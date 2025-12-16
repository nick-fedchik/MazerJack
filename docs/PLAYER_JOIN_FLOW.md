# Player Join Flow — Детальна специфікація

> Version: 2.1.0  
> Цей документ описує ТОЧНИЙ порядок дій при підключенні гравця до гри.

---

## Сценарій підключення гравця

### Крок 1: Підключення (Connect)
- Гравець підключився до сервера Roblox
- **Персонаж НЕ створюється** — гравець ще не грає
- Гравець бачить чорний екран

### Крок 2: Ідентифікація гравця
- Сервер отримує інформацію про гравця:
  - `player.UserId` — унікальний ID
  - `player.DisplayName` — нікнейм
  - Аватар через `rbxthumb://`

### Крок 3: Визначення статусу
- Сервер перевіряє DataStore: чи грав цей гравець раніше?
- Встановлює атрибут `IsNewPlayer`:
  - `true` — новий гравець (перший раз)
  - `false` — досвідчений (грав раніше)

### Крок 4: Показ заставки
- Активується `JoinGameGui`:
  - Чорний/темний фон на весь екран
  - Аватар гравця
  - Нікнейм гравця
  - Статус: "Новий дослідник" або "Досвідчений мандрівник"
  - Кнопка "ПРИЄДНАТИСЯ"

### Крок 5: Очікування
- **Нічого не відбувається**
- Сервер і клієнт чекають поки гравець натисне кнопку

### Крок 6: Гравець натиснув "ПРИЄДНАТИСЯ"
- Клієнт відправляє `JoinGame` RemoteEvent на сервер

### Крок 7: Активація гри
1. Сервер отримує RemoteEvent
2. Сервер ховає `JoinGameGui` (через зміну атрибута `CurrentMode`)
3. Сервер робить spawn персонажа на `StellarStation/Modules/CommandModule/SpawnLocation`
4. Гравець з'являється на космічній станції
5. Показується `StationGui`

---

## Стани гравця (State Machine)

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   CurrentMode = "Join"                                      │
│   ├── Персонаж: НЕ ІСНУЄ                                    │
│   ├── JoinGameGui: ПОКАЗАНО                                 │
│   ├── StationGui: СХОВАНО                                   │
│   └── Гравець: дивиться на заставку, чекає                  │
│                                                             │
│                    │                                        │
│                    │ Клік на "ПРИЄДНАТИСЯ"                  │
│                    │ → JoinGame RemoteEvent                 │
│                    ▼                                        │
│                                                             │
│   CurrentMode = "Station"                                   │
│   ├── Персонаж: СТВОРЕНО (spawn на станції)                 │
│   ├── JoinGameGui: СХОВАНО                                  │
│   ├── StationGui: ПОКАЗАНО                                  │
│   └── Гравець: грає на космічній станції                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## ЧАСТИНА 1: Server — GameServer.luau

### 1.1 Подія: Players.PlayerAdded

**Коли:** Гравець підключився до сервера (ще до появи персонажа).

**Кроки:**

```
1. Отримати player з події
2. Завантажити профіль:
   - Перевірити DataStore (якщо production)
   - Якщо профіль не знайдено → створити новий { isNew = true }
   - Зберегти в кеш playerProfiles[userId]
3. Встановити атрибути на Player:
   - player:SetAttribute("IsNewPlayer", profile.isNew)
   - player:SetAttribute("CurrentMode", "Join")
4. НЕ СТВОРЮВАТИ персонажа! Гравець залишається без Character.
```

**Результат:**
- `player:GetAttribute("CurrentMode")` == `"Join"`
- `player:GetAttribute("IsNewPlayer")` == `true` або `false`
- `player.Character` == `nil`

---

### 1.2 Подія: JoinGame RemoteEvent (від клієнта)

**Коли:** Гравець натиснув кнопку "ПРИЄДНАТИСЯ" в JoinGameGui.

**Перевірки (Guards):**

