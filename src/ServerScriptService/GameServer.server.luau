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
-- Player Profile Storage (Mock for MVP)
----------------------------------------------------------------

--[[
    playerProfiles
    Призначення:
      Тимчасове сховище профілів гравців (mock замість DataStore).
      Для MVP: всі гравці вважаються новими при кожному запуску.
    
    TODO: Замінити на DataStoreService для persistence.
--]]
local playerProfiles: { [number]: { isNew: boolean } } = {}

----------------------------------------------------------------
-- Helper Functions: Profile
----------------------------------------------------------------

--[[
    loadPlayerProfile(player)
    Призначення:
      Завантажує профіль гравця з сховища.
      Для MVP: завжди повертає новий профіль.

    Вхідні параметри:
      player (Player) — гравець

    Вихід:
      { isNew: boolean } — профіль гравця

    TODO: Інтегрувати з DataStoreService.
--]]
local function loadPlayerProfile(player: Player): { isNew: boolean }
	local userId = player.UserId
	
	-- Перевіряємо чи вже є профіль в пам'яті
	if playerProfiles[userId] then
		log:Info("loadPlayerProfile", "%s: Existing profile loaded", player.Name)
		return playerProfiles[userId]
	end
	
	-- TODO: Тут буде DataStore:GetAsync()
	-- Для MVP: всі нові
	local profile = {
		isNew = true,
	}
	
	playerProfiles[userId] = profile
	log:Info("loadPlayerProfile", "%s: New profile created (MVP mock)", player.Name)
	
	return profile
end

--[[
    savePlayerProfile(player)
    Призначення:
      Зберігає профіль гравця.
      Для MVP: оновлює isNew на false.

    Вхідні параметри:
      player (Player) — гравець

    TODO: Інтегрувати з DataStoreService.
--]]
local function savePlayerProfile(player: Player)
	local userId = player.UserId
	
	if playerProfiles[userId] then
		-- Після першого Join гравець вже не новий
		playerProfiles[userId].isNew = false
		log:Info("savePlayerProfile", "%s: Profile saved (isNew = false)", player.Name)
	end
	
	-- TODO: Тут буде DataStore:SetAsync()
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
      Обробляє запит гравця на перехід до локації.
--]]
local function onGoToLocation(player: Player)
	local currentMode = getPlayerMode(player)
	
	if currentMode ~= GameMode.Station then
		log:Warn("onGoToLocation", "%s tried to go to location but is in mode: %s", player.Name, tostring(currentMode))
		return
	end
	
	log:Info("onGoToLocation", "%s is going to location", player.Name)
	
	-- TODO: Телепортувати на локацію
	setPlayerMode(player, GameMode.Location)
end

--[[
    onExitGame(player)
    Призначення:
      Обробляє запит гравця на вихід з гри.
      Видаляє персонажа і повертає в режим Join.
--]]
local function onExitGame(player: Player)
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
