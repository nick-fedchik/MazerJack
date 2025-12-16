# Roadmap (versioned)

This roadmap uses semantic-ish versions:
- **Patch** ($x.y.Z$): small fixes, logging, minor refactors, tests, and safe automation.
- **Minor** ($x.Y.0$): a coherent playable increment (new service, new gameplay loop slice, new UI surface).
- **Major** ($X.0.0$): large milestone / release-candidate level changes.

Current shipped/dev baseline: **v2.1.0**

---

## v2.0.0 — Clean Architecture Rewrite (COMPLETED)

**BREAKING CHANGE**: Complete architecture rewrite from 28 files to 5 files.

### What was done:
- Archived old v1.x code to `archived/v1_code/`
- New minimal architecture:
  - `ReplicatedStorage/Shared/Constants.luau` — all game constants
  - `ReplicatedStorage/Shared/Events.luau` — RemoteEvent management
  - `ReplicatedStorage/Shared/Logger.luau` — logging (preserved from v1)
  - `ServerScriptService/GameServer.server.luau` — ALL server logic
  - `StarterPlayerScripts/GameClient.client.luau` — ALL client logic

### Architecture principles:
- Single source of truth: `Player.CurrentMode` attribute
- Server controls all state transitions
- Client only sends RemoteEvents and updates GUI visibility
- No complex FSM, Services, or Handlers — direct code

---

## v2.1.0 — Join Flow with Player Profile (CURRENT)

### Implemented:
- Player profile loading (New/Experienced detection)
- `Player.IsNewPlayer` attribute for GUI status display
- SpawnLocation discovery in `CommandModule`
- Profile display in JoinGameGui (nickname, avatar, status)
- Join → Station spawn flow

### Join Flow:
1. Player connects
2. Server loads profile (mock DataStore for MVP)
3. Server sets `IsNewPlayer` and `CurrentMode = "Join"`
4. Client shows JoinGameGui with player profile (name, avatar, status)
5. Player clicks "Join Game" button
6. Server finds SpawnLocation in CommandModule
7. Server spawns player and sets `CurrentMode = "Station"`
8. Client hides JoinGameGui, shows StationGui

### Files changed:
- `Constants.luau` — added `IsNewPlayer` attribute, `Path` constants
- `GameServer.server.luau` — profile loading, SpawnLocation discovery
- `GameClient.client.luau` — profile display, avatar loading

**Acceptance checklist (v2.1.0)**
- [x] Player connects and sees JoinGameGui
- [x] JoinGameGui shows player nickname (DisplayName)
- [x] JoinGameGui shows player avatar (from Roblox API)
- [x] JoinGameGui shows player status (New Player / Experienced)
- [x] Click "Join Game" spawns player on SpawnLocation
- [x] After spawn, StationGui is visible, JoinGameGui is hidden
- [ ] SpawnLocation exists in `Workspace/StellarStation/Modules/CommandModule`

---

## v2.2.0 — Station Structure (next)

Goal: Create basic Station structure in Workspace.

### Planned:
- CommandModule with SpawnLocation
- Basic Gateway placeholder
- Station environment (lighting, skybox)

**Acceptance checklist (v2.2.0)**
- [ ] `Workspace/StellarStation` structure exists
- [ ] `CommandModule` with proper geometry
- [ ] `SpawnLocation` in CommandModule center
- [ ] Player spawns inside CommandModule
- [ ] Basic lighting/atmosphere for space environment

---

## v2.3.0 — Exit Flow

Goal: Complete the game loop with Exit functionality.

### Planned:
- Exit button removes character
- Returns to Join mode
- Profile save on exit

**Acceptance checklist (v2.3.0)**
- [ ] Click "Exit Game" in StationGui
- [ ] Character is removed
- [ ] JoinGameGui becomes visible again
- [ ] Player can re-join without reload

---

## v2.4.0 — Persistence (DataStore)

Goal: Replace mock profile with real DataStore.

### Planned:
- DataStoreService integration
- Profile schema (isNew, credits, lastCheckpoint)
- Save/load with error handling

**Acceptance checklist (v2.4.0)**
- [ ] Profile persists between game sessions
- [ ] New player becomes Experienced after first join
- [ ] DataStore errors are logged and handled gracefully
- [ ] Schema version is tracked

---

## v2.5.0 — Station Navigation

Goal: Multiple modules with gateways.

### Planned:
- Additional modules (HallModule, etc.)
- Gateways connecting modules
- Door/gate interaction
- GateLocked attribute support

**Acceptance checklist (v2.5.0)**
- [ ] Multiple modules exist in Station
- [ ] Player can move between modules via gateways
- [ ] Locked gates deny access with log
- [ ] `CurrentStationModule` attribute updates on movement

---

## v3.0.0 — Location MVP (future)

Goal: First planet/location with travel.

- Station ↔ Location travel (no shuttle)
- LandingZone with SpawnLocation
- Basic exploration zone
- Round lifecycle

---

## Notes

- GUI (.rbxm files) are managed in Roblox Studio and exported
- Scripts (.luau files) are managed in VS Code via Rojo
- All changes should be tested with `rojo build` before commit
