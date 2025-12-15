# MVP: Station Prototype

## Overview

Goal: deliver a small, playable vertical-slice focused on the Stellar Station (no planet flight yet). Players can join, spawn on the Station, move between modules, interact with automatic doors, and have persistent profile data (credits, knowledge tree, upgrades) saved at checkpoints.

## Station structure (Modules + Gateways)

This section is authoritative for how the Stellar Station is physically organized.

- **Modules**
  - A Module is a **hermetic** room/volume.
  - Geometry: **cube** or **parallelepiped**.
  - Some modules will later include **viewports/illuminators** that let the player see space and the nearby Planet.
  - There is normal gravity. A **Gravity Regulator** exists somewhere at the bottom of the station; it is **always working** and requires no gameplay resources.

- **Gateways (connectors / gates)**
  - Modules connect through Gateways.
  - A Gateway may have **2, 3, or 4 doors**.
  - Default Gateway: **2 doors facing each other**.
  - A Gateway is a **cube** whose walls comfortably fit its doors.
  - Door height: **20% taller than typical player height**.
  - Doors are either:
    - **Locked/disabled** for unbuilt modules or modules forbidden by game logic ("Gate is Locked" state), or
    - **Automatic** (open/close behavior).

- **Command Module (first / main module)**
  - The primary spawn for Station is in `CommandModule`.
  - A `SpawnLocation` is placed **on the floor in the center** of the Command Module.

- **Rojo workspace mapping (current repo convention)**
  - `Workspace/StellarStation/Modules/<ModuleName>`
  - `Workspace/StellarStation/Gateways/<GatewayName>`
  - `Workspace/StellarStation/Modules/CommandModule/SpawnLocation`

## Primary Goals (first release)

- Scalable, well-logged architecture with clear state tracking.
- Login / Splash screen and spawn flow into Command Module spawn location.
- Player movement and module navigation (doors auto open/close).
- Locked/unfinished modules (access denied for development ease).
- Checkpoint save (SpawnZone) storing player profile: credits, knowledge, station upgrades.
- Credits earned by selling loot / small reward for completing "study" on a location.
- Player knowledge tree (planetology) as individual progression.
- In-game debug UI to inspect player and game states (developer mode).

## Acceptance Criteria

- Player can log in, spawn, walk between connected modules, and exit.
- Doors animate open/close automatically; access denied modules block movement and log attempts.
- While in `Station` state, server tracks and exposes the player's current station context:
  - `CurrentStationModule` (string)
  - `CurrentStationGate` (string)
- Checkpoint saves and loads player profile with credits and knowledge tree.
- All gameplay-affecting services emit structured logs and have basic tests/mocks.
- Simple Stellar Station Control Panel UI exists with status indicators (gravity ok, engine offline, scanner idle).
- Login screen shows game title, version, player's nickname, avatar, and current level (or "Newbie").
- Player can exit from in-game menu with "Exit Game" both on Station and on Locations.
- Scanner behavior: has limited energy (2 scans at new game), recharges slowly from Solar Panels, can be charged quickly by resources gathered on planet; a successful scan adds a discovered Location to a Planet's known list.
- Only one active location is visible at a time (either Station or a Planet Location). Player can travel to a discovered Location without a shuttle (shuttle deferred), and the Station world is hidden while on a Location.
- Locations include a `LandingZone` (with `SpawnLocation`) and a Labyrinth. Rounds run a timed exploration; at the end of a round the labyrinth closes — players left inside die, lose loot and XP gained since last Check-In, and respawn at the Location's `SpawnLocation`.
- Check-In action updates the player's checkpoint (LastCheckpoint) and is persisted by `PersistenceService` (used to determine XP/loot protection).

Additional confirmations from design session:

- `Check-In` persists the player's profile (inventory, credits, `LastCheckpoint`) and protects XP/loot earned up to that point; any XP/loot earned after the last `Check-In` is at risk on round failure.
- When traveling to a Location for MVP we will hide/deactivate the Station world (not fully unload) and show the Location scene; upon return we restore the Station scene.
- Scanner initial battery: 2 scans available at new game start. There is a probability of discovery on each scan (high, but not 100%); for MVP one Location is pre-discovered and the Scanner starts at 50% charge.
- Upgrades for Scanner/Telescope require both Knowledge (Player experience / KnowledgeTree) and resources (credits/materials).
- `Exit Game` from in-game menu logs player out and on next login they respawn at `LastCheckpoint`.

## Key Systems & Mapping to Repo

- States:

  - `Menu` (existing), `Loading` (existing), `StationSpawn` (new), `StationExploration` (new), `Paused`
  - Update `src/ServerScriptService/StateMachine/*` and `src/ReplicatedStorage/Shared/Enums.luau`.

