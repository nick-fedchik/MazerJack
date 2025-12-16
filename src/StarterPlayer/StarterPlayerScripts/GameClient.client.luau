--[[
    Тип скрипта: LocalScript
    Назва: GameClient
    Версія: 2.0.0
    Розміщення: StarterPlayerScripts/GameClient

    Призначення:
      ЄДИНА точка входу клієнтської логіки гри MazerJack.
      Керує видимістю GUI та реагує на зміни стану гравця.

    Загальна логіка:
      1. Очікує готовності Events
      2. Слухає зміни атрибута CurrentMode
      3. Показує/ховає GUI відповідно до режиму
      4. Обробляє кліки на кнопках GUI

    Контракти:
      - Клієнт НЕ змінює CurrentMode напряму
      - Клієнт ТІЛЬКИ надсилає RemoteEvents на сервер
      - GUI видимість визначається ТІЛЬКИ значенням CurrentMode
--]]

----------------------------------------------------------------
-- Services
----------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------
-- Dependencies
----------------------------------------------------------------

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logger = require(Shared.Logger)
local Constants = require(Shared.Constants)
local Events = require(Shared.Events)

local log = Logger.new("GameClient", "2.0.0")

----------------------------------------------------------------
-- Player reference
----------------------------------------------------------------

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

----------------------------------------------------------------
-- Constants shortcuts
----------------------------------------------------------------

local GameMode = Constants.GameMode
local Attribute = Constants.Attribute
local RemoteEvent = Constants.RemoteEvent

----------------------------------------------------------------
-- GUI References (will be resolved after GUI loads)
----------------------------------------------------------------

local joinGameGui: ScreenGui? = nil
local stationGui: ScreenGui? = nil

----------------------------------------------------------------
-- Helper Functions
----------------------------------------------------------------

--[[
    findButton(gui, buttonName)
    Призначення:
      Шукає кнопку в GUI за назвою (рекурсивно).

    Вхідні параметри:
      gui (Instance) — GUI де шукати
      buttonName (string) — назва кнопки

    Вихід:
      TextButton | nil
--]]
local function findButton(gui: Instance, buttonName: string): TextButton?
	return gui:FindFirstChild(buttonName, true) :: TextButton?
end

--[[
    setGuiEnabled(gui, enabled)
    Призначення:
      Безпечно встановлює видимість GUI.

    Вхідні параметри:
      gui (ScreenGui?) — GUI
      enabled (boolean) — чи показувати
--]]
local function setGuiEnabled(gui: ScreenGui?, enabled: boolean)
	if gui then
		gui.Enabled = enabled
	end
end

--[[
    getCurrentMode()
    Призначення:
      Отримує поточний режим гравця.

    Вихід:
      string | nil
--]]
local function getCurrentMode(): string?
	return player:GetAttribute(Attribute.CurrentMode)
end

----------------------------------------------------------------
-- GUI State Management
----------------------------------------------------------------

--[[
    updateGuiVisibility()
    Призначення:
      Оновлює видимість GUI на основі CurrentMode.
      Єдина функція, що керує видимістю GUI.
--]]
local function updateGuiVisibility()
	local mode = getCurrentMode()
	
	log:Info("updateGuiVisibility", "Mode changed to: %s", tostring(mode))
	
	-- Join GUI: видимий тільки в режимі Join
	setGuiEnabled(joinGameGui, mode == GameMode.Join)
	
	-- Station GUI: видимий тільки в режимі Station
	setGuiEnabled(stationGui, mode == GameMode.Station)
	
	-- Location GUI: TODO (поки немає)
end

----------------------------------------------------------------
-- Button Handlers
----------------------------------------------------------------

--[[
    onJoinButtonClick()
    Призначення:
      Обробляє клік на кнопку "Join Game".
--]]
local function onJoinButtonClick()
	log:Info("onJoinButtonClick", "Join button clicked")
	
	local joinEvent = Events.Get(RemoteEvent.JoinGame)
	if joinEvent then
		joinEvent:FireServer()
	else
		log:Error("onJoinButtonClick", "JoinGame event not found")
	end
end

