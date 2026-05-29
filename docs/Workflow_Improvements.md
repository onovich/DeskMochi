# DeskMochi Workflow Improvements

## Validation Layers

Use three separate layers:

- `Validate.cmd`: deterministic checks that Codex can run headlessly.
- `StartManualSmoke.ps1`: Codex-started interactive smoke where the user only observes.
- `ReleaseDryRun.cmd`: packaging readiness and export prerequisites.

Manual smoke should test real product behavior only. Do not add background-click counters or validation surfaces; DeskMochi does not need background-click interaction.

Manual smoke must not be started while the user is gaming or running a fullscreen/GPU-sensitive app. The transparent always-on-top Godot window can disturb game render devices or focus state even when memory use is modest.

## Manual Smoke Ownership

Codex owns:

- Build/restore prerequisites.
- Starting the helper service.
- Starting DeskMochi.
- Avoiding interactive smoke starts during fullscreen/game sessions.
- Writing PID/log files under `.codex/`.
- Stopping helper and Godot processes when asked.

The user owns:

- Looking at the desktop.
- Trying the visible interaction steps if needed.
- Reporting whether the observed behavior matches the checklist.

## Process Tracking

Interactive smoke scripts should write a JSON state file:

```text
.codex/manual-smoke-session.json
```

The stop script should only stop PIDs recorded in that file and should use `/shutdown` for the helper before falling back to process termination.

## Review Habit

Before extending another milestone, quickly inspect:

- `docs/M*_Checklist.md`
- `docs/progress.md`
- `.codex/project-ops-workflow.json`
- `docs/manual-smoke/results.md`

This prevents drifting into new feature work while an acceptance gate is still missing.
