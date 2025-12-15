--[[
    Тип: Script
    Назва: JoinEventHandler
    Версія: 1.2.0
    Розміщення: ServerScriptService/Handlers/JoinEventHandler

    Призначення:
      Обробляє єдину дію приєднання гравця до гри (Join Game).

    Загальна логіка:
      - Приймає запит JoinGame від клієнта
      - НЕ аналізує стан гри
      - НЕ виконує spawn напряму
      - Делегує перехід GameStateMachine

    Контракти / правила:
      - Працює тільки з GameEvents.Event.JoinGame
      - ЄДИНИЙ handler, який має право викликати SetState
      - Переходить гравця зі стану Join → Station
--]]

----------------------------------------------------------------
-- Services
----------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------
-- Dependencies
----------------------------------------------------------------

local Logger     = require(ReplicatedStorage.Shared.Logger)
local GameEvents = require(ReplicatedStorage.Shared.GameEvents)
local Enums      = require(ReplicatedStorage.Shared.Enums)

----------------------------------------------------------------
-- Module setup
----------------------------------------------------------------

local log = Logger.new("JoinEventHandler", "1.2.0")

local remote = GameEvents.GetGameRemote()

----------------------------------------------------------------
-- Event handling
----------------------------------------------------------------

--[[
    Подія: GameEvent.OnServerEvent
    Призначення:
      Приймає клієнтські події JoinGame.
    Вхід:
      player: Player
      eventName: string
--]]
remote.OnServerEvent:Connect(function(player, eventName)
	local fn = "OnServerEvent"

	log:Info(fn, "Recv event=%s userId=%d", tostring(eventName), player.UserId)

	if eventName ~= GameEvents.Event.JoinGame then
		return
	end

	local machine = rawget(_G, "GameStateMachine")
	if not machine then
		log:Error(fn, "GameStateMachine missing userId=%d", player.UserId)
		return
	end

	log:Info(fn, "JoinGame accepted userId=%d -> Station", player.UserId)

  machine:SetState(player, Enums.GameState.Station)
end)

----------------------------------------------------------------
-- Init
----------------------------------------------------------------

log:Info("Init", "JoinEventHandler ready")

----------------------------------------------------------------
-- End of script: JoinEventHandler v1.2.0
----------------------------------------------------------------
