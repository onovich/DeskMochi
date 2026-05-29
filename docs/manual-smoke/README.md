# Manual Smoke Checks

These checks cover behavior that the short Godot startup smoke cannot prove.

Codex should start the interactive session instead of asking the user to assemble windows and commands:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\StartManualSmoke.ps1 -DemoEvents
```

Or double-click `StartManualSmoke.cmd` in the project root.

After observation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\StopManualSmoke.ps1
```

Or double-click `StopManualSmoke.cmd`.

The user only observes and reports pass/fail notes.

## Visible Mochi Interaction

Goal: prove that the visible mochi body is always interactable.

Observation steps after Codex starts the smoke session:

1. Click inside the visible mochi body. Expected: DeskMochi receives the interaction and shows poke feedback.
2. Press and drag the visible mochi body. Expected: the DeskMochi window moves immediately, every time, with no cooldown.
3. Release and immediately drag again. Expected: the next drag starts immediately.
4. Press `F1` or panel `Debug`. Expected: debug information appears.
5. Press `R`. Expected: DeskMochi resets near the lower-right screen area.

Record result in `docs/manual-smoke/results.md`.

## Handfeel

Goal: decide whether M1 handfeel is good enough to move toward M2.

Observation steps:

1. Run the prototype for several minutes.
2. Try short click, press-and-hold, fast drag, slow drag, release, and repeated pokes.
3. Toggle debug overlay with `F1`.
4. Switch presets with `1`, `2`, and `3`.
5. Tune spring with `[` and `]`.
6. Tune damping with `;` and `'`.

Record useful values and subjective notes in `docs/manual-smoke/results.md`.

## Resource Usage

Goal: get a rough idle/active process snapshot.

Automated rough measurement:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\MeasureGodotResource.ps1
```

Manual steps:

1. Run the prototype and leave it idle for at least 10 seconds.
2. In another PowerShell window, run:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File tools\SampleGodotProcess.ps1
   ```

3. Interact with the prototype for 10 seconds and run the command again.
4. Record both snapshots in `docs/manual-smoke/results.md`.

## M2 Control Panel

Goal: prove that the compact panel supports the first productivity and customization loop.

Observation steps after Codex starts the smoke session:

1. Run DeskMochi and press `F2`. Expected: a compact panel appears.
2. Close the panel and click the small `...` button on mochi. Expected: the same panel opens.
3. Press `Start`. Expected: in smoke mode the timer counts down from 15 seconds and mochi enters a quieter focus expression.
4. Press `Pause`, then `Start` again. Expected: the timer pauses and resumes.
5. Add a task, mark it complete, delete it, then add another task to keep.
6. Use the `Pick` button beside the Head or Face image slot and choose a local `.png`, `.jpg`, `.jpeg`, or `.webp` image. Expected: the image mounts on mochi's head or face.
7. Click the performance mode button in the panel header. Expected: mode cycles through Eco 60/12, Balanced 90/24, and Quality 120/30. Click `Debug` in the panel header; the debug overlay's FPS cap should match the current active/idle mode.
8. Close and reopen DeskMochi. Expected: the kept task, slot path, performance mode, window position, and handfeel settings persist.
9. Close the panel. Expected: visible mochi interaction remains available immediately.

Record result in `docs/manual-smoke/results.md`.

## M3 Helper Events

Goal: prove that external developer-workflow data can drive pet feedback without blocking Godot.

Observation steps after Codex starts the smoke session:

1. With `-DemoEvents`, wait about 15 seconds. Expected: text cues appear for helper events and mochi emits blue keyboard-like energy, purple token charge, then green Git celebration feedback.
2. For a real helper check, run without `-DemoEvents`, type quickly in any editor, append `total_tokens: 12345` to the configured token log, or push Git. Expected: matching feedback appears.
3. Stop the helper through `tools\StopManualSmoke.ps1`. Expected: DeskMochi remains responsive and would retry quietly if kept open.

Record result in `docs/manual-smoke/results.md`.
