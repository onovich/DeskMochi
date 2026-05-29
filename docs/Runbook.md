# DeskMochi Runbook

## Godot

Local Godot executable:

```powershell
D:\Godot\Godot_v4.6.1-stable_mono_win64\Godot_v4.6.1-stable_mono_win64.exe
```

Console executable:

```powershell
D:\Godot\Godot_v4.6.1-stable_mono_win64\Godot_v4.6.1-stable_mono_win64_console.exe
```

## Validate Project Load

```powershell
D:\Godot\Godot_v4.6.1-stable_mono_win64\Godot_v4.6.1-stable_mono_win64_console.exe --headless --path D:\LabProjects\DeskMochi --log-file D:/LabProjects/DeskMochi/.godot_runtime/logs/godot.log --quit
```

Or use the project workflow wrapper:

```powershell
C:\Users\Administrator\.codex\skills\project-ops-workflow\scripts\ops\Validate.cmd
```

The validation scripts point Godot's `APPDATA` and `LOCALAPPDATA` to `.godot_runtime/appdata` for the child process, so shader cache and `user://` data stay inside the local workspace during automated checks.

## Run Prototype

```powershell
D:\Godot\Godot_v4.6.1-stable_mono_win64\Godot_v4.6.1-stable_mono_win64_console.exe --path D:\LabProjects\DeskMochi --log-file D:/LabProjects/DeskMochi/.godot_runtime/logs/godot-window.log
```

The current prototype opens a small transparent, borderless, always-on-top window. Drag the visible mochi body to move the window. Transparent background space is not a product interaction surface.

Interaction notes:

- Short click: poke feedback.
- Press and hold or move on the visible mochi body: drag the desktop pet window immediately.
- Release after dragging: the next drag can start immediately; there is no cooldown.
- During click, poke, and drag, the background must remain transparent.
- `F2` or the small `...` button on mochi: open the compact control panel. While it is open, the whole DeskMochi window receives mouse input so panel controls are usable. Closing it restores the body-shaped input mask.

Development hotkeys:

- `Esc`: quit.
- `R`: reset the prototype window near the lower-right area of the current screen.
- `F1`: toggle the development debug overlay and passthrough polygon outline.
- `F2`: toggle the M2 control panel.
- `1` / `2` / `3`: switch handfeel preset: soft, balanced, snappy.
- `[` / `]`: decrease/increase body spring strength.
- `;` / `'`: decrease/increase body damping.

## Short Window Smoke

Use this when a quick non-interactive check is enough:

```powershell
D:\Godot\Godot_v4.6.1-stable_mono_win64\Godot_v4.6.1-stable_mono_win64_console.exe --path D:\LabProjects\DeskMochi --log-file D:/LabProjects/DeskMochi/.godot_runtime/logs/godot-window.log --quit-after 20
```

## Codex-Started Manual Smoke

Use this when behavior needs human eyes. Codex starts everything; the user only observes.

Do not start manual smoke while a fullscreen game, capture-sensitive app, or GPU-heavy workload is running. The prototype is a transparent always-on-top Godot/OpenGL window, and launching it can disturb exclusive fullscreen, overlays, or fragile game render devices.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\StartManualSmoke.ps1 -DemoEvents
```

By default, manual smoke only restores/builds the helper before launching the GUI, so it starts a single Godot window. Run the full preflight separately through `Validate.cmd`, or opt in explicitly:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\StartManualSmoke.ps1 -DemoEvents -FullPreflight
```

Or double-click:

```text
StartManualSmoke.cmd
```

Stop the session:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\StopManualSmoke.ps1
```

Or double-click:

```text
StopManualSmoke.cmd
```

Session state is written to `.codex/manual-smoke-session.json`.

## Run Demo Motion

Use this for repeatable active-mode profiling:

```powershell
D:\Godot\Godot_v4.6.1-stable_mono_win64\Godot_v4.6.1-stable_mono_win64_console.exe --path D:\LabProjects\DeskMochi --log-file D:/LabProjects/DeskMochi/.godot_runtime/logs/godot-demo.log -- --demo-motion
```

## Sample Running Process

With DeskMochi running:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\SampleGodotProcess.ps1
```

## User Settings

The prototype stores local preferences in Godot `user://deskmochi_settings.json`.
Automated validation redirects `user://` into `.godot_runtime/appdata`, so test settings stay inside the workspace.

Roundtrip check:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\CheckUserSettings.ps1
```

Productivity state check:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\CheckProductivityState.ps1
```

## M2 Control Panel

Open the panel with `F2` or the small `...` button on mochi.

- Pomodoro: Start/Pause/Reset. Running focus mode quiets mochi's pulse and interaction effects.
- Tasks: add a task, tick it complete, or delete it.
- Slots: use `...` to pick a local image file, or paste a path and press `Set`. Head and face slots are persisted in the settings JSON.
- Performance: click `Eco` / `Balanced` / `Quality` in the panel header to cycle FPS strategy.

## M3 Helper Service

Build and test the helper through the project validator:

```powershell
C:\Users\Administrator\.codex\skills\project-ops-workflow\scripts\ops\Validate.cmd
```

Run the helper manually:

```powershell
dotnet run --project helper\DeskMochi.Helper\DeskMochi.Helper.csproj -- --keyboard --git-repo D:\LabProjects\DeskMochi --token-log D:\path\to\agent.log
```

Or copy and edit the example config, then launch with:

```powershell
dotnet run --project helper\DeskMochi.Helper\DeskMochi.Helper.csproj -- --config helper\deskmochi-helper.config.example.json
```

Local endpoints:

- `http://127.0.0.1:8765/health`
- `http://127.0.0.1:8765/events?last_id=0`
- `http://127.0.0.1:8765/shutdown`

Godot polls the helper automatically. If the helper is not running, DeskMochi keeps working and retries quietly.

## Measure Idle And Active Resource Usage

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\MeasureGodotResource.ps1
```

## Export Readiness

Check Windows export prerequisites:

```powershell
C:\Users\Administrator\.codex\skills\project-ops-workflow\scripts\ops\ReleaseDryRun.cmd
```

This verifies the export preset and reports whether Godot export templates are installed.
