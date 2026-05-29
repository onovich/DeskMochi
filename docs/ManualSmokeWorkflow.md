# DeskMochi Manual Smoke Workflow

Manual smoke is now a Codex-started process. The user should not need to assemble commands or windows by hand.

## Start

Codex runs:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\StartManualSmoke.ps1 -DemoEvents
```

The user can also double-click:

```text
StartManualSmoke.cmd
```

The script restores/builds the helper, starts the helper, and launches DeskMochi. Full Godot preflight is intentionally not part of the default manual smoke start because it launches extra Godot processes; use `Validate.cmd` before smoke, or pass `-FullPreflight` when needed.

Do not start manual smoke while the user is in a fullscreen game, capture-sensitive app, or GPU-heavy workload.

## Observe

The user only needs to look at the desktop and report whether these are true:

- DeskMochi appears as a transparent, always-on-top desktop pet.
- The visible mochi body is always clickable and draggable, with no cooldown after release.
- The transparent background stays transparent during click, poke, and drag.
- The smoke flow does not validate background clicks. The primary acceptance target is visible mochi interaction.
- The mochi body receives poke and drag interactions.
- `F2` and the small in-body `...` button open the control panel.
- Pomodoro is shortened to 15 seconds in smoke mode; ToDo, Head/Face image slots, and performance mode are usable.
- With `-DemoEvents`, text cues plus blue, purple, then green helper feedback appear within about 15 seconds.

## Stop

Codex runs:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\StopManualSmoke.ps1
```

The user can also double-click:

```text
StopManualSmoke.cmd
```

The stop script reads `.codex/manual-smoke-session.json`, calls helper `/shutdown`, and stops only the recorded PIDs.

## Record

After the user reports the result, update:

```text
docs/manual-smoke/results.md
```

Do not mark M1/M2/M3 runtime acceptance complete until the observed result is recorded there.
