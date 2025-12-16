# Architecture Audit (code v2.1 snapshot)

## Scope
- Reviewed: src/ServerScriptService/GameServer.luau, src/StarterPlayer/StarterPlayerScripts/GameClient.luau, src/ReplicatedStorage/Shared/{Constants.luau,Events.luau,Logger.luau}
- Goal: assess architecture shape, complexity, and consistency across server/client/shared scripts.

## Architecture Shape
- Server (GameServer.luau): event-driven flow; creates RemoteEvents (via Events.Init), sets player attributes CurrentMode/IsNewPlayer, mock profile store in-memory; guards mode on remotes; spawns at Path.SpawnLocation then sets mode to Station; GoToLocation/ReturnToStation only flip mode; Exit destroys character and resets to Join.
- Client (GameClient.luau): waits for Events folder, wires GUI buttons to remotes, toggles Join/Station/Location GUIs based on CurrentMode, populates Join screen with display name/avatar/status, listens to attribute changes to refresh GUI.
- Shared: Constants centralize mode/attribute/remote/path strings and game version; Events creates/looks up RemoteEvents; Logger is shared print/warn wrapper (v1.2.0 while code is labeled 2.1.x).

## Complexity Assessment
- Overall low: linear handlers, no FSM or service decomposition beyond a single server script; minimal branching and no background tasks beyond GUI listeners.
- State handling is simple attr flips without transition locks or context (no per-player state objects, no station/location services).
- GUI wiring relies on fuzzy name matching (multiple fallback names) instead of explicit UI contract but remains straightforward.

## Consistency Check
- Good: attribute/remote names shared through Constants; server and client use the same names and modes.
- Versioning: Constants/GameServer/GameClient marked 2.1.x but Logger remains 1.2.0 (mixed versions in logs), comments still refer to MVP/Mock.
- Data model: server mock profile only tracks isNew; client expects IsNewPlayer attr to render status. No other persistence contract defined, so client/server expectations align only on that one flag.
- Paths: spawn path hardcoded via Constants.Path; assumes Workspace/StellarStation/Modules/CommandModule/SpawnLocation exists and is a SpawnLocation instance.

## Gaps / Risks
- Persistence stub: in-memory profile resets each server; IsNewPlayer may be false within session then true next join; TODOs for DataStore not implemented.
- State integrity: no FSM/locks; remote spam could flip modes rapidly; GoToLocation/ReturnToStation do not move players or manage context, only set CurrentMode, so client UI can desync from actual position.
- Spawn safety: spawnPlayerAtStation sets RespawnLocation then LoadCharacter but does not check spawn part integrity or disabled respawn; no handling for location spawns.
- Remote trust: no rate limiting, payload validation, or caller checks; ExitGame destroys character server-side without notifying client.
- Events lifecycle: Events folder created only if GameServer runs; GameClient waits up to 10s then errors out—no retry/backoff or visibility into partial init.
- UI contract: LocationGui optional; buttons resolved by heuristic names; missing GUI elements silently skip wiring; no feedback to player on rejected remote calls.

## Recommendations
- Introduce a small state machine/service layer (Join/Station/Location) with guarded transitions, context per player, and explicit OnEnter/OnExit hooks (spawn, save, UI notify).
- Implement real persistence (DataStore or profile service) with schema/versioning; track isNew and other progression fields; add retry/backoff and logging.
- Harden remotes: validate mode before handling, add rate limits, and ensure payload schemas (even if empty) are checked; send structured client responses.
- Spawn/control flow: centralize spawn resolution and integrity checks; add location travel mechanics before flipping mode; keep player attributes in sync with actual position.
- Align shared modules: update Logger version or file paths to match 2.1.x; consider single Shared bootstrap to create Events once and expose accessors to avoid duplication.
- UI contracts: define required buttons/labels per GUI and assert their presence; add user-facing feedback on failure (e.g., mode mismatch) instead of silent warn-only logs.