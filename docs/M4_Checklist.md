# M4 Checklist

Source: `docs/Godot_Development_Plan.md`

## Done / Started

- Idle and active resource measurement script exists at `tools/MeasureGodotResource.ps1`.
- A rough idle/active sample is recorded in `docs/manual-smoke/results.md`.
- Idle frame throttling exists in the Godot app.
- Performance mode V1 exists:
  - `eco`: 60 FPS active, 12 FPS idle.
  - `balanced`: 90 FPS active, 24 FPS idle.
  - `quality`: 120 FPS active, 30 FPS idle.
- Performance mode is available in the compact panel and persists in user settings.
- `.gitignore` excludes local Godot, .NET runtime, helper build, and log artifacts.
- Windows export preset exists in `export_presets.cfg`.
- Export readiness check exists at `tools/CheckExportReadiness.ps1`.
- `ReleaseDryRun.cmd` currently reports export templates are not installed on this machine.

## Remaining

- Run manual long-session profiling after M1/M2/M3 manual smoke.
- Install Godot 4.6.1 export templates on the machine before producing a real Windows package.
- Add a real package command after export templates are confirmed.
- Add startup/tray behavior decisions.
- Expand default visual states and animations beyond the prototype shape.

## M4 Exit Criteria

- Idle and focused resource usage is acceptable for always-on desktop use. Rough automated samples exist; longer manual profiling is still needed.
- Ordinary users can install, launch, configure, and exit the app. Editor-run prototype exists; packaged build is still needed.
- Release artifacts include necessary runtimes and resources. Not started.
