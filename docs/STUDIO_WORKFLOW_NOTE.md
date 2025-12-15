# Studio workflow note (no Rojo)

This repo contains some Rojo-style metadata files (e.g. `init.meta.json`). If you are not using Rojo, Roblox Studio will ignore these files.

For Studio-only workflows, UI defaults are enforced at runtime:
- Join screen is shown when `CurrentMode == nil` or `"Join"`.
- Station screen is shown when `CurrentMode == "Station"`.

If you edit UI directly in Studio, ensure these ScreenGuis exist under `StarterGui`:
- `StarterGui/JoinGameGui`
- `StarterGui/StationGui`

And if you want the scripts to bind to your custom UI, keep (or rename in code) these elements:
- Join: `PlayerName`, `PlayerStatus`, `GameStatus`, `JoinGameButton`
- Station: `Title`, `Subtitle`, `GoLocationButton`, `ExitGameButton`
