--[[
    Тип скрипта: LocalScript
    Назва: GameClient
    Версія: 2.1.0
    Розміщення: StarterPlayerScripts/GameClient

    Призначення:
      ЄДИНА точка входу клієнтської логіки гри MazerJack.
      Керує видимістю GUI та реагує на зміни стану гравця.

    Загальна логіка:
      1. Очікує готовності Events
      2. Слухає зміни атрибутів CurrentMode та IsNewPlayer
      3. Заповнює профіль гравця в JoinGameGui (нікнейм, аватар, статус)
      4. Показує/ховає GUI відповідно до режиму
      5. Обробляє кліки на кнопках GUI

    Контракти:
      - Клієнт НЕ змінює CurrentMode напряму
      - Клієнт ТІЛЬКИ надсилає RemoteEvents на сервер
      - GUI видимість визначається ТІЛЬКИ значенням CurrentMode
      - Профіль (нікнейм, аватар) отримується з Roblox API
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

local log = Logger.new("GameClient", "2.1.0")

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
local locationGui: ScreenGui? = nil

----------------------------------------------------------------
-- Helper Functions: GUI Search
----------------------------------------------------------------

--[[
    findDescendant(parent, name)
    Призначення:
      Шукає нащадка в GUI за назвою (рекурсивно).

    Вхідні параметри:
      parent (Instance) — де шукати
      name (string) — назва елемента

    Вихід:
      Instance | nil
--]]
local function findDescendant(parent: Instance, name: string): Instance?
	return parent:FindFirstChild(name, true)
end

--[[
    findButton(gui, ...)
    Призначення:
      Шукає кнопку за одним із можливих імен.

    Вхідні параметри:
      gui (Instance) — GUI де шукати
      ... (string) — можливі назви кнопки

    Вихід:
      TextButton | nil
--]]
local function findButton(gui: Instance, ...: string): TextButton?
	for _, name in ipairs({...}) do
		local button = findDescendant(gui, name)
		if button and (button:IsA("TextButton") or button:IsA("ImageButton")) then
			return button :: TextButton
		end
	end
	return nil
end

--[[
    findTextLabel(gui, ...)
    Призначення:
      Шукає TextLabel за одним із можливих імен.

    Вхідні параметри:
      gui (Instance) — GUI де шукати
      ... (string) — можливі назви

    Вихід:
      TextLabel | nil
--]]
local function findTextLabel(gui: Instance, ...: string): TextLabel?
	for _, name in ipairs({...}) do
		local label = findDescendant(gui, name)
		if label and label:IsA("TextLabel") then
			return label :: TextLabel
		end
	end
	return nil
end

--[[
    findImageLabel(gui, ...)
    Призначення:
      Шукає ImageLabel за одним із можливих імен.

    Вхідні параметри:
      gui (Instance) — GUI де шукати
      ... (string) — можливі назви

    Вихід:
      ImageLabel | nil
--]]
local function findImageLabel(gui: Instance, ...: string): ImageLabel?
	for _, name in ipairs({...}) do
		local label = findDescendant(gui, name)
		if label and label:IsA("ImageLabel") then
			return label :: ImageLabel
		end
	end
	return nil
end

----------------------------------------------------------------
-- Helper Functions: GUI State
----------------------------------------------------------------

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

--[[
    getIsNewPlayer()
    Призначення:
      Отримує чи гравець новий.

    Вихід:
      boolean
--]]
local function getIsNewPlayer(): boolean
	return player:GetAttribute(Attribute.IsNewPlayer) == true
end

----------------------------------------------------------------
-- Profile Display
----------------------------------------------------------------

--[[
    getPlayerAvatarUrl(userId)
    Призначення:
      Генерує URL аватара гравця.

    Вхідні параметри:
      userId (number) — ID гравця

    Вихід:
      string — URL для ImageLabel.Image
--]]
local function getPlayerAvatarUrl(userId: number): string
	-- Використовуємо Roblox thumbnail API
	return string.format(
		"https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150&format=png",
		userId
	)
end

--[[
    updateJoinGuiProfile()
    Призначення:
      Заповнює профіль гравця в JoinGameGui.
      Встановлює нікнейм, аватар та статус (New/Experienced).
--]]
local function updateJoinGuiProfile()
	if not joinGameGui then
		return
	end
	
	-- Нікнейм
	local nameLabel = findTextLabel(joinGameGui, 
		"PlayerName", "NameLabel", "PlayerNameLabel", "NicknameLabel")
	if nameLabel then
		nameLabel.Text = player.DisplayName
		log:Info("updateJoinGuiProfile", "Set player name: %s", player.DisplayName)
	end
	
	-- Аватар
	local avatarImage = findImageLabel(joinGameGui,
		"PlayerAvatar", "AvatarImage", "AvatarLabel", "PlayerImage")
	if avatarImage then
		-- Використовуємо async thumbnail API
		local success, content = pcall(function()
			return Players:GetUserThumbnailAsync(
				player.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size150x150
			)
		end)
		
		if success and content then
			avatarImage.Image = content
			log:Info("updateJoinGuiProfile", "Set player avatar from GetUserThumbnailAsync")
		else
			-- Fallback до URL
			avatarImage.Image = getPlayerAvatarUrl(player.UserId)
			log:Info("updateJoinGuiProfile", "Set player avatar from URL fallback")
		end
	end
	
	-- Статус (New Player / Experienced)
	local statusLabel = findTextLabel(joinGameGui,
		"PlayerStatus", "StatusLabel", "PlayerStatusLabel", "ExperienceLabel")
	if statusLabel then
		local isNew = getIsNewPlayer()
		statusLabel.Text = isNew and "New Player" or "Experienced"
		log:Info("updateJoinGuiProfile", "Set player status: %s", statusLabel.Text)
	end
end

----------------------------------------------------------------
-- GUI Visibility Management
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
	local showJoin = mode == GameMode.Join
	setGuiEnabled(joinGameGui, showJoin)
	
	-- Оновлюємо профіль коли показуємо JoinGui
	if showJoin then
		updateJoinGuiProfile()
	end
	
	-- Station GUI: видимий тільки в режимі Station
	setGuiEnabled(stationGui, mode == GameMode.Station)
	
	-- Location GUI: видимий тільки в режимі Location
	setGuiEnabled(locationGui, mode == GameMode.Location)
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
      Обробляє клік на кнопку "Go to Location" (Station → Location).
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
    onReturnToStationButtonClick()
    Призначення:
      Обробляє клік на кнопку "Return to Station" (Location → Station).
--]]
local function onReturnToStationButtonClick()
	log:Info("onReturnToStationButtonClick", "Return to Station button clicked")
	
	local returnEvent = Events.Get(RemoteEvent.ReturnToStation)
	if returnEvent then
		returnEvent:FireServer()
	else
		log:Error("onReturnToStationButtonClick", "ReturnToStation event not found")
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
	local joinButton = findButton(joinGameGui, 
		"JoinButton", "JoinGameButton", "PlayButton", "StartButton")
	
	if joinButton then
		joinButton.Activated:Connect(onJoinButtonClick)
		log:Info("setupJoinGui", "Join button connected: %s", joinButton.Name)
	else
		log:Warn("setupJoinGui", "Join button not found in JoinGameGui")
	end
	
	-- Заповнюємо профіль
	updateJoinGuiProfile()
	
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
	local goLocationButton = findButton(stationGui, 
		"GoLocationButton", "GoToLocationButton", "LocationButton")
	
	if goLocationButton then
		goLocationButton.Activated:Connect(onGoLocationButtonClick)
		log:Info("setupStationGui", "GoLocation button connected: %s", goLocationButton.Name)
	end
	
	-- Кнопка Exit
	local exitButton = findButton(stationGui, 
		"ExitButton", "ExitGameButton", "BackButton")
	
	if exitButton then
		exitButton.Activated:Connect(onExitButtonClick)
		log:Info("setupStationGui", "Exit button connected: %s", exitButton.Name)
	end
	
	-- Початково ховаємо
	stationGui.Enabled = false
