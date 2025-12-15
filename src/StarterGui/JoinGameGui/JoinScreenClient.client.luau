--[[
    Тип: LocalScript
    Назва: JoinScreenClient
  Версія: 1.2.6
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

local log = Logger.new("JoinScreenClient", "1.2.6")

----------------------------------------------------------------
-- Player / GUI resolution
----------------------------------------------------------------

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = playerGui:WaitForChild("JoinGameGui")

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

-- Function: ensureMinimalJoinUi
-- Призначення:
--   Створює мінімальний набір UI-елементів для JoinScreen, якщо вони відсутні в ассетах.
--   Це потрібно, бо репозиторій може не містити rbxmx/UI, а скрипт не повинен зависати на очікуванні.
-- Вхідні параметри:
--   screenGui: ScreenGui
-- Вихід:
--   (TextLabel, TextLabel, TextLabel, TextButton)
-- Хто використовує:
--   JoinScreenClient (Init)
local function ensureMinimalJoinUi(screenGui: ScreenGui)
  local root = screenGui:FindFirstChild("Root")
  if not root then
    root = Instance.new("Frame")
    root.Name = "Root"
    root.BackgroundTransparency = 1
    root.Size = UDim2.fromScale(1, 1)
    root.Parent = screenGui
  end

  local function ensureTextLabel(name: string)
    local existing = screenGui:FindFirstChild(name, true)
    if existing and existing:IsA("TextLabel") then
      return existing
    end

    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromOffset(300, 40)
    label.AnchorPoint = Vector2.new(0.5, 0)
    label.Position = UDim2.fromScale(0.5, 0)
    label.Text = name
    label.Parent = root
    return label
  end

  local function ensureTextButton(name: string)
    local existing = screenGui:FindFirstChild(name, true)
    if existing and existing:IsA("TextButton") then
      return existing
    end

    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.fromOffset(240, 50)
    button.AnchorPoint = Vector2.new(0.5, 0)
    button.Position = UDim2.fromScale(0.5, 0)
    button.Text = "Join Game"
    button.Parent = root
    return button
  end

  local playerName = ensureTextLabel("PlayerName")
  local playerStatus = ensureTextLabel("PlayerStatus")
  local gameStatus = ensureTextLabel("GameStatus")
  local joinButton = ensureTextButton("JoinGameButton")

  -- Minimal layout (vertical stack)
  local list = root:FindFirstChildOfClass("UIListLayout")
  if not list then
    list = Instance.new("UIListLayout")
    list.FillDirection = Enum.FillDirection.Vertical
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 10)
    list.Parent = root
  end

  return playerName, playerStatus, gameStatus, joinButton
end

local lblPlayerName = waitForDescendant(gui, "PlayerName", 1)
local lblPlayerStatus = waitForDescendant(gui, "PlayerStatus", 1)
local lblGameStatus = waitForDescendant(gui, "GameStatus", 1)
local btnJoinGame = waitForDescendant(gui, "JoinGameButton", 1)

if not (lblPlayerName and lblPlayerStatus and lblGameStatus and btnJoinGame) then
  log:Warn(
    "Init",
    "Join UI elements missing in assets; creating minimal UI (names: PlayerName/PlayerStatus/GameStatus/JoinGameButton)"
  )
  lblPlayerName, lblPlayerStatus, lblGameStatus, btnJoinGame = ensureMinimalJoinUi(gui)
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

-- NOTE:
-- JoinGameGui is expected to be Disabled by default in assets.
-- Visibility is controlled via CurrentMode (see onModeChanged).

lblPlayerNameLabel.Visible = false
lblPlayerStatusLabel.Visible = false
lblGameStatusLabel.Visible = false

btnJoinGameButton.Visible = false
btnJoinGameButton.Active = false

log:Info("Init", "JoinScreen initialized and locked")
local revealStarted = false

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
-- Function: startRevealSequence
-- Призначення:
--   Запускає детерміновану послідовність показу елементів (Sprint 1).
-- Вхідні параметри:
--   none
-- Вихід / ефект:
--   Поступово показує тексти і вмикає кнопку Join Game
-- Хто використовує:
--   onModeChanged (коли JoinScreen стає видимим)
----------------------------------------------------------------
local function startRevealSequence()
  task.delay(0.5, revealPlayerName)
  task.delay(1.0, revealPlayerStatus)
  task.delay(1.5, revealGameStatusAndEnableJoin)
end

----------------------------------------------------------------
-- Deterministic reveal sequence (Sprint 1)
----------------------------------------------------------------

-- Started lazily when the JoinScreen becomes visible

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
  local shouldShow = (mode == nil or mode == "Join")

  if shouldShow then
    if not gui.Enabled then
      gui.Enabled = true
      log:Info("UI", "JoinScreen shown mode=%s", tostring(mode))
    end

    if not revealStarted then
      revealStarted = true
      startRevealSequence()
    end
    return
  end

  if gui.Enabled then
    gui.Enabled = false
    log:Info("UI", "JoinScreen hidden mode=%s", tostring(mode))
  end
end

player:GetAttributeChangedSignal("CurrentMode"):Connect(onModeChanged)
onModeChanged()

----------------------------------------------------------------
-- End of script: JoinScreenClient v1.2.5
-- End of script: JoinScreenClient v1.2.6
----------------------------------------------------------------
