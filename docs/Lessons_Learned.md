# DeskMochi Lessons Learned

Date: 2026-05-29

This document records project-specific working knowledge that should steer future Codex work.

## What Worked

- Godot native transparent windows are good enough for the prototype path. `Window.transparent`, `Viewport.transparent_bg`, borderless/always-on-top, and `DisplayServer.window_set_mouse_passthrough(...)` let us avoid a Unity `UniWindowController` port for M1.
- The root scene owning plain state objects remains easy to reason about. The current Input -> Simulation -> Presentation -> Integration flow kept Godot Autoload singletons out of core behavior.
- Small deterministic scripts are valuable. `Validate.cmd` now catches Godot script load errors, settings regressions, productivity state regressions, helper build issues, and helper protocol issues.
- Runtime-facing smoke must focus on the actual product interaction. The old background-click validation surface confused the acceptance goal and was removed from the smoke flow.
- Do not clear the mouse input mask during visible mochi click or drag. On Windows/Godot transparent windows, full-window input during drag can expose an opaque black rectangle; keep full-window input reserved for the control panel.
- Do not launch interactive smoke while the user is playing a fullscreen game or running a GPU-sensitive app. Memory may be reasonable while the transparent always-on-top OpenGL window still destabilizes game focus/rendering.
- The helper service should prefer boring local protocols. Replacing `HttpListener` with a small loopback `TcpListener` avoided Windows HTTP.sys behavior and made `/health`, `/events`, and `/shutdown` easier to validate.
- Windows/.NET processes need graceful shutdown paths. The helper now has `/shutdown` and top-level exception handling to avoid .NET application error dialogs.

## What Hurt

- PowerShell and .NET default to user-global locations unless redirected. Restore/build scripts must set `DOTNET_CLI_HOME`, `APPDATA`, `LOCALAPPDATA`, and `NUGET_PACKAGES` into `.dotnet_runtime`.
- `Start-Process dotnet run ...` is less predictable than starting the built helper executable directly. Test scripts should run the exe after build.
- A manual smoke checklist alone is too easy to postpone. The project needs a Codex-started smoke harness where the user only observes visible product behavior and reports pass/fail.
- Some synced Google Doc text is mojibake in local Markdown. The roadmap meaning is already captured in checklists and progress docs, but future doc sync should preserve UTF-8 cleanly.

## Current Workflow Rules

- `Validate.cmd` remains the mechanical gate before claiming code progress.
- `ReleaseDryRun.cmd` reports packaging readiness, but real Windows export is blocked until Godot export templates are installed.
- For user-observed behavior, Codex should launch the smoke harness, not ask the user to manually assemble windows and commands.
- Use `docs/manual-smoke/results.md` as the acceptance log. Do not mark M1/M2/M3 runtime acceptance complete without manual observation evidence there.

## Next Improvements

- Keep manual smoke launch/stop scripts idempotent and PID-tracked.
- Add a short prompted observation checklist to the smoke harness output.
- When export templates are installed, add a package command that creates a real Windows artifact and includes the helper runtime plan.