```
1. Перевірити cooldown:
   - Якщо минуло менше 1 секунди з останнього переходу → ВІДХИЛИТИ
   
2. Перевірити поточний режим:
   - Якщо player:GetAttribute("CurrentMode") != "Join" → ВІДХИЛИТИ
   - Логувати: "Player tried to join but is in mode: X"
```

**Дії (якщо перевірки пройдені):**

```
1. Знайти SpawnLocation:
   - Шлях: Workspace/StellarStation/Modules/CommandModule/SpawnLocation
   - Якщо не знайдено → використати default spawn

2. Встановити RespawnLocation:
   - player.RespawnLocation = spawnLocation

3. Завантажити персонажа:
   - player:LoadCharacter()
   - Персонаж з'явиться на SpawnLocation

4. Змінити режим:
   - player:SetAttribute("CurrentMode", "Station")

5. Оновити профіль:
   - player:SetAttribute("IsNewPlayer", false)
   - Зберегти в DataStore (async)
```

**Результат:**
- `player:GetAttribute("CurrentMode")` == `"Station"`
- `player:GetAttribute("IsNewPlayer")` == `false`
- `player.Character` != `nil` (персонаж існує)

---

## ЧАСТИНА 2: Client — GameClient.luau

### 2.1 Ініціалізація клієнта

**Коли:** LocalScript запускається.

**Кроки:**

```
1. Отримати посилання:
   - player = Players.LocalPlayer
   - playerGui = player:WaitForChild("PlayerGui")

2. Знайти GUI елементи:
   - joinGui = playerGui:WaitForChild("JoinGameGui", 10)
   - stationGui = playerGui:WaitForChild("StationGui", 10)

3. Дочекатися Events:
   - eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
   - joinEvent = eventsFolder:WaitForChild("JoinGame")

4. Підключити listener на зміну атрибута:
   - player:GetAttributeChangedSignal("CurrentMode"):Connect(updateGuiVisibility)

5. Викликати updateGuiVisibility() для початкового стану
```

---

### 2.2 Функція: updateGuiVisibility()

**Призначення:** Показує/ховає GUI залежно від CurrentMode.

**Логіка:**

```lua
local function updateGuiVisibility()
    local mode = player:GetAttribute("CurrentMode")
    
    if joinGui then
        joinGui.Enabled = (mode == "Join")
    end
    
    if stationGui then
        stationGui.Enabled = (mode == "Station")
    end
    
    if locationGui then
        locationGui.Enabled = (mode == "Location")
    end
end
```

**Правило:** Тільки ОДИН GUI видимий в кожен момент часу.

---

### 2.3 Функція: setupJoinGui()

**Призначення:** Налаштовує JoinGameGui.

**Кроки:**

```lua
local function setupJoinGui()
    if not joinGui then return end
    
    -- 1. Знайти елементи
    local avatarImage = joinGui:FindFirstChild("AvatarImage", true)
    local nicknameLabel = joinGui:FindFirstChild("NicknameLabel", true)
    local statusLabel = joinGui:FindFirstChild("StatusLabel", true)
    local joinButton = joinGui:FindFirstChild("JoinButton", true)
    
    -- 2. Заповнити профіль гравця
    if avatarImage then
        avatarImage.Image = string.format(
            "rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150",
            player.UserId
        )
    end
    
    if nicknameLabel then
        nicknameLabel.Text = player.DisplayName
    end
    
    if statusLabel then
        local isNew = player:GetAttribute("IsNewPlayer")
        if isNew then
            statusLabel.Text = "Новий дослідник"
            statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Yellow
        else
            statusLabel.Text = "Досвідчений мандрівник"
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green
        end
    end
    
    -- 3. Підключити кнопку
    if joinButton then
        joinButton.MouseButton1Click:Connect(function()
            joinEvent:FireServer()
        end)
    end
end
```

---

### 2.4 Оновлення StatusLabel при зміні IsNewPlayer

**Призначення:** Якщо атрибут IsNewPlayer змінився, оновити текст.

