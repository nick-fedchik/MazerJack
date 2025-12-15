--[[
    Тип: Script
    Назва: MainServer
  Версія: 1.2.1
    Розміщення: ServerScriptService/MainServer

    Призначення:
      Центральна точка ініціалізації серверної частини гри MazerJack.

    Загальна логіка:
      - Створює та реєструє сервіси
      - Реєструє всі Game States у GameStateMachine
      - Забезпечує єдиний FSM singleton (_G.GameStateMachine)
      - Ініціалізує гравця при вході
      - Гарантує коректний Boot у Join state

    КЛЮЧОВЕ ПРАВИЛО (виправлено в цьому патчі):
      - GameStateMachine працює з ЛОГІЧНИМИ іменами станів:
          "Join", "Station", "Location"
      - Назви файлів (StateJoin.lua тощо) НІКОЛИ
        не використовуються як stateName

    Взаємодія / контракти:
      - Використовує Enums.GameState як єдине джерело імен станів
      - Передає services та remotes у FSM
      - FSM доступний через _G.GameStateMachine
--]]

----------------------------------------------------------------
-- Services
----------------------------------------------------------------

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------
-- Dependencies
----------------------------------------------------------------

local Logger = require(ReplicatedStorage.Shared.Logger)
local Enums  = require(ReplicatedStorage.Shared.Enums)
local GameEvents = require(ReplicatedStorage.Shared.GameEvents)

----------------------------------------------------------------
-- Logger
----------------------------------------------------------------

local log = Logger.new("MainServer", "1.2.1")

----------------------------------------------------------------
-- Services construction
----------------------------------------------------------------

local Services = {}

Services.PersistenceService =
	require(ServerScriptService.Services.PersistenceService).new()

Services.PlayerSpawnService =
	require(ServerScriptService.Services.PlayerSpawnService).new()

Services.PlayerService =
	require(ServerScriptService.Services.PlayerService).new(
		Services.PersistenceService,
		Services.PlayerSpawnService
	)

Services.DoorService =
	require(ServerScriptService.Services.DoorService).new()

----------------------------------------------------------------
-- State modules registration
-- ВАЖЛИВО:
--   КЛЮЧІ = Enums.GameState.*
--   НЕ назви файлів
----------------------------------------------------------------

local StateModules = {
	[Enums.GameState.Join] =
		require(ServerScriptService.StateMachine.StateJoin),

	[Enums.GameState.Station] =
		require(ServerScriptService.StateMachine.StateStation),

	[Enums.GameState.Location] =
		require(ServerScriptService.StateMachine.StateLocation),
}

----------------------------------------------------------------
-- GameStateMachine (singleton)
----------------------------------------------------------------

local GameStateMachine =
	require(ServerScriptService.StateMachine.GameStateMachine)

local gameEventRemote = GameEvents.GetGameRemote()

local machine = GameStateMachine.new(
	StateModules,
	Services,
	gameEventRemote
)

-- Canonical global exposure
_G.GameStateMachine = machine
_G.MazerJackServices = Services

log:Info("Boot", "GameStateMachine initialized")

----------------------------------------------------------------
-- Player lifecycle
----------------------------------------------------------------

--[[
    Подія: Players.PlayerAdded
    Призначення:
      Повна серверна ініціалізація гравця.
    Послідовність:
      1) InitPlayer (persistence + spawn guard)
      2) Boot FSM у Join state
--]]
Players.PlayerAdded:Connect(function(player)
	local fn = "PlayerAdded"

	-- 1. Ініціалізація гравця (обовʼязково до FSM)
	Services.PlayerService:InitPlayer(player)

	-- 2. Старт FSM у Join
	machine:SetState(player, Enums.GameState.Join)

	log:Info(fn, "Player initialized userId=%d", player.UserId)
end)

--[[
    Подія: Players.PlayerRemoving
    Призначення:
      Коректне завершення сесії гравця.
--]]
Players.PlayerRemoving:Connect(function(player)
	Services.PlayerService:OnPlayerRemoving(player)
end)

----------------------------------------------------------------
-- Init complete
----------------------------------------------------------------

log:Info("Boot", "MainServer ready")

----------------------------------------------------------------
-- End of script: MainServer v1.2.1
----------------------------------------------------------------
