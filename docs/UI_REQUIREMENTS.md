# UI Requirements

> Game Version: 2.1.0  
> Source: Roblox Studio Assistant

---

## Space Environment (Station Scene)
- Show an orbiting **star (sun analog)** visible from the station exterior; warm light source, distinct from default Roblox sky.
- Include a **planet (non-Earth)** in view near the station; unique color/atmosphere so it is clearly not Earth.
- Add **stellar cloud/nebula backdrop** (starfield with a cloudy band) to avoid empty black space.
- These visuals apply around the **Space Station** scene only; on **planetary locations** the surrounding sky/lighting can stay at the new-project defaults.

## JoinGameGui

**Location:** StarterGui/JoinGameGui

**Requirements:**
```
Create a ScreenGui named "JoinGameGui" with:
- Frame "MainFrame" centered, size 400x500 pixels, dark semi-transparent background
- ImageLabel "AvatarImage" at top, 150x150, circular (UICorner)
- TextLabel "NicknameLabel" below avatar, white text, bold, size 24
- TextLabel "StatusLabel" below nickname, yellow text for new players, size 18
- TextButton "JoinButton" at bottom, green background, white text "Join Game", size 200x50
- All elements should have UICorner for rounded corners
- Set Enabled = false (will be controlled by script)
```

**Expected hierarchy with types:**

| Element | Type | Notes |
|---------|-----|------|
| `MainFrame` | Frame | Main container with rounded corners |
| `AvatarImage` | ImageLabel | Player headshot (can use avatar thumbnail) |
| `NicknameLabel` | TextLabel | DisplayName |
| `StatusLabel` | TextLabel | "New Player" or "Experienced Player" |
| `JoinButton` | TextButton | Fires `JoinGame` RemoteEvent |

**Runtime (GameClient.luau):**
- Enabled when `CurrentMode == "Join"`
- `AvatarImage` uses `rbxthumb://type=AvatarHeadShot&id={UserId}&w=150&h=150`
- `NicknameLabel` = `player.DisplayName`
- `StatusLabel` toggles text based on `IsNewPlayer`

---

## StationGui

**Location:** StarterGui/StationGui

**Requirements:**
```
Create a ScreenGui named "StationGui" with:
- Frame "TopBar" anchored to top, full width, height 60px, dark background
- TextLabel "LocationLabel" in TopBar showing current area
- TextButton "ExitButton" in TopBar right corner, red background, text "Exit", size 80x40
- Frame "BottomPanel" anchored to bottom center, contains action buttons
- TextButton "GoToLocationButton" in BottomPanel, blue background, text "Go to Location", size 200x50
- All elements should have UICorner for rounded corners
- Set Enabled = false (controlled by script)
```

**Expected hierarchy with types:**

| Element | Type | Notes |
|---------|-----|------|
| `TopBar` | Frame | Header container |
| `LocationLabel` | TextLabel | Shows current station area |
| `ExitButton` | TextButton | Fires `ExitGame` RemoteEvent |
| `BottomPanel` | Frame | Container for action buttons |
| `GoToLocationButton` | TextButton | Fires `GoToLocation` RemoteEvent |

**Runtime (GameClient.luau):**
- Enabled when `CurrentMode == "Station"`
- Area name displayed from game state (Station)
- "Go to Location" triggers `GoToLocation`

---

## LocationGui

**Location:** StarterGui/LocationGui

**Requirements:**
```
Create a ScreenGui named "LocationGui" with:
- Frame "TopBar" anchored to top, full width, height 60px, dark background
- TextLabel "LocationName" in TopBar, white text, showing planet name
- TextButton "ReturnButton" in TopBar right corner, orange background, text "Return", size 120x40
- TextButton "ExitButton" next to ReturnButton, red background, text "Exit", size 80x40
- All elements should have UICorner for rounded corners
- Set Enabled = false (controlled by script)
```

**Expected hierarchy with types:**

| Element | Type | Notes |
|---------|-----|------|
| `TopBar` | Frame | Header container |
| `LocationName` | TextLabel | Planet/location name |
| `ReturnButton` | TextButton | Fires `ReturnToStation` RemoteEvent |
| `ExitButton` | TextButton | Fires `ExitGame` RemoteEvent |

**Runtime (GameClient.luau):**
- Enabled when `CurrentMode == "Location"`
- Name shows active location
- "Return" triggers `ReturnToStation`

---

## SpawnLocation

**Location:** Workspace/StellarStation/Modules/CommandModule/SpawnLocation

**Requirements:**
```
In Workspace, create folder hierarchy: StellarStation > Modules > CommandModule
Inside CommandModule, add a SpawnLocation part named "SpawnLocation"
- Set Neutral = true
- Set AllowTeamChangeOnTouch = false  
- Set Duration = 0
- Position where players should spawn on the station deck
- Make it invisible or styled to match station floor
```

**Notes:**
- Used as the spawn point for players when they click "Join Game"
- Referenced by `GameServer.luau` via `findSpawnLocation()`
- Path constant: `Constants.Path.SpawnLocation`

---

## Visual / Styling Defaults

### Colors
- Dark, cool-toned backgrounds for frames (`BackgroundColor3 = Color3.fromRGB(20, 20, 30)`, `BackgroundTransparency = 0.3`)
- Accent colors by action: green (Join), blue (GoToLocation), orange (Return), red (Exit)
- White/yellow text for contrast

### UICorner
- Radius 8-12 pixels for frames/buttons
- 50% radius for circular avatar image

### Enabled = false
- Each ScreenGui starts with `Enabled = false` to allow script control
- Scripts (GameClient.luau) toggle visibility based on `CurrentMode`

---

## GUI to RemoteEvent Mapping

| GUI | RemoteEvent | Flow |
|-----|-------------|-----------|
| JoinGameGui | — | `Join` state visible |
| JoinGameGui.JoinButton | `JoinGame` | `Join` -> `Station` |
| StationGui | — | `Station` state visible |
| StationGui.GoToLocationButton | `GoToLocation` | `Station` -> `Location` |
| StationGui.ExitButton | `ExitGame` | `Station` -> `Join` |
| LocationGui | — | `Location` state visible |
| LocationGui.ReturnButton | `ReturnToStation` | `Location` -> `Station` |
| LocationGui.ExitButton | `ExitGame` | `Location` -> `Join` |

---

## References

- **Client:** [GameClient.luau](../src/StarterPlayer/StarterPlayerScripts/GameClient.client.luau)
- **Server:** [GameServer.luau](../src/ServerScriptService/GameServer.server.luau)
- **Constants:** [Constants.luau](../src/ReplicatedStorage/Shared/Constants.luau)