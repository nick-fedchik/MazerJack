--[[
    Тип: ModuleScript
    Назва: PlayerSpawnService
    Версія: 1.2.1
    Розміщення: ServerScriptService/Services/PlayerSpawnService

    Призначення:
      ЄДИНИЙ сервіс відповідальний за spawn гравця.

    Загальна логіка (Sprint 1):
      - Spawn дозволяється ТІЛЬКИ після JoinGame
      - Використовується ЛИШЕ StellarStation.SpawnLocation
      - Рівно один LoadCharacter() на сесію входу

    Контракти / правила:
      - НЕ втручається в CharacterAdded
      - НЕ використовує anchor / void
      - НЕ виконує spawn без дозволу
--]]

----------------------------------------------------------------
-- Services
----------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------
-- Dependencies
----------------------------------------------------------------

local Logger = require(ReplicatedStorage.Shared.Logger)
local Enums = require(ReplicatedStorage.Shared.Enums)

----------------------------------------------------------------
-- Module setup
----------------------------------------------------------------

local PlayerSpawnService = {}
PlayerSpawnService.__index = PlayerSpawnService

local log = Logger.new("PlayerSpawnService", "1.2.1")

local ATTR_SPAWN_ENABLED = "MJ_SpawnEnabled"

----------------------------------------------------------------
-- Construction
----------------------------------------------------------------

--[[
    Функція: new
    Призначення:
      Створює новий екземпляр PlayerSpawnService.
--]]
function PlayerSpawnService.new()
	return setmetatable({}, PlayerSpawnService)
end

----------------------------------------------------------------
-- Spawn gate
----------------------------------------------------------------

--[[
    Функція: SetSpawnEnabled
    Призначення:
      Вмикає або вимикає можливість spawn для гравця.
    Вхід:
      player: Player
      enabled: boolean
--]]
function PlayerSpawnService:SetSpawnEnabled(player, enabled)
	player:SetAttribute(ATTR_SPAWN_ENABLED, enabled == true)
	log:Info("SetSpawnEnabled", "userId=%d enabled=%s", player.UserId, tostring(enabled))
end

--[[
    Функція: IsSpawnEnabled
    Призначення:
      Перевіряє, чи дозволений spawn для гравця.
    Вхід:
      player: Player
    Вихід:
      boolean
--]]
function PlayerSpawnService:IsSpawnEnabled(player)
	return player:GetAttribute(ATTR_SPAWN_ENABLED) == true
end

----------------------------------------------------------------
-- Spawning
----------------------------------------------------------------

--[[
    Функція: ApplySpawnForStation
    Призначення:
      Виконує spawn гравця на Космічній Станції.
    Вхід:
      player: Player
--]]
function PlayerSpawnService:ApplySpawnForStation(player)
	local fn = "ApplySpawnForStation"

	if not self:IsSpawnEnabled(player) then
		log:Warn(fn, "Spawn blocked userId=%d", player.UserId)
		return
	end

	local station = workspace:FindFirstChild("StellarStation")
	if not station then
		log:Error(fn, "StellarStation missing")
		return
	end

	local passengerRoom = station:FindFirstChild("PassengerRoom")
	if not passengerRoom then
		log:Error(fn, "PassengerRoom missing in StellarStation")
		return
	end

	local spawnLocation = passengerRoom:FindFirstChild("SpawnLocation")
	if not spawnLocation then
		log:Error(fn, "SpawnLocation missing in PassengerRoom")
		return
	end

  -- Studio/Rojo safety: ensure the spawn part is stable.
  if spawnLocation:IsA("BasePart") then
    spawnLocation.Anchored = true
    spawnLocation.CanCollide = true
  end

	player.RespawnLocation = spawnLocation
	player:LoadCharacter()

	log:Info(fn, "Spawned userId=%d at Station", player.UserId)
end

return PlayerSpawnService
----------------------------------------------------------------
-- End of script: PlayerSpawnService v1.2.1
----------------------------------------------------------------
