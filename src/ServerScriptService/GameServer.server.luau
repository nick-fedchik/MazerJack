--[[
    Тип скрипта: Script (Server)
    Назва: GameServer
    Версія: 2.0.0
    Розміщення: ServerScriptService/GameServer

    Призначення:
      ЄДИНА точка входу серверної логіки гри MazerJack.
      Керує станом гравців та обробляє всі RemoteEvents.

    Загальна логіка:
      1. Ініціалізує Events
      2. При підключенні гравця — ставить CurrentMode = "Join"
      3. При отриманні JoinGame — спавнить гравця, ставить "Station"
      4. При GoToLocation — перехід на локацію (TODO)
      5. При ExitGame — повертає в Join

    Контракти:
      - Player.CurrentMode — атрибут, єдине джерело правди
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

local log = Logger.new("GameServer", "2.0.0")

----------------------------------------------------------------
-- Constants shortcuts
----------------------------------------------------------------

local GameMode = Constants.GameMode
local Attribute = Constants.Attribute
local RemoteEvent = Constants.RemoteEvent

----------------------------------------------------------------
-- Helper Functions
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
    spawnPlayerAtStation(player)
    Призначення:
      Спавнить персонажа гравця на станції.

    Вхідні параметри:
      player (Player) — гравець

    Побічні ефекти:
      - Завантажує персонажа
--]]
local function spawnPlayerAtStation(player: Player)
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
--]]
local function onPlayerAdded(player: Player)
	log:Info("onPlayerAdded", "Player joined: %s (UserId: %d)", player.Name, player.UserId)
	
	-- Встановлюємо початковий стан
	setPlayerMode(player, GameMode.Join)
end

--[[
    onPlayerRemoving(player)
    Призначення:
      Обробляє відключення гравця.
--]]
local function onPlayerRemoving(player: Player)
	log:Info("onPlayerRemoving", "Player left: %s", player.Name)
	-- Тут можна зберегти прогрес (TODO)
end

--[[
    onJoinGame(player)
    Призначення:
      Обробляє запит гравця на вхід у гру.
--]]
local function onJoinGame(player: Player)
	local currentMode = getPlayerMode(player)
	
	if currentMode ~= GameMode.Join then
		log:Warn("onJoinGame", "%s tried to join but is in mode: %s", player.Name, tostring(currentMode))
		return
	end
	
	log:Info("onJoinGame", "%s is joining the game", player.Name)
	
	-- Спавнимо персонажа
	spawnPlayerAtStation(player)
	
	-- Переходимо в режим Station
	setPlayerMode(player, GameMode.Station)
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
--]]
local function onExitGame(player: Player)
	log:Info("onExitGame", "%s is exiting game", player.Name)
	
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
-- End of script: GameServer v2.0.0
----------------------------------------------------------------
