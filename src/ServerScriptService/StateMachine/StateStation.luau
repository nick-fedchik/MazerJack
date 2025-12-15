--[[
    Тип: ModuleScript
    Назва: StateStation
	Версія: 1.2.0
    Розміщення: ServerScriptService/StateMachine/StateStation

    Призначення:
      Серверний стан "Station" (Sprint 1 baseline + безпечний Exit Game).

    Загальна логіка:
      - OnEnter: вмикає spawn для гравця та спавнить у StellarStation/SpawnLocation.
      - GoLocation: stub (для Sprint 2).
      - RequestExitGame: контрольований вихід:
          1) збереження прогресу (PersistenceService:Save)
          2) У Studio: повернення в Join (FSM:SetState(player,"Join"))
          3) У Live: TeleportService:Teleport до поточного PlaceId
             (fallback: Kick)

    Взаємодія / контракти:
      - Викликається ТІЛЬКИ через GameStateMachine (SetState).
      - StationEventHandler може викликати:
          activeState:GoLocation(...)
          activeState:RequestExitGame(player)

    Архітектурні правила:
      - State відповідає за свою бізнес-логіку.
      - Spawn робиться через PlayerSpawnService.
      - Не робити "пошук спавнів" по Workspace — тільки канонічний сервіс.

--]]

----------------------------------------------------------------
-- Services
----------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

----------------------------------------------------------------
-- Dependencies
----------------------------------------------------------------

local Logger = require(ReplicatedStorage.Shared.Logger)
local Enums = require(ReplicatedStorage.Shared.Enums)
local GameEvents = require(ReplicatedStorage.Shared.GameEvents)

----------------------------------------------------------------
-- Module setup
----------------------------------------------------------------

local StateStation = {}
StateStation.__index = StateStation

local log = Logger.new("StateStation", "1.2.0")

----------------------------------------------------------------
-- Constructor: new
-- Призначення:
--   Створює інстанс стану Station для конкретного GameStateMachine.
-- Вхідні параметри:
--   machine: GameStateMachine (singleton)
--   services: table (PersistenceService, PlayerSpawnService, PlayerService, ...)
--   remote: RemoteEvent (ReplicatedStorage/Remotes/GameEvent)
-- Вихід:
--   instance: StateStation
-- Хто використовує:
--   GameStateMachine під час переходу в стан Station
----------------------------------------------------------------
function StateStation.new(machine, services, remote)
	local self = setmetatable({}, StateStation)

	self.Name = Enums.GameState.Station -- очікується рядок "Station"
	self._machine = machine
	self._services = services
	self._remote = remote

	log:Info("Constructor", "StateStation created")

	return self
end

----------------------------------------------------------------
-- Function: OnEnter
-- Призначення:
--   Вхід у стан Station: вмикає spawn та спавнить гравця на станції.
-- Вхідні параметри:
--   player: Player
--   context: table|nil (може містити PersistentState)
-- Вихід / ефект:
--   Спавн гравця у StellarStation/SpawnLocation, оновлення атрибутів/пам'яті
-- Хто використовує:
--   GameStateMachine при переході Join -> Station
----------------------------------------------------------------
function StateStation:OnEnter(player, context)
	local fn = "OnEnter"

	log:Info(fn, "Station entered userId=%d", player.UserId)

	-- Runtime attributes
	player:SetAttribute("IsInStation", true)
	player:SetAttribute("IsInLocation", false)

	-- Enable spawn and spawn at station
	self._services.PlayerSpawnService:SetSpawnEnabled(player, true)
	self._services.PlayerSpawnService:ApplySpawnForStation(player)

	-- Persistence (DATA ONLY)
	local ps =
		(context and context.PersistentState)
		or self._services.PersistenceService:GetCached(player)

	ps.lastMode = "Station"
	ps.lastSpawnZone = "Station"
	ps.updatedAtUnix = os.time()

	self._services.PersistenceService:Save(player, ps)

	-- Notify client (optional; не критично для Sprint 1)
	if self._remote and self._remote.FireClient then
		self._remote:FireClient(player, GameEvents.Event.EnteredMode, {
			mode = Enums.GameState.Station,
		})
	end
end

----------------------------------------------------------------
-- Function: OnExit
-- Призначення:
--   Вихід зі стану Station (зачистка runtime-прапорців).
-- Вхідні параметри:
--   player: Player
--   context: table|nil
-- Вихід / ефект:
--   Оновлює атрибути гравця
-- Хто використовує:
--   GameStateMachine при переході Station -> інший стан
----------------------------------------------------------------
function StateStation:OnExit(player, _context)
	local fn = "OnExit"
	player:SetAttribute("IsInStation", false)
	log:Info(fn, "Station exit userId=%d", player.UserId)
end

----------------------------------------------------------------
-- Function: GoLocation (stub)
-- Призначення:
--   Заглушка для Sprint 2: перехід у локацію.
-- Вхідні параметри:
--   player: Player
--   payload: table|nil (наприклад {LocationId="Location_001"})
-- Вихід / ефект:
--   Поки що лише логування / майбутня інтеграція зі StateLocation
-- Хто використовує:
--   StationEventHandler по кнопці GoLocation
----------------------------------------------------------------
function StateStation:GoLocation(player, payload)
	local fn = "GoLocation"
	log:Warn(fn, "Not implemented yet userId=%d payload=%s", player.UserId, tostring(payload))
end

----------------------------------------------------------------
-- Function: RequestExitGame
-- Призначення:
--   Контрольований вихід з гри по кнопці Exit Game:
--     1) Save прогресу
--     2) Studio: повернення у Join (без teleport)
--     3) Live: Teleport у цей же PlaceId
-- Вхідні параметри:
--   player: Player
-- Вихід / ефект:
--   Виконує Save; далі змінює стан або teleports / kick
-- Хто використовує:
--   StationEventHandler по action="ExitGame"
----------------------------------------------------------------
function StateStation:RequestExitGame(player)
	local fn = "RequestExitGame"

	-- 1) Save progress
	local ps = self._services.PersistenceService:GetCached(player)
	ps.updatedAtUnix = os.time()

	local okSave = self._services.PersistenceService:Save(player, ps)
	if not okSave then
		log:Warn(fn, "Save returned false userId=%d (continuing exit flow)", player.UserId)
	else
		log:Info(fn, "Progress saved userId=%d", player.UserId)
	end

	-- 2) Exit behavior differs by environment
	if RunService:IsStudio() then
		log:Info(fn, "Studio detected -> returning to Join userId=%d", player.UserId)

		-- IMPORTANT: Use FSM to go back to Join so UI reacts via CurrentMode
		if self._machine and self._machine.SetState then
			self._machine:SetState(player, Enums.GameState.Join)
		else
			log:Error(fn, "GameStateMachine missing in state instance userId=%d", player.UserId)
		end
		return
	end

	-- 3) Live: teleport to same place (rejoin effect)
	local placeId = game.PlaceId

	local okTp, errTp = pcall(function()
		TeleportService:Teleport(placeId, player)
	end)

	if okTp then
		log:Info(fn, "Teleport issued userId=%d placeId=%d", player.UserId, placeId)
		return
	end

	log:Error(fn, "Teleport failed userId=%d err=%s; kicking", player.UserId, tostring(errTp))
	pcall(function()
		player:Kick("Progress saved. Please rejoin the game.")
	end)
end

return StateStation

----------------------------------------------------------------
-- End of script: StateStation v1.1.3
----------------------------------------------------------------