end

--[[
    setupLocationGui()
    Призначення:
      Налаштовує LocationGui та підключає обробники кнопок.
      LocationGui показується коли гравець на планетній локації.
--]]
local function setupLocationGui()
	locationGui = playerGui:WaitForChild("LocationGui", 10) :: ScreenGui?
	
	if not locationGui then
		log:Warn("setupLocationGui", "LocationGui not found (will be created later)")
		return
	end
	
	log:Info("setupLocationGui", "LocationGui found")
	
	-- Кнопка Return to Station (Location → Station)
	local returnButton = findButton(locationGui, 
		"ReturnToStationButton", "ReturnButton", "BackToStationButton", "StationButton")
	
	if returnButton then
		returnButton.Activated:Connect(onReturnToStationButtonClick)
		log:Info("setupLocationGui", "ReturnToStation button connected: %s", returnButton.Name)
	end
	
	-- Кнопка Exit (Location → Join)
	local exitButton = findButton(locationGui, 
		"ExitButton", "ExitGameButton")
	
	if exitButton then
		exitButton.Activated:Connect(onExitButtonClick)
		log:Info("setupLocationGui", "Exit button connected: %s", exitButton.Name)
	end
	
	-- Початково ховаємо
	locationGui.Enabled = false
end

----------------------------------------------------------------
-- Attribute Change Listeners
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

--[[
    setupIsNewListener()
    Призначення:
      Підключає слухача змін атрибута IsNewPlayer.
--]]
local function setupIsNewListener()
	player:GetAttributeChangedSignal(Attribute.IsNewPlayer):Connect(function()
		updateJoinGuiProfile()
	end)
	
	log:Info("setupIsNewListener", "IsNewPlayer change listener connected")
end

----------------------------------------------------------------
-- Initialization
----------------------------------------------------------------

--[[
    init()
    Призначення:
      Ініціалізує клієнт гри.
      1. Очікує готовності Events
      2. Налаштовує GUI
      3. Підключає слухачів атрибутів
      4. Оновлює видимість на основі поточного стану
--]]
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
	setupLocationGui()
	
	-- Підключаємо слухачів змін атрибутів
	setupModeListener()
	setupIsNewListener()
	
	-- Оновлюємо видимість на основі поточного стану
	-- (на випадок якщо атрибут вже встановлений)
	updateGuiVisibility()
	
	log:Info("init", "=== GameClient Ready ===")
end

-- Start
init()

----------------------------------------------------------------
-- End of script: GameClient v2.1.0
----------------------------------------------------------------