```lua
player:GetAttributeChangedSignal("IsNewPlayer"):Connect(function()
    local statusLabel = joinGui:FindFirstChild("StatusLabel", true)
    if statusLabel then
        local isNew = player:GetAttribute("IsNewPlayer")
        statusLabel.Text = isNew and "Новий дослідник" or "Досвідчений мандрівник"
    end
end)
```

---

## ЧАСТИНА 3: GUI Structure — Точні імена

### JoinGameGui (StarterGui)

```
JoinGameGui (ScreenGui)
├── Enabled = false
└── MainFrame (Frame)
    ├── AvatarImage (ImageLabel)
    │   └── Image = "" (заповнюється скриптом)
    ├── NicknameLabel (TextLabel)
    │   └── Text = "" (заповнюється скриптом)
    ├── StatusLabel (TextLabel)
    │   └── Text = "" (заповнюється скриптом)
    └── JoinButton (TextButton)
        └── Text = "ПРИЄДНАТИСЯ"
```

### StationGui (StarterGui)

```
StationGui (ScreenGui)
├── Enabled = false
└── TopBar (Frame)
    ├── LocationLabel (TextLabel)
    │   └── Text = "Космічна Станція"
    ├── ExitButton (TextButton)
    │   └── Text = "ВИХІД"
    └── GoToLocationButton (TextButton)
        └── Text = "НА ПЛАНЕТУ"
```

---

## ЧАСТИНА 4: Правила перевірок (Guards)

### Сервер: Перед обробкою RemoteEvent

| Перевірка | Умова відхилення | Дія |
|-----------|------------------|-----|
| Cooldown | `tick() - lastTransition < 1.0` | Return, log warning |
| Wrong Mode | `CurrentMode != expected` | Return, log warning |
| No Player | `player == nil` | Return |

### Клієнт: Перед відправкою RemoteEvent

| Перевірка | Умова відхилення | Дія |
|-----------|------------------|-----|
| No Event | `joinEvent == nil` | Return, log error |
| GUI not ready | `joinButton == nil` | Skip button setup |

---

## ЧАСТИНА 5: Послідовність подій (Timeline)

```
TIME    SERVER                          CLIENT
─────────────────────────────────────────────────────────────
t=0     PlayerAdded fires               —
        → SetAttribute("CurrentMode", "Join")
        → SetAttribute("IsNewPlayer", true)
        
t=0.1   —                               LocalScript starts
                                        → WaitForChild("JoinGameGui")
                                        → setupJoinGui()
                                        → updateGuiVisibility()
                                        → JoinGameGui.Enabled = true
                                        
t=5     —                               Player clicks "ПРИЄДНАТИСЯ"
                                        → joinEvent:FireServer()
                                        
t=5.01  JoinGame.OnServerEvent fires    —
        → canTransition() check
        → getPlayerMode() == "Join" ✓
        → findSpawnLocation()
        → player:LoadCharacter()
        → SetAttribute("CurrentMode", "Station")
        
t=5.02  —                               AttributeChanged fires
                                        → updateGuiVisibility()
                                        → JoinGameGui.Enabled = false
                                        → StationGui.Enabled = true
                                        
t=5.1   Character spawns on station     Character appears in game
```

---

## ІНСТРУКЦІЯ ДЛЯ ROBLOX STUDIO ASSISTANT

### ⚠️ ВАЖЛИВО: Правила для Assistant

1. **НЕ СТВОРЮВАТИ СКРИПТИ** — вся логіка вже є в `GameClient.luau`
2. **ТОЧНІ ІМЕНА** — імена елементів мають бути ТОЧНО як вказано
3. **Enabled = false** — GUI мають бути вимкнені за замовчуванням
4. **Ієрархія важлива** — елементи мають бути вкладені правильно

---

### ПРОМПТ 1: Створити JoinGameGui

Скопіюй цей текст в Roblox Studio Assistant:

