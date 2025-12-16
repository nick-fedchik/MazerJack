# Roadmap (versioned)

This roadmap uses semantic-ish versions:
- **Patch** ($x.y.Z$): small fixes, logging, minor refactors, tests, and safe automation.
- **Minor** ($x.Y.0$): a coherent playable increment (new service, new gameplay loop slice, new UI surface).
- **Major** ($X.0.0$): large milestone / release-candidate level changes.

Current shipped/dev baseline: **v1.2.2**

---

## v1.2.x — Station MVP hardening (short-term)

### v1.2.3
- Stabilize and document the current Station structure conventions:
	- `Workspace/StellarStation/Modules/<ModuleName>`
	- `Workspace/StellarStation/Gateways/<GatewayName>`
	- `CommandModule/SpawnLocation`
- Make `LocationsConfig` explicitly “unused for MVP” in docs and keep header/footer versions consistent.
- Ensure server boot logs the title/version once (source of truth: `GameConfig`).

### v1.2.4
- Gate model contract: each gateway model may have `GateLocked` boolean attribute.
- Log gate entry attempts consistently from server (locked/unlocked).
- Minimal door behavior integration point (no new UX): door logic reads `GateLocked` and denies movement/opens accordingly.

### v1.2.5
- Add a tiny Studio-only test runner and keep it green:
	- `GameStateMachine` contracts (transition sets `CurrentMode`, lock blocks re-entrant transitions).
	- `StationContextService` contracts (module/gate attributes, `GateLocked` defaults).
- Add a basic “playtest checklist” section to docs (spawn, join, gate logging, station context attrs).

### v1.2.6
- Rojo-safe automation:
	- VS Code build task is the default build task.
	- Optional pre-commit hook runs `rojo build` for relevant staged files.
- CI-ready note (even if CI isn’t configured yet): “what command to run to validate”.

**Exit criteria for v1.2.x**
- Join → Station spawn is reliable.
- Station context attributes work in Station mode:
	- `CurrentStationModule`
	- `CurrentStationGate`
- Gate entry logs include `GateLocked` state.
- Rojo build is stable and reproducible.

---

## v1.3.0 — Station navigation slice (still no planets)

Goal: more “station feel” without adding the planet/location loop yet.

- Introduce a minimal `StationService` (authoritative module/gate metadata):
	- module list + gateway list
	- locked/unlocked rules in one place
- Door integration uses `StationService` as the single source of truth.
- Add at least one more module besides `CommandModule` (e.g. `HallModule`) + one gateway connecting them.
- Expand tests:
	- `StationService` access rules
	- door lock decision logic (pure function / small mockable surface)

**Acceptance checklist (v1.3.0)**
- Player can move CommandModule → another module through a gateway.
- Locked gateways reliably deny access and log the attempt.
- Unlocked gateways allow passage and still log entry attempts.
- `StationService` is the single source of truth for module/gate metadata (no duplicated rules).
- `DoorService` behavior is consistent with `StationService` lock state.
- Server exposes correct station context attributes while in Station:
	- `CurrentStationModule`
	- `CurrentStationGate`
- At least one automated test covers access/lock decision logic.

---

## v1.4.0 — Station consoles: Scanner/Telescope placeholders

Goal: introduce the “systems panel” loop with minimal gameplay weight.

- Add basic “Control Panel” interaction points (server-authoritative, client UI minimal).
- Scanner:
	- battery/energy placeholder values
	- “scan request” event flow (rate limited)
- Telescope:
	- shows known planets/locations (still mostly static data)

**Acceptance checklist (v1.4.0)**
- Player can interact with a Station “Control Panel” surface without errors.
- Scanner “scan request” flow works end-to-end (client request → server validate → server response).
- Scan requests are rate limited (spam doesn’t flood logs/remotes).
- Scanner exposes a visible battery/energy value (even if placeholder).
- Telescope UI shows the current known planet/location list from config/data.
- All interactions produce structured logs (no silent failures).
- At least one automated test covers scan request validation/rate limiting.

---

## v1.5.0 — Persistence expansion (profile + checkpoint contracts)

Goal: persistence becomes meaningful beyond “exists”.

- Expand `PersistenceService` schema gradually (still Studio-safe):
	- credits
	- knowledge tree stub
	- last checkpoint contract (Station/Location)
- Add schema migration notes (documented expectations; migrations can still be manual for MVP).

**Acceptance checklist (v1.5.0)**
- Player profile loads with defaults when no prior data exists.
- Credits and knowledge stub persist across sessions (in production; Studio remains safe/no-crash).
- `LastCheckpoint` is saved/loaded and has a clear Station/Location contract.
- Schema version is tracked and documented; upgrading doesn’t brick existing saves.
- Save is triggered at an explicit checkpoint event (not every frame/heartbeat).
- Failures are logged with actionable context (userId, schemaVersion, operation).
- At least one automated test validates default state + schema version behavior.

---

## v1.6.0 — Locations MVP (first minimal planet/location loop)

Goal: one discoverable location loop, with Station world hidden while on location.

- Basic travel Station ↔ Location (no shuttle).
- Location structure:
	- `LandingZone` with `SpawnLocation`
	- `ExplorationZone` / labyrinth placeholder
- Minimal “Round” lifecycle (timer + failure consequence) as described in requirements.

**Acceptance checklist (v1.6.0)**
- Player can travel Station → Location and back using the intended MVP flow.
- Only one scene is visible/active at a time (Station hidden while on Location).
- Location has `LandingZone/SpawnLocation` and player spawns there on arrival.
- Player can perform `Check In` and it updates persisted `LastCheckpoint`.
- Round can start, runs a timer, and ends deterministically.
- If player is inside exploration at round end, the failure consequence triggers (death/respawn + loss since last check-in).
- At least one automated test validates the state transition + checkpoint contract.

---

## v1.7.0 — Economy + balancing pass

- Credits and reward sources become consistent.
- Scanner/Telescope upgrades consume resources/knowledge.
- Tuning and guardrails (anti-grind, basic caps).

**Acceptance checklist (v1.7.0)**
- Credits are earned from at least one defined gameplay source and logged.
- Credits spending/upgrades have server-side validation (no client-authoritative edits).
- Scanner/Telescope upgrades consume both resources/knowledge as designed.
- Economy values are sourced from config (not scattered magic numbers).
- Basic caps/limits exist to prevent runaway accumulation in MVP.
- Persistence correctly saves/loads economy-related fields.
- At least one automated test validates a core economy rule (earn/spend/cap).

---

## v2.0.0 — Release candidate goals (long-term)

- Stable save/load behavior in production.
- Clear, test-backed state machine contracts across Join/Station/Location.
- Minimal content pipeline: add modules/gates/locations without rewriting core code.

**Acceptance checklist (v2.0.0)**
- A new module/gateway can be added via Workspace structure + metadata with minimal/no code changes.
- State machine transitions across Join/Station/Location are covered by tests and stable under retry/race.
- Save/load works reliably in production environments; failures are observable and recoverable.
- Rojo build is reproducible and part of the standard verification flow.
- Core services follow consistent logging and error-handling conventions.
- A minimal playtest checklist exists and is kept up to date for each release.

---

## Notes / housekeeping

- Versions listed above are **candidates**; we can merge/split minors depending on scope.
- Each minor should have a short acceptance checklist (playable slice) and at least one basic automated test.
