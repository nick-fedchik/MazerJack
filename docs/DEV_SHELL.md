## Default Shell: Git Bash (Windows)

This workspace is configured to use Git Bash as the default integrated terminal on Windows.

- VS Code workspace setting: `.vscode/settings.json` sets `terminal.integrated.defaultProfile.windows` to `Git Bash`.
- Path used: `C:\Program Files\Git\bin\bash.exe` with args `--login -i` (adjust if Git is installed elsewhere).

If you'd like to use a different shell (WSL, PowerShell, or custom), update `.vscode/settings.json` accordingly or change the default from VS Code's terminal dropdown (Open terminal → Select Default Profile).

Ukrainian: Ця папка налаштована використовувати Git Bash як термінал за замовчуванням у Windows. Змініть профіль у `.vscode/settings.json`, якщо потрібно інший термінал.