```
Create a ScreenGui in StarterGui. Follow these EXACT specifications:

NAME: "JoinGameGui"
PROPERTIES:
- Enabled = false
- ResetOnSpawn = false
- IgnoreGuiInset = true
- ZIndexBehavior = Enum.ZIndexBehavior.Sibling

HIERARCHY:
JoinGameGui (ScreenGui)
└── Background (Frame)
    ├── AvatarImage (ImageLabel)
    ├── NicknameLabel (TextLabel)
    ├── StatusLabel (TextLabel)
    └── JoinButton (TextButton)

ELEMENT: Background (Frame)
- Name: "Background"
- Size: UDim2.new(1, 0, 1, 0) -- full screen
- Position: UDim2.new(0, 0, 0, 0)
- BackgroundColor3: Color3.fromRGB(10, 10, 20) -- dark blue/black
- BackgroundTransparency: 0
- BorderSizePixel: 0

ELEMENT: AvatarImage (ImageLabel) - child of Background
- Name: "AvatarImage"
- Size: UDim2.new(0, 150, 0, 150)
- Position: UDim2.new(0.5, -75, 0.3, -75)
- AnchorPoint: Vector2.new(0, 0)
- BackgroundTransparency: 1
- Image: "" (empty string, script will fill)
- Add UICorner child with CornerRadius = UDim.new(1, 0) for circle

ELEMENT: NicknameLabel (TextLabel) - child of Background
- Name: "NicknameLabel"
- Size: UDim2.new(0, 400, 0, 50)
- Position: UDim2.new(0.5, -200, 0.3, 100)
- BackgroundTransparency: 1
- Text: "" (empty, script will fill)
- TextColor3: Color3.fromRGB(255, 255, 255)
- TextSize: 28
- Font: Enum.Font.GothamBold
- TextXAlignment: Enum.TextXAlignment.Center

ELEMENT: StatusLabel (TextLabel) - child of Background
- Name: "StatusLabel"
- Size: UDim2.new(0, 400, 0, 30)
- Position: UDim2.new(0.5, -200, 0.3, 160)
- BackgroundTransparency: 1
- Text: "" (empty, script will fill)
- TextColor3: Color3.fromRGB(255, 255, 0) -- yellow
- TextSize: 20
- Font: Enum.Font.Gotham
- TextXAlignment: Enum.TextXAlignment.Center

ELEMENT: JoinButton (TextButton) - child of Background
- Name: "JoinButton"
- Size: UDim2.new(0, 250, 0, 60)
- Position: UDim2.new(0.5, -125, 0.7, 0)
- BackgroundColor3: Color3.fromRGB(0, 180, 0) -- green
- Text: "ПРИЄДНАТИСЯ"
- TextColor3: Color3.fromRGB(255, 255, 255)
- TextSize: 24
- Font: Enum.Font.GothamBold
- Add UICorner child with CornerRadius = UDim.new(0, 12)
- Add UIStroke child with Color = Color3.fromRGB(255,255,255), Thickness = 2

DO NOT ADD ANY SCRIPTS. The existing GameClient.luau handles all button logic.
```

---

### ПРОМПТ 2: Створити StationGui

Скопіюй цей текст в Roblox Studio Assistant:

