--[[
    Тип: Script
    Назва: StationEventHandler
    Версія: 1.2.0
    Розміщення: ServerScriptService/Handlers/StationEventHandler

    Призначення:
      Серверний обробник подій інтерфейсу космічної станції (StationGui).

    Загальна логіка:
      - Приймає дії клієнта зі StationScreenClient
      - НЕ змінює GameState напряму
      - Делегує обробку дій АКТИВНОМУ StateStation
      - Не використовує жодних хардкоджених назв станів

    Контракти / правила:
      - Заборонено викликати GameStateMachine:SetState напряму
      - Заборонено виконувати spawn
      - Дозволена тільки делегація через методи активного state
      - Перевірка валідності відбувається через наявність методів, а не Name

    Події:
      Client → Server (RemoteEvent: StationEvent)
        - "GoLocation"
        - "ExitGame"
--]]

----------------------------------------------------------------
-- Services
----------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------
-- Dependencies
----------------------------------------------------------------

local Logger = require(ReplicatedStorage.Shared.Logger)

----------------------------------------------------------------
-- Module setup
----------------------------------------------------------------

local log = Logger.new("StationEventHandler", "1.2.0")

local remote = ReplicatedStorage.Remotes.StationEvent

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

--[[
    Функція: getMachine
    Призначення:
      Безпечно отримує singleton GameStateMachine з глобального контексту.
    Вхід:
      none
    Вихід:
      GameStateMachine | nil
--]]
local function getMachine()
	return rawget(_G, "GameStateMachine")
end

----------------------------------------------------------------
-- Event handling
----------------------------------------------------------------

--[[
    Подія: StationEvent.OnServerEvent
    Призначення:
      Обробляє дії гравця зі StationGui.
    Вхідні параметри:
      player : Player
      action : string
      payload : table | nil
    Вихід / ефект:
      Делегує дію активному state, якщо він підтримує відповідний метод
--]]
remote.OnServerEvent:Connect(function(player, action, payload)
	local fn = "OnServerEvent"

	----------------------------------------------------------------
	-- Resolve GameStateMachine
	----------------------------------------------------------------
	local machine = getMachine()
	if not machine then
		log:Error(fn, "GameStateMachine missing userId=%d", player.UserId)
		return
	end

	----------------------------------------------------------------
	-- Resolve active state
	----------------------------------------------------------------
	local activeState = machine:GetActiveState(player)
	if not activeState then
		log:Warn(fn, "No active state userId=%d", player.UserId)
		return
	end

	----------------------------------------------------------------
	-- GoLocation (Sprint 2 / hardcoded stub)
	----------------------------------------------------------------
	if action == "GoLocation" then
		log:Info(fn, "GoLocation requested userId=%d", player.UserId)

		if type(activeState.GoLocation) ~= "function" then
			log:Warn(
				fn,
				"GoLocation ignored userId=%d state=%s",
				player.UserId,
				tostring(activeState.Name)
			)
			return
		end

		activeState:GoLocation(player, payload)
		return
	end

	----------------------------------------------------------------
	-- Exit Game (Sprint 1 – safe exit)
	----------------------------------------------------------------
	if action == "ExitGame" then
		log:Info(fn, "ExitGame requested userId=%d", player.UserId)
		log:Info(fn, "Active state=%s has RequestExitGame=%s", tostring(activeState.Name), tostring(type(activeState.RequestExitGame) == "function"))

		if type(activeState.RequestExitGame) ~= "function" then
			log:Warn(
				fn,
				"ExitGame ignored userId=%d state=%s",
				player.UserId,
				tostring(activeState.Name)
			)
			return
		end

		log:Info(fn, "Calling RequestExitGame on active state")
		activeState:RequestExitGame(player)
		log:Info(fn, "RequestExitGame completed")
		return
	end

	----------------------------------------------------------------
	-- Unknown action
	----------------------------------------------------------------
	log:Warn(
		fn,
		"Unknown Station action=%s userId=%d",
		tostring(action),
		player.UserId
	)
end)

----------------------------------------------------------------
-- Init
----------------------------------------------------------------

log:Info("Init", "StationEventHandler ready")

----------------------------------------------------------------
-- End of script: StationEventHandler v1.2.0
----------------------------------------------------------------
