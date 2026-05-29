<!-- codex-project-ops-workflow: initialized -->
<!-- initialized-at: 2026-05-29 16:13:26 +08:00 -->

# Codex Ops Workflow

Initialization status: initialized
Project: DeskMochi
Repository root: D:\LabProjects\DeskMochi
Machine config: `.codex/project-ops-workflow.json`
Skill: project-ops-workflow

Treat this document and `.codex/project-ops-workflow.json` as the source of truth for mechanical project operations.

## Global Wrappers

```powershell
C:\Users\Administrator\.codex\skills\project-ops-workflow\scripts\ops\EnvCheck.cmd
C:\Users\Administrator\.codex\skills\project-ops-workflow\scripts\ops\RestoreDeps.cmd
C:\Users\Administrator\.codex\skills\project-ops-workflow\scripts\ops\InstallDeps.cmd
C:\Users\Administrator\.codex\skills\project-ops-workflow\scripts\ops\Build.cmd
C:\Users\Administrator\.codex\skills\project-ops-workflow\scripts\ops\Test.cmd
C:\Users\Administrator\.codex\skills\project-ops-workflow\scripts\ops\Lint.cmd
C:\Users\Administrator\.codex\skills\project-ops-workflow\scripts\ops\Format.cmd
C:\Users\Administrator\.codex\skills\project-ops-workflow\scripts\ops\Typecheck.cmd
C:\Users\Administrator\.codex\skills\project-ops-workflow\scripts\ops\StructureCheck.cmd
C:\Users\Administrator\.codex\skills\project-ops-workflow\scripts\ops\Codegen.cmd
C:\Users\Administrator\.codex\skills\project-ops-workflow\scripts\ops\DocsCheck.cmd
C:\Users\Administrator\.codex\skills\project-ops-workflow\scripts\ops\Validate.cmd
C:\Users\Administrator\.codex\skills\project-ops-workflow\scripts\ops\StartDevServer.cmd
C:\Users\Administrator\.codex\skills\project-ops-workflow\scripts\ops\StopDevServer.cmd
C:\Users\Administrator\.codex\skills\project-ops-workflow\scripts\ops\Smoke.cmd
C:\Users\Administrator\.codex\skills\project-ops-workflow\scripts\ops\Package.cmd
C:\Users\Administrator\.codex\skills\project-ops-workflow\scripts\ops\ReleaseDryRun.cmd
```

## Validate Sequence

Configured validation sequence:

1. `envCheck`: verify the local Godot console executable.
2. `build`: compile the DeskMochi helper service.
3. `typecheck`: load the Godot project headlessly and quit.
4. `test`: verify local user settings JSON roundtrip, productivity state behavior, helper behavior, and workflow script syntax.
5. `smoke`: start the real Windows display path briefly with `--quit-after 30`.

## Manual Smoke

Interactive smoke is started by Codex, not assembled manually by the user:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\StartManualSmoke.ps1 -DemoEvents
powershell -NoProfile -ExecutionPolicy Bypass -File tools\StopManualSmoke.ps1
```

The user only observes and reports whether the visible checklist passes. Results belong in `docs/manual-smoke/results.md`.

## Dev Server

Start command: ``
Health URL: ``
Ready text: ``
Timeout seconds: 30

## Safety Policy

Do not run destructive clean/reset/deploy commands unless the user explicitly asks.