```
Create a ScreenGui in StarterGui. Follow these EXACT specifications:

NAME: "StationGui"
PROPERTIES:
- Enabled = false
- ResetOnSpawn = false
- ZIndexBehavior = Enum.ZIndexBehavior.Sibling

HIERARCHY:
StationGui (ScreenGui)
├── TopBar (Frame)
│   ├── LocationLabel (TextLabel)
│   └── ExitButton (TextButton)
└── BottomPanel (Frame)
    └── GoToLocationButton (TextButton)

ELEMENT: TopBar (Frame)
- Name: "TopBar"
- Size: UDim2.new(1, 0, 0, 60)
- Position: UDim2.new(0, 0, 0, 0)
- BackgroundColor3: Color3.fromRGB(20, 20, 35)
- BackgroundTransparency: 0.2
- BorderSizePixel: 0

ELEMENT: LocationLabel (TextLabel) - child of TopBar
- Name: "LocationLabel"
- Size: UDim2.new(0, 300, 1, 0)
- Position: UDim2.new(0, 20, 0, 0)
- BackgroundTransparency: 1
- Text: "Космічна Станція"
- TextColor3: Color3.fromRGB(255, 255, 255)
- TextSize: 24
- Font: Enum.Font.GothamBold
- TextXAlignment: Enum.TextXAlignment.Left
- TextYAlignment: Enum.TextYAlignment.Center

ELEMENT: ExitButton (TextButton) - child of TopBar
- Name: "ExitButton"
- Size: UDim2.new(0, 100, 0, 40)
- Position: UDim2.new(1, -120, 0.5, -20)
- BackgroundColor3: Color3.fromRGB(200, 50, 50) -- red
- Text: "ВИХІД"
- TextColor3: Color3.fromRGB(255, 255, 255)
- TextSize: 18
- Font: Enum.Font.GothamBold
- Add UICorner child with CornerRadius = UDim.new(0, 8)

ELEMENT: BottomPanel (Frame)
- Name: "BottomPanel"
- Size: UDim2.new(0, 300, 0, 80)
- Position: UDim2.new(0.5, -150, 1, -100)
- BackgroundColor3: Color3.fromRGB(20, 20, 35)
- BackgroundTransparency: 0.2
- Add UICorner child with CornerRadius = UDim.new(0, 12)

ELEMENT: GoToLocationButton (TextButton) - child of BottomPanel
- Name: "GoToLocationButton"
- Size: UDim2.new(0, 220, 0, 50)
- Position: UDim2.new(0.5, -110, 0.5, -25)
- BackgroundColor3: Color3.fromRGB(50, 120, 200) -- blue
- Text: "НА ПЛАНЕТУ"
- TextColor3: Color3.fromRGB(255, 255, 255)
- TextSize: 20
- Font: Enum.Font.GothamBold
- Add UICorner child with CornerRadius = UDim.new(0, 8)

DO NOT ADD ANY SCRIPTS. The existing GameClient.luau handles all button logic.
```

---

### ПРОМПТ 3: Створити SpawnLocation

Скопіюй цей текст в Roblox Studio Assistant:

```
Create a SpawnLocation for player spawning. Follow these EXACT specifications:

LOCATION: Create folder hierarchy in Workspace:
Workspace
└── StellarStation (Folder)
    └── Modules (Folder)
        └── CommandModule (Folder or Model)
            └── SpawnLocation (SpawnLocation part)

ELEMENT: SpawnLocation
- ClassName: SpawnLocation (not Part!)
- Name: "SpawnLocation"
- Size: Vector3.new(6, 1, 6)
- Position: Place it on the floor of CommandModule where players should appear
- Anchored: true
- CanCollide: false
- Transparency: 1 (invisible)
- Neutral: true
- AllowTeamChangeOnTouch: false
- Duration: 0

The SpawnLocation should be invisible but positioned where the player character will stand when joining the game.

If StellarStation or CommandModule already exist as Models, add SpawnLocation inside the existing CommandModule.
```

---

### ПЕРЕВІРКА ПІСЛЯ СТВОРЕННЯ

Після виконання промптів перевір в Explorer:

```
StarterGui
├── JoinGameGui (ScreenGui) ← Enabled = false
│   └── Background (Frame)
│       ├── AvatarImage (ImageLabel)
│       ├── NicknameLabel (TextLabel)
│       ├── StatusLabel (TextLabel)
│       └── JoinButton (TextButton)
│
└── StationGui (ScreenGui) ← Enabled = false
    ├── TopBar (Frame)
    │   ├── LocationLabel (TextLabel)
    │   └── ExitButton (TextButton)
    └── BottomPanel (Frame)
        └── GoToLocationButton (TextButton)

Workspace
└── StellarStation
    └── Modules
        └── CommandModule
            └── SpawnLocation (SpawnLocation)
```

---

## Файли коду

- **Сервер:** [GameServer.luau](../src/ServerScriptService/GameServer.luau)
- **Клієнт:** [GameClient.luau](../src/StarterPlayer/StarterPlayerScripts/GameClient.luau)
- **Константи:** [Constants.luau](../src/ReplicatedStorage/Shared/Constants.luau)
