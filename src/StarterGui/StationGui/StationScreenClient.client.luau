--[[
    Тип: LocalScript
    Назва: StationScreenClient
	Версія: 1.2.4
    Розміщення: StarterGui/StationGui/StationScreenClient

    Призначення:
      Клієнтський UI космічної станції (Sprint 1).

    Загальна логіка:
      - GUI стартує з Enabled = false
      - Стає видимим ТІЛЬКИ коли CurrentMode == StationMode
      - Передає дії користувача на сервер

    Взаємодія / контракти:
      - Client → Server:
          StationEvent RemoteEvent
      - Client ← Server:
          Player Attribute "CurrentMode"

    Архітектурні правила:
      - НЕ змінює GameState
      - НЕ керує Spawn
--]]

----------------------------------------------------------------
-- Services
----------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------
-- Dependencies
----------------------------------------------------------------

local Logger = require(ReplicatedStorage.Shared.Logger)
local GameEvents = require(ReplicatedStorage.Shared.GameEvents)

local log = Logger.new("StationScreenClient", "1.2.4")

----------------------------------------------------------------
-- Player / GUI resolution
----------------------------------------------------------------

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = playerGui:WaitForChild("StationGui")

----------------------------------------------------------------
-- Function: waitForDescendant
-- Призначення:
--   Безпечно очікує на нащадка з певною назвою в ієрархії GUI.
-- Вхідні параметри:
--   parent: Instance
--   name: string
--   timeoutSeconds: number? (default 10)
-- Вихід:
--   Instance | nil
-- Хто використовує:
--   StationScreenClient (resolution без жорсткої залежності від Root)
----------------------------------------------------------------
local function waitForDescendant(parent: Instance, name: string, timeoutSeconds: number?): Instance?
	local timeout = timeoutSeconds or 10
	local started = os.clock()
	local found = parent:FindFirstChild(name, true)
	while not found and (os.clock() - started) < timeout do
		task.wait(0.1)
		found = parent:FindFirstChild(name, true)
	end
	return found
end

----------------------------------------------------------------
-- UI elements
----------------------------------------------------------------

local title = waitForDescendant(gui, "Title", 10)
local subtitle = waitForDescendant(gui, "Subtitle", 10)
local btnGoLocation = waitForDescendant(gui, "GoLocationButton", 10)
local btnExit = waitForDescendant(gui, "ExitGameButton", 10)

if not (title and subtitle and btnGoLocation and btnExit) then
	log:Error(
		"Init",
		"Station UI elements missing (check names: Title/Subtitle/GoLocationButton/ExitGameButton)"
	)
	return
end

local titleLabel = title :: any
local subtitleLabel = subtitle :: any
local btnGoLocationButton = btnGoLocation :: any
local btnExitButton = btnExit :: any

----------------------------------------------------------------
-- Remote
----------------------------------------------------------------

local stationRemote = GameEvents.GetStationRemote()

----------------------------------------------------------------
-- Initial UI state
----------------------------------------------------------------

gui.Enabled = false

titleLabel.Text = "STATION"
subtitleLabel.Text = "Safe Zone"

log:Info("Init", "StationScreen initialized and hidden")

----------------------------------------------------------------
-- Function: syncVisibility
-- Призначення:
--   Синхронізує видимість Station GUI з поточним режимом гри.
-- Вхідні параметри:
--   none
-- Вихід / ефект:
--   Вмикає / вимикає StationGui
-- Хто використовує:
--   Player Attribute "CurrentMode"
----------------------------------------------------------------
local function syncVisibility()
	local mode = player:GetAttribute("CurrentMode")
	local visible = (mode == "Station")

	gui.Enabled = visible

	log:Info(
		"syncVisibility",
		"CurrentMode=%s StationGui.Enabled=%s",
		tostring(mode),
		tostring(visible)
	)
end

player:GetAttributeChangedSignal("CurrentMode"):Connect(syncVisibility)
syncVisibility()

----------------------------------------------------------------
-- Function: onGoLocationClicked
-- Призначення:
--   Обробляє запит переходу з станції в локацію.
-- Вхідні параметри:
--   none (MouseButton1Click)
-- Вихід / ефект:
--   Надсилає GoLocation на сервер
-- Хто використовує:
--   Кнопка GoLocationButton
----------------------------------------------------------------
local function onGoLocationClicked()
	log:Info("GoLocationClick", "Requested")

	stationRemote:FireServer(
		"GoLocation",
		{ LocationId = "Location_001" }
	)
end

btnGoLocationButton.MouseButton1Click:Connect(onGoLocationClicked)

----------------------------------------------------------------
-- Function: onExitClicked
-- Призначення:
--   Обробляє запит виходу зі станції.
-- Вхідні параметри:
--   none (MouseButton1Click)
-- Вихід / ефект:
--   Надсилає Exit на сервер
-- Хто використовує:
--   Кнопка ExitButton
----------------------------------------------------------------
local function onExitGameClicked()
	log:Info("ExitGameClick", "Requested")
	
	-- Debug: Check if remote exists
	if not stationRemote then
		log:Error("ExitGameClick", "StationRemote is nil")
		return
	end
	
	log:Info("ExitGameClick", "Firing ExitGame event")
	stationRemote:FireServer("ExitGame")
	log:Info("ExitGameClick", "ExitGame event fired")
end

btnExitButton.MouseButton1Click:Connect(onExitGameClicked)

----------------------------------------------------------------
-- End of script: StationScreenClient v1.2.4
----------------------------------------------------------------
