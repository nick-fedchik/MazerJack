--[[
    Тип: LocalScript
    Назва: StationScreenClient
    Версія: 1.2.0
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

local log = Logger.new("StationScreenClient", "1.2.0")

----------------------------------------------------------------
-- Player / GUI resolution
----------------------------------------------------------------

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = playerGui:WaitForChild("StationGui")
local root = gui:WaitForChild("Root")

----------------------------------------------------------------
-- UI elements
----------------------------------------------------------------

local title    = root:WaitForChild("Title")
local subtitle = root:WaitForChild("Subtitle")

local actions       = root:WaitForChild("Actions")
local btnGoLocation = actions:WaitForChild("GoLocationButton")
local btnExit       = actions:WaitForChild("ExitGameButton")

----------------------------------------------------------------
-- Remote
----------------------------------------------------------------

local stationRemote = ReplicatedStorage.Remotes.StationEvent

----------------------------------------------------------------
-- Initial UI state
----------------------------------------------------------------

gui.Enabled = false

title.Text    = "STATION"
subtitle.Text = "Safe Zone"

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

btnGoLocation.MouseButton1Click:Connect(onGoLocationClicked)

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

btnExit.MouseButton1Click:Connect(onExitGameClicked)

----------------------------------------------------------------
-- End of script: StationScreenClient v1.2.0
----------------------------------------------------------------
