# UI Requirements

> Game Version: 2.1.0  
> Промпти для Roblox Studio Assistant

---

## JoinGameGui

**Розміщення:** StarterGui/JoinGameGui

**Промпт:**
```
Create a ScreenGui named "JoinGameGui" with:
- Frame "MainFrame" centered, size 400x500 pixels, dark semi-transparent background
- ImageLabel "AvatarImage" at top, 150x150, circular (UICorner)
- TextLabel "NicknameLabel" below avatar, white text, bold, size 24
- TextLabel "StatusLabel" below nickname, yellow text for new players, size 18
- TextButton "JoinButton" at bottom, green background, white text "ПРИЄДНАТИСЯ", size 200x50
- All elements should have UICorner for rounded corners
- Set Enabled = false (will be controlled by script)
```

**Елементи та їх призначення:**

| Елемент | Тип | Опис |
|---------|-----|------|
| `MainFrame` | Frame | Головний контейнер, центрований |
| `AvatarImage` | ImageLabel | Аватар гравця (заповнюється скриптом) |
| `NicknameLabel` | TextLabel | DisplayName гравця |
| `StatusLabel` | TextLabel | "Новий дослідник" або "Досвідчений мандрівник" |
| `JoinButton` | TextButton | Кнопка входу в гру → `JoinGame` RemoteEvent |

**Логіка (GameClient.client.luau):**
- Показується коли `CurrentMode == "Join"`
- `AvatarImage` заповнюється через `rbxthumb://type=AvatarHeadShot&id={UserId}&w=150&h=150`
- `NicknameLabel` = `player.DisplayName`
- `StatusLabel` залежить від атрибута `IsNewPlayer`

---

## StationGui

**Розміщення:** StarterGui/StationGui

**Промпт:**
```
Create a ScreenGui named "StationGui" with:
- Frame "TopBar" anchored to top, full width, height 60px, dark background
- TextLabel "LocationLabel" in TopBar showing "Космічна Станція"
- TextButton "ExitButton" in TopBar right corner, red background, text "ВИХІД", size 80x40
- Frame "BottomPanel" anchored to bottom center, contains action buttons
- TextButton "GoToLocationButton" in BottomPanel, blue background, text "НА ПЛАНЕТУ", size 200x50
- All elements should have UICorner for rounded corners
- Set Enabled = false (controlled by script)
```

**Елементи та їх призначення:**

| Елемент | Тип | Опис |
|---------|-----|------|
| `TopBar` | Frame | Верхня панель навігації |
| `LocationLabel` | TextLabel | Назва поточної локації |
| `ExitButton` | TextButton | Вихід з гри → `ExitGame` RemoteEvent |
| `BottomPanel` | Frame | Нижня панель з діями |
| `GoToLocationButton` | TextButton | Перехід на планету → `GoToLocation` RemoteEvent |

**Логіка (GameClient.client.luau):**
- Показується коли `CurrentMode == "Station"`
- Гравець фізично знаходиться на космічній станції
- Кнопка "НА ПЛАНЕТУ" переводить в режим Location

---

## LocationGui

**Розміщення:** StarterGui/LocationGui

**Промпт:**
```
Create a ScreenGui named "LocationGui" with:
- Frame "TopBar" anchored to top, full width, height 60px, dark background
- TextLabel "LocationName" in TopBar, white text, showing planet name
- TextButton "ReturnButton" in TopBar right corner, orange background, text "НА СТАНЦІЮ", size 120x40
- TextButton "ExitButton" next to ReturnButton, red background, text "ВИХІД", size 80x40
- All elements should have UICorner for rounded corners
- Set Enabled = false (controlled by script)
```

**Елементи та їх призначення:**

| Елемент | Тип | Опис |
|---------|-----|------|
| `TopBar` | Frame | Верхня панель навігації |
| `LocationName` | TextLabel | Назва планети/локації |
| `ReturnButton` | TextButton | Повернення на станцію → `ReturnToStation` RemoteEvent |
| `ExitButton` | TextButton | Вихід з гри → `ExitGame` RemoteEvent |

**Логіка (GameClient.client.luau):**
- Показується коли `CurrentMode == "Location"`
- Гравець фізично знаходиться на планетній локації
- Кнопка "НА СТАНЦІЮ" повертає в режим Station

---

## SpawnLocation

**Розміщення:** Workspace/StellarStation/Modules/CommandModule/SpawnLocation

**Промпт:**
```
In Workspace, create folder hierarchy: StellarStation > Modules > CommandModule
Inside CommandModule, add a SpawnLocation part named "SpawnLocation"
- Set Neutral = true
- Set AllowTeamChangeOnTouch = false  
- Set Duration = 0
- Position where players should spawn on the station deck
- Make it invisible or styled to match station floor
```

**Призначення:**
- Точка спавну гравців після натискання "ПРИЄДНАТИСЯ"
- Використовується в `GameServer.server.luau` функцією `findSpawnLocation()`
- Шлях визначений в `Constants.Path.SpawnLocation`

---

## Загальні рекомендації

### Стилізація
- Темний напівпрозорий фон для Frame (`BackgroundColor3 = Color3.fromRGB(20, 20, 30)`, `BackgroundTransparency = 0.3`)
- Білий текст для основних елементів
- Зелений для позитивних дій (Join)
- Помаранчевий для навігації (Return)
- Червоний для виходу (Exit)
- Синій для дослідження (GoToLocation)

### UICorner
- Радіус 8-12 пікселів для кнопок
- Радіус 50% для аватара (круглий)

### Enabled = false
- Всі ScreenGui мають бути `Enabled = false` за замовчуванням
- Видимість контролюється через `GameClient.client.luau`

---

## Зв'язок з кодом

| GUI | RemoteEvent | Режим гри |
|-----|-------------|-----------|
| JoinGameGui | — | `Join` (показується) |
| JoinGameGui.JoinButton | `JoinGame` | `Join` → `Station` |
| StationGui | — | `Station` (показується) |
| StationGui.GoToLocationButton | `GoToLocation` | `Station` → `Location` |
| StationGui.ExitButton | `ExitGame` | `Station` → `Join` |
| LocationGui | — | `Location` (показується) |
| LocationGui.ReturnButton | `ReturnToStation` | `Location` → `Station` |
| LocationGui.ExitButton | `ExitGame` | `Location` → `Join` |

---

## Файли коду

- **Клієнт:** [GameClient.client.luau](../src/StarterPlayer/StarterPlayerScripts/GameClient.client.luau)
- **Сервер:** [GameServer.server.luau](../src/ServerScriptService/GameServer.server.luau)
- **Константи:** [Constants.luau](../src/ReplicatedStorage/Shared/Constants.luau)