--[[
    onGoLocationButtonClick()
    Призначення:
      Обробляє клік на кнопку "Go to Location".
--]]
local function onGoLocationButtonClick()
	log:Info("onGoLocationButtonClick", "Go Location button clicked")
	
	local goEvent = Events.Get(RemoteEvent.GoToLocation)
	if goEvent then
		goEvent:FireServer()
	else
		log:Error("onGoLocationButtonClick", "GoToLocation event not found")
	end
end

--[[
    onExitButtonClick()
    Призначення:
      Обробляє клік на кнопку "Exit Game".
--]]
local function onExitButtonClick()
	log:Info("onExitButtonClick", "Exit button clicked")
	
	local exitEvent = Events.Get(RemoteEvent.ExitGame)
	if exitEvent then
		exitEvent:FireServer()
	else
		log:Error("onExitButtonClick", "ExitGame event not found")
	end
end

----------------------------------------------------------------
-- GUI Setup
----------------------------------------------------------------

--[[
    setupJoinGui()
    Призначення:
      Налаштовує JoinGameGui та підключає обробники кнопок.
--]]
local function setupJoinGui()
	joinGameGui = playerGui:WaitForChild("JoinGameGui", 10) :: ScreenGui?
	
	if not joinGameGui then
		log:Warn("setupJoinGui", "JoinGameGui not found")
		return
	end
	
	log:Info("setupJoinGui", "JoinGameGui found")
	
	-- Шукаємо кнопку Join (може мати різні назви)
	local joinButton = findButton(joinGameGui, "JoinButton") 
		or findButton(joinGameGui, "JoinGameButton")
		or findButton(joinGameGui, "PlayButton")
	
	if joinButton then
		joinButton.Activated:Connect(onJoinButtonClick)
		log:Info("setupJoinGui", "Join button connected: %s", joinButton.Name)
	else
		log:Warn("setupJoinGui", "Join button not found in JoinGameGui")
	end
	
	-- Початково ховаємо (updateGuiVisibility покаже якщо потрібно)
	joinGameGui.Enabled = false
end

--[[
    setupStationGui()
    Призначення:
      Налаштовує StationGui та підключає обробники кнопок.
--]]
local function setupStationGui()
	stationGui = playerGui:WaitForChild("StationGui", 10) :: ScreenGui?
	
	if not stationGui then
		log:Warn("setupStationGui", "StationGui not found")
		return
	end
	
	log:Info("setupStationGui", "StationGui found")
	
	-- Кнопка Go to Location
	local goLocationButton = findButton(stationGui, "GoLocationButton")
		or findButton(stationGui, "GoToLocationButton")
	
	if goLocationButton then
		goLocationButton.Activated:Connect(onGoLocationButtonClick)
		log:Info("setupStationGui", "GoLocation button connected: %s", goLocationButton.Name)
	end
	
	-- Кнопка Exit
	local exitButton = findButton(stationGui, "ExitButton")
		or findButton(stationGui, "ExitGameButton")
	
	if exitButton then
		exitButton.Activated:Connect(onExitButtonClick)
		log:Info("setupStationGui", "Exit button connected: %s", exitButton.Name)
	end
	
	-- Початково ховаємо
	stationGui.Enabled = false
end

----------------------------------------------------------------
-- Mode Change Listener
----------------------------------------------------------------

--[[
    setupModeListener()
    Призначення:
      Підключає слухача змін атрибута CurrentMode.
--]]
local function setupModeListener()
	player:GetAttributeChangedSignal(Attribute.CurrentMode):Connect(function()
		updateGuiVisibility()
	end)
	
	log:Info("setupModeListener", "Mode change listener connected")
end

----------------------------------------------------------------
-- Initialization
----------------------------------------------------------------

local function init()
	log:Info("init", "=== GameClient Starting ===")
	
	-- Чекаємо готовності Events
	if not Events.WaitForReady(10) then
		log:Error("init", "Events folder not found - server may not be running")
		return
	end
	log:Info("init", "Events ready")
	
	-- Налаштовуємо GUI
	setupJoinGui()
	setupStationGui()
	
	-- Підключаємо слухача змін режиму
	setupModeListener()
	
	-- Оновлюємо видимість на основі поточного стану
	-- (на випадок якщо атрибут вже встановлений)
	updateGuiVisibility()
	
	log:Info("init", "=== GameClient Ready ===")
end

-- Start
init()

----------------------------------------------------------------
-- End of script: GameClient v2.0.0
----------------------------------------------------------------
