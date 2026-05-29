# Manual Smoke Results

## Transparent Window And Visible Input

Status: removed from active smoke flow on 2026-05-30.

Notes:

- User observed DeskMochi transparent always-on-top window appeared.
- Background click interactions are not a DeskMochi product requirement.
- Final decision: remove background-click validation and all counter-style validation from smoke.
- Current acceptance focuses on visible mochi input: click, drag, panel open, and controls.

## Handfeel

Status: needs retest after immediate-drag simplification on 2026-05-30.

Suggested initial tuning:

- Preset: balanced
- Spring: 78
- Damping: 14

Notes:

- User observed clicking mochi produced feedback.
- User did not observe drag feedback.
- Follow-up: make drag onset and drag movement feedback more obvious before retest.
- Second manual pass: mochi still could not be dragged.
- Fourth manual pass: one drag can work, but immediate subsequent drags fail until much later.
- Follow-up applied: pressing the visible mochi body now enters drag immediately; releasing returns to idle immediately.
- Fifth manual pass: dragging made the transparent window background turn into a black rectangle.
- Follow-up applied: keep the body-shaped input mask during click, poke, and drag. Only the control panel can temporarily request full-window input.

## Resource Usage

Status: measured automatically at 2026-05-29 19:10:36 +08:00; spot-checked during manual smoke on 2026-05-30.

| Mode | Samples | Processes | Seconds | Avg CPU % | Max Working Set MB | Max Private MB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| idle | 24 | 2 | 12.08 | 0.43 | 217.6 | 190.8 |
| active-demo | 32 | 2 | 16.26 | 0.88 | 220.4 | 192.7 |

Manual smoke spot-check on 2026-05-30:

- Godot working set: about 195 MB; private memory: about 181 MB.
- Helper working set: about 37 MB; private memory: about 11 MB.
- User reported a game crashed when DeskMochi started. This is more likely startup/rendering interference from a transparent always-on-top Godot/OpenGL window than sustained memory pressure.
- Follow-up applied: default `StartManualSmoke.ps1` no longer runs the full Godot preflight before launching the GUI. Use `Validate.cmd` separately or `StartManualSmoke.ps1 -FullPreflight` when the desktop is idle.

## M2 Control Panel

Status: partially verified manually at 2026-05-29.

Notes:

- Pass: `F2` and in-body button open the panel.
- Pass: ToDo item create, complete, and delete work.
- Partial: Pomodoro start and reset work, but 25 minutes is too long for smoke completion.
- Partial: Performance mode text changes, but expected runtime effect is unclear.
- Failed UX: slot picker purpose and operation are unclear.
- Second manual pass: smoke Pomodoro completion is visible but not prominent enough; future audio/animation can be deferred if logic interface is sound.
- Second manual pass: slot picker is understood as unclear DIY feature; file dialog is too small and could not select a file.
- Second manual pass: performance text changes, but `F1` debug did not respond, so real FPS cap could not be observed.
- Fourth manual pass: panel header text overlaps badly, making FPS/performance unreadable.
- Pending: passthrough restored after panel close.

## M3 Helper Events

Status: unclear manual observation at 2026-05-29.

Notes:

- Failed UX: user did not know what blue, purple, and green demo feedback meant or what conditions triggered it.
- Follow-up: smoke mode should show explicit helper event cues.
- Second manual pass: helper event text/feedback still was not visible or understandable.
- Pending: Godot remains responsive when helper stops.
