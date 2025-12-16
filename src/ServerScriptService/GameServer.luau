--[[
    Тип скрипта: Script (Server)
    Назва: GameServer
    Версія: 2.1.0
    Розміщення: ServerScriptService/GameServer

    Призначення:
      ЄДИНА точка входу серверної логіки гри MazerJack.
      Керує станом гравців та обробляє всі RemoteEvents.

    Загальна логіка:
      1. Ініціалізує Events
      2. При підключенні гравця:
         - Завантажує профіль (New/Experienced)
         - Встановлює CurrentMode = "Join"
         - Встановлює IsNewPlayer атрибут
      3. При отриманні JoinGame:
         - Знаходить SpawnLocation в CommandModule
         - Спавнить гравця на SpawnLocation
         - Встановлює CurrentMode = "Station"
      4. При GoToLocation — перехід на локацію (TODO)
      5. При ExitGame — повертає в Join

    Контракти:
      - Player.CurrentMode — атрибут, єдине джерело правди для режиму
      - Player.IsNewPlayer — атрибут, визначає чи гравець новий
      - Всі переходи станів тільки тут
      - Клієнт НЕ може змінювати стан напряму
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

local log = Logger.new("GameServer", "2.1.0")

----------------------------------------------------------------
-- Constants shortcuts
----------------------------------------------------------------

local GameMode = Constants.GameMode
local Attribute = Constants.Attribute
local RemoteEvent = Constants.RemoteEvent
local Path = Constants.Path

----------------------------------------------------------------
-- DataStore
----------------------------------------------------------------

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

--[[
    DATASTORE_KEY_PREFIX
    Призначення:
      Префікс для ключів гравців в DataStore.
--]]
local DATASTORE_KEY_PREFIX = "Player_"

--[[
    TRANSITION_COOLDOWN
    Призначення:
      Мінімальний час між переходами станів (секунди).
      Захищає від спаму RemoteEvents.
--]]
local TRANSITION_COOLDOWN = 1.0

--[[
    playerDataStore
    Призначення:
      DataStore для збереження профілів гравців.
      В Studio використовується mock-режим.
--]]
local playerDataStore: DataStore?
local isStudio = RunService:IsStudio()

if not isStudio then
	local success, result = pcall(function()
		return DataStoreService:GetDataStore("MazerJackPlayerData_v1")
	end)
	if success then
		playerDataStore = result
		log:Info("DataStore", "DataStore initialized successfully")
	else
		log:Warn("DataStore", "Failed to get DataStore: %s", tostring(result))
	end
else
	log:Info("DataStore", "Running in Studio - using mock DataStore")
end

--[[
    playerProfiles
    Призначення:
      Кеш профілів гравців в пам'яті.
      Синхронізується з DataStore при load/save.
--]]
local playerProfiles: { [number]: { isNew: boolean } } = {}

--[[
    lastTransitionTime
    Призначення:
      Трекер останнього часу переходу для кожного гравця.
      Використовується для cooldown захисту.
--]]
local lastTransitionTime: { [number]: number } = {}

----------------------------------------------------------------
-- Helper Functions: Profile
----------------------------------------------------------------

--[[
    loadPlayerProfile(player)
    Призначення:
      Завантажує профіль гравця з DataStore.
      Використовує кеш та retry logic.

    Вхідні параметри:
      player (Player) — гравець

    Вихід:
      { isNew: boolean } — профіль гравця
--]]
local function loadPlayerProfile(player: Player): { isNew: boolean }
	local userId = player.UserId
	local key = DATASTORE_KEY_PREFIX .. tostring(userId)
	
	-- Перевіряємо кеш
	if playerProfiles[userId] then
		log:Info("loadPlayerProfile", "%s: Profile loaded from cache", player.Name)
		return playerProfiles[userId]
	end
	
	-- Профіль за замовчуванням (новий гравець)
	local profile = { isNew = true }
	
	-- Завантажуємо з DataStore (тільки не в Studio)
	if playerDataStore then
		local MAX_RETRIES = 3
		for attempt = 1, MAX_RETRIES do
			local success, result = pcall(function()
				return playerDataStore:GetAsync(key)
			end)
			
			if success then
				if result then
					profile = result
					log:Info("loadPlayerProfile", "%s: Profile loaded from DataStore (isNew=%s)", 
						player.Name, tostring(profile.isNew))
				else
					log:Info("loadPlayerProfile", "%s: No saved profile, creating new", player.Name)
				end
				break
			else
				log:Warn("loadPlayerProfile", "%s: DataStore read failed (attempt %d/%d): %s", 
					player.Name, attempt, MAX_RETRIES, tostring(result))
				if attempt < MAX_RETRIES then
					task.wait(1)
				end
			end
		end
	else
		log:Info("loadPlayerProfile", "%s: Studio mode - new profile created", player.Name)
	end
	
	playerProfiles[userId] = profile
	return profile
end

--[[
    savePlayerProfile(player)
    Призначення:
      Зберігає профіль гравця в DataStore.
      Оновлює isNew на false після першого Join.

    Вхідні параметри:
      player (Player) — гравець
--]]
local function savePlayerProfile(player: Player)
	local userId = player.UserId
	local key = DATASTORE_KEY_PREFIX .. tostring(userId)
	
	if not playerProfiles[userId] then
		log:Warn("savePlayerProfile", "%s: No profile in cache to save", player.Name)
		return
	end
	
	-- Оновлюємо isNew
	playerProfiles[userId].isNew = false
	
	-- Зберігаємо в DataStore
	if playerDataStore then
		local MAX_RETRIES = 3
		for attempt = 1, MAX_RETRIES do
			local success, err = pcall(function()
				playerDataStore:SetAsync(key, playerProfiles[userId])
			end)
			
			if success then
				log:Info("savePlayerProfile", "%s: Profile saved to DataStore", player.Name)
				return
			else
				log:Warn("savePlayerProfile", "%s: DataStore write failed (attempt %d/%d): %s", 
					player.Name, attempt, MAX_RETRIES, tostring(err))
				if attempt < MAX_RETRIES then
					task.wait(1)
				end
			end
		end
	else
		log:Info("savePlayerProfile", "%s: Studio mode - profile cached (isNew = false)", player.Name)
	end
end

--[[
    canTransition(player)
    Призначення:
      Перевіряє чи минув cooldown з останнього переходу.
      Захищає від спаму RemoteEvents.

    Вхідні параметри:
      player (Player) — гравець

    Вихід:
      boolean — true якщо перехід дозволений
--]]
local function canTransition(player: Player): boolean
	local userId = player.UserId
	local now = tick()
	
	local lastTime = lastTransitionTime[userId] or 0
	if now - lastTime < TRANSITION_COOLDOWN then
		log:Warn("canTransition", "%s: Transition blocked (cooldown %.1fs remaining)", 
			player.Name, TRANSITION_COOLDOWN - (now - lastTime))
		return false
	end
	
	lastTransitionTime[userId] = now
	return true
end

----------------------------------------------------------------
-- Helper Functions: State
----------------------------------------------------------------

--[[
    setPlayerMode(player, mode)
    Призначення:
      Встановлює режим гри для гравця.

    Вхідні параметри:
      player (Player) — гравець
      mode (string) — режим з GameMode

    Побічні ефекти:
      - Встановлює атрибут CurrentMode на гравця
--]]
local function setPlayerMode(player: Player, mode: string)
	local oldMode = player:GetAttribute(Attribute.CurrentMode)
	player:SetAttribute(Attribute.CurrentMode, mode)
	log:Info("setPlayerMode", "%s: %s → %s", player.Name, tostring(oldMode), mode)
end

--[[
    getPlayerMode(player)
    Призначення:
      Отримує поточний режим гри гравця.

    Вхідні параметри:
      player (Player) — гравець

    Вихід:
      string | nil — поточний режим
--]]
local function getPlayerMode(player: Player): string?
	return player:GetAttribute(Attribute.CurrentMode)
end

--[[
    setPlayerIsNew(player, isNew)
    Призначення:
      Встановлює атрибут IsNewPlayer.

    Вхідні параметри:
      player (Player) — гравець
      isNew (boolean) — чи гравець новий
--]]
local function setPlayerIsNew(player: Player, isNew: boolean)
	player:SetAttribute(Attribute.IsNewPlayer, isNew)
	log:Info("setPlayerIsNew", "%s: IsNewPlayer = %s", player.Name, tostring(isNew))
end

----------------------------------------------------------------
-- Helper Functions: Spawn
----------------------------------------------------------------

--[[
    findSpawnLocation()
    Призначення:
      Знаходить SpawnLocation в CommandModule.

    Вихід:
      SpawnLocation | nil — знайдений SpawnLocation або nil
--]]
local function findSpawnLocation(): SpawnLocation?
	local workspace = game:GetService("Workspace")
	
	-- Шукаємо за шляхом з Constants
	local pathParts = string.split(Path.SpawnLocation, "/")
	local current: Instance = workspace
	
	for _, part in ipairs(pathParts) do
		local child = current:FindFirstChild(part)
		if not child then
			log:Warn("findSpawnLocation", "Path not found at: %s (looking for %s)", current:GetFullName(), part)
			return nil
		end
		current = child
	end
	
	if current:IsA("SpawnLocation") then
		log:Info("findSpawnLocation", "Found SpawnLocation: %s", current:GetFullName())
		return current :: SpawnLocation
	end
	
	log:Warn("findSpawnLocation", "Found object is not SpawnLocation: %s", current.ClassName)
	return nil
end

--[[
    spawnPlayerAtStation(player)
    Призначення:
      Спавнить персонажа гравця на станції.
      Використовує SpawnLocation в CommandModule якщо доступний.

    Вхідні параметри:
      player (Player) — гравець

    Побічні ефекти:
      - Встановлює RespawnLocation якщо знайдено SpawnLocation
      - Завантажує персонажа
--]]
local function spawnPlayerAtStation(player: Player)
	-- Шукаємо SpawnLocation
	local spawnLocation = findSpawnLocation()
	
	if spawnLocation then
		player.RespawnLocation = spawnLocation
		log:Info("spawnPlayerAtStation", "%s: RespawnLocation set to %s", player.Name, spawnLocation:GetFullName())
	else
		log:Warn("spawnPlayerAtStation", "%s: SpawnLocation not found, using default spawn", player.Name)
	end
	
	-- Завантажуємо персонажа
	log:Info("spawnPlayerAtStation", "Loading character for %s", player.Name)
	player:LoadCharacter()
end

----------------------------------------------------------------
-- Event Handlers
----------------------------------------------------------------

--[[
    onPlayerAdded(player)
    Призначення:
      Обробляє підключення нового гравця.
      1. Завантажує профіль
      2. Встановлює атрибути (IsNewPlayer, CurrentMode)
--]]
local function onPlayerAdded(player: Player)
	log:Info("onPlayerAdded", "Player joined: %s (UserId: %d, DisplayName: %s)", 
		player.Name, player.UserId, player.DisplayName)
	
	-- Завантажуємо профіль
	local profile = loadPlayerProfile(player)
	
	-- Встановлюємо атрибут IsNewPlayer
	setPlayerIsNew(player, profile.isNew)
	
	-- Встановлюємо початковий режим
	setPlayerMode(player, GameMode.Join)
end

--[[
    onPlayerRemoving(player)
    Призначення:
      Обробляє відключення гравця.
      Зберігає профіль перед виходом.
--]]
local function onPlayerRemoving(player: Player)
	log:Info("onPlayerRemoving", "Player left: %s", player.Name)
	
	-- Зберігаємо профіль
	savePlayerProfile(player)
	
	-- Очищаємо кеш
	local userId = player.UserId
	task.delay(5, function()
		playerProfiles[userId] = nil
		lastTransitionTime[userId] = nil
		log:Info("onPlayerRemoving", "Cleaned up cache for UserId: %d", userId)
	end)
end

--[[
    onJoinGame(player)
    Призначення:
      Обробляє запит гравця на вхід у гру.
      1. Перевіряє що гравець в режимі Join
      2. Спавнить на SpawnLocation
      3. Переводить в режим Station
      4. Оновлює профіль (більше не новий)
--]]
local function onJoinGame(player: Player)
	-- Cooldown check
	if not canTransition(player) then
		return
	end
	
	local currentMode = getPlayerMode(player)
	
	if currentMode ~= GameMode.Join then
		log:Warn("onJoinGame", "%s tried to join but is in mode: %s", player.Name, tostring(currentMode))
		return
	end
	
	log:Info("onJoinGame", "%s is joining the game", player.Name)
	
	-- Спавнимо персонажа на станції
	spawnPlayerAtStation(player)
	
	-- Переходимо в режим Station
	setPlayerMode(player, GameMode.Station)
	
	-- Оновлюємо профіль: гравець більше не новий
	setPlayerIsNew(player, false)
	savePlayerProfile(player)
end

--[[
    onGoToLocation(player)
    Призначення:
      Обробляє запит гравця на перехід до локації (планети).
      Доступно тільки з режиму Station.
--]]
local function onGoToLocation(player: Player)
	-- Cooldown check
	if not canTransition(player) then
		return
	end
	
	local currentMode = getPlayerMode(player)
	
	if currentMode ~= GameMode.Station then
		log:Warn("onGoToLocation", "%s tried to go to location but is in mode: %s", player.Name, tostring(currentMode))
		return
	end
	
	log:Info("onGoToLocation", "%s is going to location (Station → Location)", player.Name)
	
	-- TODO: Телепортувати на локацію, сховати Station
	setPlayerMode(player, GameMode.Location)
end

--[[
    onReturnToStation(player)
    Призначення:
      Обробляє запит гравця на повернення на космічну станцію.
      Доступно тільки з режиму Location.
--]]
local function onReturnToStation(player: Player)
	-- Cooldown check
	if not canTransition(player) then
		return
	end
	
	local currentMode = getPlayerMode(player)
	
	if currentMode ~= GameMode.Location then
		log:Warn("onReturnToStation", "%s tried to return to station but is in mode: %s", player.Name, tostring(currentMode))
		return
	end
	
	log:Info("onReturnToStation", "%s is returning to station (Location → Station)", player.Name)
	
	-- TODO: Телепортувати назад на станцію, показати Station
	-- Спавнимо на станції
	spawnPlayerAtStation(player)
	
	setPlayerMode(player, GameMode.Station)
end

--[[
    onExitGame(player)
    Призначення:
      Обробляє запит гравця на вихід з гри.
      Видаляє персонажа і повертає в режим Join.
--]]
local function onExitGame(player: Player)
	-- Cooldown check
	if not canTransition(player) then
		return
	end
	
	log:Info("onExitGame", "%s is exiting game", player.Name)
	
	-- Зберігаємо профіль перед виходом
	savePlayerProfile(player)
	
	-- Видаляємо персонажа
	if player.Character then
		player.Character:Destroy()
	end
	
	-- Повертаємо в режим Join
	setPlayerMode(player, GameMode.Join)
end

----------------------------------------------------------------
-- Initialization
----------------------------------------------------------------

--[[
    init()
    Призначення:
      Ініціалізує сервер гри.
      1. Створює RemoteEvents
      2. Підключає обробники подій гравців
      3. Підключає RemoteEvent handlers
--]]
local function init()
	log:Info("init", "=== %s v%s Server Starting ===", Constants.Game.Name, Constants.Game.Version)
	
	-- Створюємо RemoteEvents
	Events.Init()
	log:Info("init", "Events initialized")
	
	-- Підключаємо обробники подій гравців
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	
	-- Обробляємо гравців, які вже є (для Studio testing)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end
	
	-- Підключаємо RemoteEvent handlers
	local joinEvent = Events.Get(RemoteEvent.JoinGame)
	if joinEvent then
		joinEvent.OnServerEvent:Connect(onJoinGame)
		log:Info("init", "JoinGame event connected")
	end
	
	local goLocationEvent = Events.Get(RemoteEvent.GoToLocation)
	if goLocationEvent then
		goLocationEvent.OnServerEvent:Connect(onGoToLocation)
		log:Info("init", "GoToLocation event connected")
	end
	
	local returnToStationEvent = Events.Get(RemoteEvent.ReturnToStation)
	if returnToStationEvent then
		returnToStationEvent.OnServerEvent:Connect(onReturnToStation)
		log:Info("init", "ReturnToStation event connected")
	end
	
	local exitEvent = Events.Get(RemoteEvent.ExitGame)
	if exitEvent then
		exitEvent.OnServerEvent:Connect(onExitGame)
		log:Info("init", "ExitGame event connected")
	end
	
	log:Info("init", "=== Server Ready ===")
end

-- Start
init()

----------------------------------------------------------------
-- End of script: GameServer v2.1.0
----------------------------------------------------------------
