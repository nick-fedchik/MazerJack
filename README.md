# MazerJack

## Development

### Rojo sync checks (Rojo-safe)

- VS Code task: `Terminal → Run Task… → Rojo: Build (default.project.json)` (also the default Build Task).
- Optional pre-commit check (recommended):
	- Enable once: `git config core.hooksPath .githooks`
	- Result: commits are blocked if `rojo build default.project.json` fails.