- Services:

  - `PlayerSpawnService` (extend) — spawn zones, respawn checkpoints.
  - `PlayerService` (extend) — player profile, attributes, experience.
  - `PersistenceService` (uses DataStore) — save/load player profiles & station state.
  - `DoorService` (existing) — keep for door mechanics; integrate with `StationService`.
  - `StationService` (new) — modules, spawn points, locked access, module metadata.
  - `EconomyService` (new, lightweight) — credits, sell/currency logic.

  - `Scanner` (entity) — battery/energy, radius, upgrades; exposed through Scanner Console.
  - `Telescope` (entity) — planet discovery UI in Telescope Module.
  - `SolarPanels` (module) — passive recharge for Scanner and station power indicators.
  - `ScienceModule` (module) — view player's Knowledge Tree and game knowledge base.
  - `LandingZone` + `RoundManager` (location systems) — spawn/check-in, labyrinth generation, round lifecycle and failure handling.

- Remotes / Events:

  - Add station-specific remotes to `ReplicatedStorage/Shared/GameEvents.luau` for control panel, scan requests, module access attempts, and save requests.

- UI / Client

  - `StarterGui/JoinGameGui` (Login), `StarterGui/StationGui` (control panel, HUD).
  - Add debug overlay toggled by dev key to show player state for QA.

  - `StarterGui/JoinGameGui` should show title/version, nickname/avatar selection, Current Level (or "Newbie"), and `Join Game` button.
  - Location context menu: `Exit Game`, `Check In`, `Start Round` (available on Locations only).

- Data Models
  - PlayerProfile: { PlayerId, Credits, KnowledgeTree, StationUpgrades, LastCheckpoint }

## Prototype Scope (vertical slice)

- Implement login → spawn → walk → open door → enter unlocked module → interact with simple terminal (increment minor knowledge or get credit reward) → save at checkpoint.
- Provide easy-to-use dev commands to force-save/force-load player profiles.
- Extend prototype scope to include quick travel from Station to a discovered Location (no shuttle), hiding the Station world while on Location, implementing `LandingZone` spawn, simple labyrinth generation, `Check In` / `Start Round` flows, round timer, and end-of-round consequences (death, loot/XP loss, respawn to Location spawn).

## Location structure (MVP)

- Planet Location NN (for MVP NN=01) is divided into zones:
  - `LandingZone`: contains a `SpawnLocation` used for check-in and respawn.
  - `ExplorationZone`: contains the Labyrinth and exploration gameplay for rounds. Zones do not overlap.

Only one Location is active and visible at a time for MVP (either Station or one Location scene).

## MVP Test Plan / Acceptance Flow

The following tests must pass for the Station Prototype MVP:

1. Login / Logout

- Player can open the `JoinGameGui`, enter nickname, join, and be spawned at the Station `SpawnLocation`.
- `Exit Game` logs the player out; on next login the player respawns at `LastCheckpoint`.

2. Station traversal & module tracking

- Player can walk between modules; server records module entry/exit events.
- Doors open/close automatically and unauthorized entry is prevented and logged.

3. Travel to Location & Check-In

- Player may travel to the known Location (MVP has 1 pre-discovered Location).
- On arrival, the player can `Check In` at the Location's `LandingZone` to persist `LastCheckpoint` (protects XP/loot up to that point).

4. Exploration & Round lifecycle

- Player can enter the `ExplorationZone` and start a Round via `Start Round`.
- Round runs a timer, after which the Labyrinth closes. If the Player is inside at round end they die, lose loot/Xp gained since last Check-In, and respawn to the Location's `SpawnLocation`.

5. Return flow

- Player can return to Station only from the `LandingZone` (not from inside the Labyrinth); upon return the Station scene is shown again.

6. Persistence & Save/Load

- `PersistenceService` can save/load PlayerProfile with `LastCheckpoint`, Credits and KnowledgeTree.

7. Dev/debug checks

- Developer debug overlay shows current `GameState` and player checkpoint for QA.

Notes: implement automated tests where practical and supplement with playtest checklist for the above flows.

## Non-Goals (initial)

- Planet flight and planetary scenes (deferred).
- Full UI polish and art assets (use placeholders).
- Monetization features.

## Testing & Quality

- Unit tests for `EconomyService`, `PersistenceService` load/save, and `StationService` access control.
- Playtest checklist for spawn flows, door behavior, and save/load validation.

## Next Steps

1. Confirm spec with you.
2. Produce sequence of PRs: (a) Enums & states, (b) `StationService` + doors integration, (c) Profile persistence, (d) UI + dev debug overlay, (e) Scanner/Telescope/SolarPanels modules and consoles, (f) Labyrinth & `RoundManager`, (g) Check-in / LandingZone & save integration, (h) tests & docs.
3. Implement prototype and run LSP/tests, then iterate with playtests.

---

If this matches your vision, I will start by creating/adding the `StationService` design and the required Enums/states changes and then implement a minimal prototype that adds a `StationSpawn` state and spawn flow.
