--[[
    Тип: LocalScript
    Назва: JoinScreenClient
    Версія: 1.2.0
    Розміщення: StarterGui/JoinGameGui/JoinScreenClient

    Призначення:
      Клієнтська стартова заставка приєднання до гри (Sprint 1).
      ЄДИНА точка входу гравця в гру.

    Загальна логіка:
      1. GUI активний одразу після завантаження клієнта
      2. Поетапно відображає:
         - PlayerName
         - PlayerStatus
         - GameStatus
      3. Після успішної ініціалізації активує кнопку "Join Game"
      4. По кліку надсилає JoinGame на сервер
      5. Ховає GUI ТІЛЬКИ після переходу гравця в StationMode

    Взаємодія / контракти:
      - Client → Server:
          GameEvents.Event.JoinGame
      - Client ← Server:
          Player Attribute "CurrentMode"

    Архітектурні правила:
      - НЕ змінює GameState
      - НЕ керує Spawn
      - НЕ взаємодіє зі Station GUI
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

local log = Logger.new("JoinScreenClient", "1.2.0")

----------------------------------------------------------------
-- Player / GUI resolution
----------------------------------------------------------------

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = playerGui:WaitForChild("JoinGameGui")
local root = gui:WaitForChild("Root", 10)

if not root then
  log:Error("Init", "Root not found under JoinGameGui (check UI hierarchy)")
  return
end

----------------------------------------------------------------
-- UI elements
----------------------------------------------------------------

local lblPlayerName   = root:WaitForChild("PlayerName")
local lblPlayerStatus = root:WaitForChild("PlayerStatus")
local lblGameStatus   = root:WaitForChild("GameStatus")
local btnJoinGame     = root:WaitForChild("JoinGameButton")

----------------------------------------------------------------
-- Remote
----------------------------------------------------------------

local gameRemote = GameEvents.GetGameRemote()

----------------------------------------------------------------
-- Initial UI state
----------------------------------------------------------------

gui.Enabled = true

lblPlayerName.Visible   = false
lblPlayerStatus.Visible = false
lblGameStatus.Visible   = false

btnJoinGame.Visible = false
btnJoinGame.Active  = false

log:Info("Init", "JoinScreen initialized and locked")

----------------------------------------------------------------
-- Function: revealPlayerName
-- Призначення:
--   Відображає ім’я гравця на екрані заставки.
-- Вхідні параметри:
--   none
-- Вихід / ефект:
--   Робить PlayerName видимим
-- Хто використовує:
--   JoinScreenClient (Sprint 1)
----------------------------------------------------------------
local function revealPlayerName()
	lblPlayerName.Text = player.Name
	lblPlayerName.Visible = true
	log:Info("UI", "PlayerName shown")
end

----------------------------------------------------------------
-- Function: revealPlayerStatus
-- Призначення:
--   Відображає статус гравця (Sprint 1: Ready).
-- Вхідні параметри:
--   none
-- Вихід / ефект:
--   Робить PlayerStatus видимим
-- Хто використовує:
--   JoinScreenClient (Sprint 1)
----------------------------------------------------------------
local function revealPlayerStatus()
	lblPlayerStatus.Text = "Ready"
	lblPlayerStatus.Visible = true
	log:Info("UI", "PlayerStatus shown")
end

----------------------------------------------------------------
-- Function: revealGameStatusAndEnableJoin
-- Призначення:
--   Показує статус гри та активує кнопку Join Game.
-- Вхідні параметри:
--   none
-- Вихід / ефект:
--   Активує можливість приєднання до гри
-- Хто використовує:
--   JoinScreenClient (Sprint 1)
----------------------------------------------------------------
local function revealGameStatusAndEnableJoin()
	lblGameStatus.Text = "Ready"
	lblGameStatus.Visible = true

	btnJoinGame.Visible = true
	btnJoinGame.Active  = true

	log:Info("UI", "Join Game enabled")
end

----------------------------------------------------------------
-- Deterministic reveal sequence (Sprint 1)
----------------------------------------------------------------

task.delay(0.5, revealPlayerName)
task.delay(1.0, revealPlayerStatus)
task.delay(1.5, revealGameStatusAndEnableJoin)

----------------------------------------------------------------
-- Function: onJoinGameClicked
-- Призначення:
--   Обробляє клік по кнопці Join Game.
-- Вхідні параметри:
--   none (MouseButton1Click)
-- Вихід / ефект:
--   Надсилає JoinGame на сервер
-- Хто використовує:
--   Кнопка JoinGameButton
----------------------------------------------------------------
local function onJoinGameClicked()
	lblGameStatus.Text = "Joining..."
	btnJoinGame.Active = false

	log:Info("JoinClick", "JoinGame requested userId=%d", player.UserId)

	gameRemote:FireServer(GameEvents.Event.JoinGame)
end

btnJoinGame.MouseButton1Click:Connect(onJoinGameClicked)

----------------------------------------------------------------
-- Function: onModeChanged
-- Призначення:
--   Ховає JoinScreen після входу в StationMode.
-- Вхідні параметри:
--   none (AttributeChangedSignal)
-- Вихід / ефект:
--   Вимикає JoinGameGui
-- Хто використовує:
--   Player Attribute "CurrentMode"
----------------------------------------------------------------
local function onModeChanged()
	local mode = player:GetAttribute("CurrentMode")

	if mode == "Station" then
		gui.Enabled = false
		log:Info("UI", "JoinScreen hidden (Station entered)")
	elseif mode == "Join" then
		gui.Enabled = true
		log:Info("UI", "JoinScreen shown (returned to Join)")
	end
end

player:GetAttributeChangedSignal("CurrentMode"):Connect(onModeChanged)

----------------------------------------------------------------
-- End of script: JoinScreenClient v1.1.0
----------------------------------------------------------------
