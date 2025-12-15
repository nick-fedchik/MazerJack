--[[
    Тип: ModuleScript
    Назва: GameStateMachine
    Версія: 1.2.0
    Розміщення: ServerScriptService/StateMachine/GameStateMachine

    Призначення:
      Центральна детермінована машина станів гри.
      Керує переходами між станами для кожного гравця окремо.

    Загальна логіка:
      - Для кожного гравця існує рівно ОДИН активний стан
      - Перехід між станами відбувається тільки через SetState
      - Підтримується блокування переходів (anti-race)

    Контракти / правила:
      - GameStateMachine є singleton (створюється в MainServer)
      - Зберігається в _G.GameStateMachine
      - Handlers НЕ МОЖУТЬ викликати SetState напряму (окрім JoinEventHandler)
      - Стан зобовʼязаний мати поле Name
--]]

----------------------------------------------------------------
-- Services
----------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------
-- Dependencies
----------------------------------------------------------------

local Logger = require(ReplicatedStorage.Shared.Logger)
local Enums  = require(ReplicatedStorage.Shared.Enums)

----------------------------------------------------------------
-- Module setup
----------------------------------------------------------------

local GameStateMachine = {}
GameStateMachine.__index = GameStateMachine

local log = Logger.new("GameStateMachine", "1.2.0")

----------------------------------------------------------------
-- Construction
----------------------------------------------------------------

--[[
    Функція: new
    Призначення:
      Створює новий екземпляр GameStateMachine.
    Вхід:
      stateConstructors: table<string, module>
      services: table — сервіси гри
      remote: RemoteEvent — GameEvent
    Вихід:
      GameStateMachine
--]]
function GameStateMachine.new(stateConstructors, services, remote)
	local self = setmetatable({}, GameStateMachine)

	self._states = stateConstructors
	self._services = services
	self._remote = remote

	self._activeState = {}    -- [userId] = stateInstance
	self._transitionLock = {} -- [userId] = boolean

	return self
end

----------------------------------------------------------------
-- Lock helpers
----------------------------------------------------------------

--[[
    Функція: _lock
    Призначення:
      Блокує перехід стану для гравця.
    Вхід:
      userId: number
    Вихід:
      boolean — чи вдалося отримати lock
--]]
function GameStateMachine:_lock(userId)
	if self._transitionLock[userId] then
		return false
	end
	self._transitionLock[userId] = true
	return true
end

--[[
    Функція: _unlock
    Призначення:
      Знімає блокування переходу стану.
    Вхід:
      userId: number
--]]
function GameStateMachine:_unlock(userId)
	self._transitionLock[userId] = false
end

----------------------------------------------------------------
-- Introspection API (для Handlers)
----------------------------------------------------------------

--[[
    Функція: GetActiveState
    Призначення:
      Повертає активний state-обʼєкт гравця.
    Вхід:
      player: Player
    Вихід:
      table | nil
--]]
function GameStateMachine:GetActiveState(player)
	return self._activeState[player.UserId]
end

--[[
    Функція: GetActiveStateName
    Призначення:
      Повертає імʼя активного стану гравця.
    Вхід:
      player: Player
    Вихід:
      string | nil
--]]
function GameStateMachine:GetActiveStateName(player)
	local state = self._activeState[player.UserId]
	return state and state.Name or nil
end

----------------------------------------------------------------
-- State transitions
----------------------------------------------------------------

--[[
    Функція: SetState
    Призначення:
      ЄДИНИЙ дозволений спосіб змінити стан гравця.
    Вхід:
      player: Player
      stateName: string
      context: table | nil
    Вихід:
      boolean — успішність переходу
--]]
function GameStateMachine:SetState(player, stateName, context)
	local fn = "SetState"
	local userId = player.UserId

	if not self:_lock(userId) then
		log:Warn(fn, "Transition locked userId=%d target=%s", userId, tostring(stateName))
		return false
	end

	local ok, err = pcall(function()
		local prevState = self._activeState[userId]

		-- OnExit попереднього стану
		if prevState and prevState.OnExit then
			prevState:OnExit(player, context)
		end

		local ctor = self._states[stateName]
		if not ctor then
			error("Unknown state: " .. tostring(stateName))
		end

		local nextState = ctor.new(self, self._services, self._remote)
		self._activeState[userId] = nextState

		-- Авторитетний runtime-атрибут
		player:SetAttribute("CurrentMode", stateName)

		log:Info(
			fn,
			"Transition userId=%d %s -> %s",
			userId,
			prevState and tostring(prevState.Name) or "nil",
			tostring(stateName)
		)

		-- OnEnter нового стану
		if nextState.OnEnter then
			nextState:OnEnter(player, context)
		end
	end)

	self:_unlock(userId)

	if not ok then
		log:Error(fn, "Transition failed userId=%d err=%s", userId, tostring(err))
		return false
	end

	return true
end

--[[
    Функція: BootToJoin
    Призначення:
      Початковий boot FSM у Join-стан.
    Вхід:
      player: Player
      context: table | nil
--]]
function GameStateMachine:BootToJoin(player, context)
	return self:SetState(player, Enums.GameState.Join, context)
end

return GameStateMachine
----------------------------------------------------------------
-- End of script: GameStateMachine v1.1.0
----------------------------------------------------------------
