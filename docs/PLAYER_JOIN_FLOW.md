# Player Join Flow — Детальна специфікація

> Version: 2.1.0  
> Цей документ описує ТОЧНИЙ порядок дій при підключенні гравця до гри.

---

## Огляд State Machine

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   Player.CurrentMode = "Join"                               │
│   ├── Character: НЕ ІСНУЄ                                   │
│   ├── JoinGameGui: VISIBLE                                  │
│   └── StationGui: HIDDEN                                    │
│                                                             │
│                    │ Player clicks "ПРИЄДНАТИСЯ"            │
│                    │ Client fires JoinGame RemoteEvent      │
│                    ▼                                        │
│                                                             │
│   Player.CurrentMode = "Station"                            │
│   ├── Character: ІСНУЄ (spawned on SpawnLocation)           │
│   ├── JoinGameGui: HIDDEN                                   │
│   └── StationGui: VISIBLE                                   │
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

## ЧАСТИНА 6: Промпт для Roblox Studio Assistant

### Створення JoinGameGui

```
Create a ScreenGui in StarterGui named exactly "JoinGameGui" with these exact children:

1. Set JoinGameGui.Enabled = false
2. Add a Frame named "MainFrame":
   - Size: UDim2.new(0, 400, 0, 500)
   - Position: UDim2.new(0.5, -200, 0.5, -250)
   - BackgroundColor3: Color3.fromRGB(20, 20, 30)
   - BackgroundTransparency: 0.2

3. Inside MainFrame, add ImageLabel named "AvatarImage":
   - Size: UDim2.new(0, 150, 0, 150)
   - Position: UDim2.new(0.5, -75, 0, 30)
   - Image: "" (empty, will be set by script)
   - Add UICorner with CornerRadius = UDim.new(0.5, 0)

4. Inside MainFrame, add TextLabel named "NicknameLabel":
   - Size: UDim2.new(1, -40, 0, 40)
   - Position: UDim2.new(0, 20, 0, 200)
   - Text: "" (empty, will be set by script)
   - TextColor3: Color3.fromRGB(255, 255, 255)
   - TextSize: 24
   - Font: GothamBold

5. Inside MainFrame, add TextLabel named "StatusLabel":
   - Size: UDim2.new(1, -40, 0, 30)
   - Position: UDim2.new(0, 20, 0, 250)
   - Text: "" (empty, will be set by script)
   - TextColor3: Color3.fromRGB(255, 255, 0)
   - TextSize: 18
   - Font: Gotham

6. Inside MainFrame, add TextButton named "JoinButton":
   - Size: UDim2.new(0, 200, 0, 50)
   - Position: UDim2.new(0.5, -100, 1, -80)
   - Text: "ПРИЄДНАТИСЯ"
   - BackgroundColor3: Color3.fromRGB(0, 170, 0)
   - TextColor3: Color3.fromRGB(255, 255, 255)
   - TextSize: 20
   - Font: GothamBold
   - Add UICorner with CornerRadius = UDim.new(0, 8)

Do NOT add any scripts. The GameClient.luau script handles all logic.
```

### Створення StationGui

```
Create a ScreenGui in StarterGui named exactly "StationGui" with these exact children:

1. Set StationGui.Enabled = false
2. Add a Frame named "TopBar":
   - Size: UDim2.new(1, 0, 0, 60)
   - Position: UDim2.new(0, 0, 0, 0)
   - BackgroundColor3: Color3.fromRGB(20, 20, 30)
   - BackgroundTransparency: 0.3

3. Inside TopBar, add TextLabel named "LocationLabel":
   - Size: UDim2.new(0, 300, 1, 0)
   - Position: UDim2.new(0, 20, 0, 0)
   - Text: "Космічна Станція"
   - TextColor3: Color3.fromRGB(255, 255, 255)
   - TextSize: 22
   - TextXAlignment: Left
   - Font: GothamBold

4. Inside TopBar, add TextButton named "ExitButton":
   - Size: UDim2.new(0, 80, 0, 40)
   - Position: UDim2.new(1, -100, 0.5, -20)
   - Text: "ВИХІД"
   - BackgroundColor3: Color3.fromRGB(200, 50, 50)
   - TextColor3: Color3.fromRGB(255, 255, 255)
   - Add UICorner with CornerRadius = UDim.new(0, 8)

5. Add a Frame named "BottomPanel":
   - Size: UDim2.new(0, 300, 0, 80)
   - Position: UDim2.new(0.5, -150, 1, -100)
   - BackgroundColor3: Color3.fromRGB(20, 20, 30)
   - BackgroundTransparency: 0.3
   - Add UICorner with CornerRadius = UDim.new(0, 12)

6. Inside BottomPanel, add TextButton named "GoToLocationButton":
   - Size: UDim2.new(0, 200, 0, 50)
   - Position: UDim2.new(0.5, -100, 0.5, -25)
   - Text: "НА ПЛАНЕТУ"
   - BackgroundColor3: Color3.fromRGB(50, 100, 200)
   - TextColor3: Color3.fromRGB(255, 255, 255)
   - Add UICorner with CornerRadius = UDim.new(0, 8)

Do NOT add any scripts. The GameClient.luau script handles all logic.
```

---

## Файли коду

- **Сервер:** [GameServer.luau](../src/ServerScriptService/GameServer.luau)
- **Клієнт:** [GameClient.luau](../src/StarterPlayer/StarterPlayerScripts/GameClient.luau)
- **Константи:** [Constants.luau](../src/ReplicatedStorage/Shared/Constants.luau)
