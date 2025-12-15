--[[
    Тип: LocalScript
    Назва: JoinScreenClient
  Версія: 1.2.4
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

local log = Logger.new("JoinScreenClient", "1.2.4")

----------------------------------------------------------------
-- Player / GUI resolution
----------------------------------------------------------------

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = playerGui:WaitForChild("JoinGameGui")

-- Ensure Join UI is visible by default (Sprint 1 baseline)
gui.Enabled = true

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
--   JoinScreenClient (resolution без жорсткої залежності від Root)
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

local lblPlayerName = waitForDescendant(gui, "PlayerName", 10)
local lblPlayerStatus = waitForDescendant(gui, "PlayerStatus", 10)
local lblGameStatus = waitForDescendant(gui, "GameStatus", 10)
local btnJoinGame = waitForDescendant(gui, "JoinGameButton", 10)

if not (lblPlayerName and lblPlayerStatus and lblGameStatus and btnJoinGame) then
  log:Error(
    "Init",
    "Join UI elements missing (check names: PlayerName/PlayerStatus/GameStatus/JoinGameButton)"
  )
  return
end

local lblPlayerNameLabel = lblPlayerName :: any
local lblPlayerStatusLabel = lblPlayerStatus :: any
local lblGameStatusLabel = lblGameStatus :: any
local btnJoinGameButton = btnJoinGame :: any

----------------------------------------------------------------
-- Remote
----------------------------------------------------------------

local gameRemote = GameEvents.GetGameRemote()

----------------------------------------------------------------
-- Initial UI state
----------------------------------------------------------------

gui.Enabled = true

lblPlayerNameLabel.Visible = false
lblPlayerStatusLabel.Visible = false
lblGameStatusLabel.Visible = false

btnJoinGameButton.Visible = false
btnJoinGameButton.Active = false

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
  lblPlayerNameLabel.Text = player.Name
  lblPlayerNameLabel.Visible = true
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
  lblPlayerStatusLabel.Text = "Ready"
  lblPlayerStatusLabel.Visible = true
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
	lblGameStatusLabel.Text = "Ready"
	lblGameStatusLabel.Visible = true

	btnJoinGameButton.Visible = true
	btnJoinGameButton.Active = true

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
  lblGameStatusLabel.Text = "Joining..."
  btnJoinGameButton.Active = false

	log:Info("JoinClick", "JoinGame requested userId=%d", player.UserId)

	gameRemote:FireServer(GameEvents.Event.JoinGame)
end

btnJoinGameButton.MouseButton1Click:Connect(onJoinGameClicked)

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
-- End of script: JoinScreenClient v1.2.4
----------------------------------------------------------------
