# Architecture Audit (code v2.1.0)

> Last updated: December 2024

## Scope
- Reviewed: src/ServerScriptService/GameServer.luau, src/StarterPlayer/StarterPlayerScripts/GameClient.luau, src/ReplicatedStorage/Shared/{Constants.luau,Events.luau,Logger.luau}
- Goal: assess architecture shape, complexity, and consistency across server/client/shared scripts.

## Architecture Shape
- Server (GameServer.luau): event-driven flow; creates RemoteEvents (via Events.Init), sets player attributes CurrentMode/IsNewPlayer, DataStore persistence with retry logic; guards mode on remotes with transition cooldown (1s); spawns at Path.SpawnLocation then sets mode to Station; GoToLocation/ReturnToStation flip mode; Exit destroys character and resets to Join.
- Client (GameClient.luau): waits for Events folder, wires GUI buttons to remotes, toggles Join/Station/Location GUIs based on CurrentMode, populates Join screen with display name/avatar/status, listens to attribute changes to refresh GUI.
- Shared: Constants centralize mode/attribute/remote/path strings and game version (2.1.0); Events creates/looks up RemoteEvents; Logger is shared print/warn wrapper (2.1.0).

## Complexity Assessment
- Overall low: linear handlers, no FSM or service decomposition beyond a single server script; minimal branching and no background tasks beyond GUI listeners.
- State handling is simple attr flips with transition cooldown (1s) to prevent spam.
- GUI wiring relies on fuzzy name matching (multiple fallback names) instead of explicit UI contract but remains straightforward.

## Consistency Check
- Good: attribute/remote names shared through Constants; server and client use the same names and modes.
- Versioning: All modules (Constants, GameServer, GameClient, Logger) now at v2.1.0 — consistent.
- Data model: DataStore integration with retry logic (3 attempts); tracks isNew flag persistently (production) or in-memory (Studio).
- Paths: spawn path defined via Constants.Path; assumes Workspace/StellarStation/Modules/CommandModule/SpawnLocation exists.

## Implemented Features (v2.1.0)

### ✅ Fixed from previous audit:
- **DataStore persistence**: Real DataStore in production, mock in Studio
- **Transition cooldown**: 1 second between state transitions (anti-spam)
- **Logger version**: Updated to 2.1.0
- **Cache cleanup**: Player profiles cleaned from memory on leave

### Current safeguards:
- `canTransition(player)` — checks cooldown before any state change
- Mode validation — each handler verifies expected `CurrentMode`
- Retry logic — DataStore read/write with 3 attempts and backoff

## Remaining Gaps / Risks
- State integrity: GoToLocation/ReturnToStation do not move players or manage context, only set CurrentMode.
- Spawn safety: spawnPlayerAtStation sets RespawnLocation then LoadCharacter but does not check spawn part integrity.
- Remote trust: no payload validation beyond mode check; ExitGame destroys character server-side without client notification.
- UI contract: LocationGui optional; buttons resolved by heuristic names; missing GUI elements silently skip wiring.

## Recommendations (Priority Order)

1. **Location spawn mechanics** — implement actual teleportation for GoToLocation
2. **Spawn integrity check** — verify SpawnLocation exists before LoadCharacter
3. **Structured client responses** — send acknowledgment/error back to client on RemoteEvent
4. **UI contracts** — define required buttons/labels per GUI and assert presence