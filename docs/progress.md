# DeskMochi Progress

## 2026-05-29

Phase 0 is functionally validated:

- Godot 4.6.1 project initialized.
- Transparent, borderless, always-on-top prototype window starts successfully.
- Mouse passthrough polygon is driven from the mochi body contour.
- Short window smoke passes with the Windows display driver.

M1 has started:

- Input -> Simulation -> Presentation loop exists.
- The mochi body uses a multi-point spring contour.
- Dragging the mochi moves the desktop window.
- Poking and fast movement deform the body contour.
- Release now enters a Falling -> Settled -> Idle flow with floor bounce.
- Face anchors follow squash/stretch and motion lean.
- Short click emits poke rings and sparks; landing emits bounce feedback.
- Idle frame budget drops after a short calm period and restores during interaction.
- Development debug overlay, tuning hotkeys, effect count, and passthrough outline are available behind `F1`.
- Handfeel presets are available through `1` soft, `2` balanced, and `3` snappy.
- Window position and handfeel settings persist through `user://deskmochi_settings.json`.
- Manual smoke checklist and result log are prepared under `docs/manual-smoke/`.
- Automated idle/active resource sampling is available through `tools/MeasureGodotResource.ps1`.
- M1 packaging decision is documented in `docs/decisions/0002-defer-windows-export-until-after-m1-handfeel.md`.

M2 foundation has started:

- User preference persistence exists through `scripts/persistence/user_settings.gd`.
- Handfeel settings and window position are saved locally.
- Settings roundtrip is validated by `tools/CheckUserSettings.ps1`.
- Compact control panel is available with `F2`.
- Pomodoro start, pause, reset, completion reminder, and persisted state are implemented.
- Running Pomodoro now drives Focus mode, making mochi visually quieter.
- ToDo add, complete, delete, and persisted state are implemented in the compact panel.
- Productivity state behavior is validated by `tools/CheckProductivityState.ps1`.
- Customization slot V1 is implemented for head and face image paths, including a file picker, persisted paths, and runtime local texture loading.
- The panel opens through `F2` or a small in-body toggle button.
- When the panel is visible, the app temporarily clears mouse passthrough so UI controls can receive input; hiding the panel restores mochi-contour passthrough.

M3 foundation has started:

- Local .NET helper service prototype exists under `helper/DeskMochi.Helper`.
- Helper exposes `/health` and `/events?last_id=...` on localhost.
- Keyboard activity emits frequency only; no key contents are recorded.
- Git remote-ref log changes emit push-like events for a configured repo.
- AI token log lines emit token usage events.
- Helper supports JSON config files plus command-line overrides.
- Godot persists the helper event endpoint in user settings.
- Godot polls helper events and maps keyboard, Git, and token data into mochi visual feedback.
- Helper build, parser self-test, and HTTP health check are included in `Validate.cmd`.

M4 foundation has started:

- Performance mode V1 is available from the compact panel.
- Eco, Balanced, and Quality modes change active and idle FPS caps.
- Performance mode persists through `user://deskmochi_settings.json`.
- Windows export preset and export readiness script are in place.
- Release dry run reports Godot export templates are not installed yet, so real Windows packaging remains pending.

Workflow improvements:

- Lessons learned are recorded in `docs/Lessons_Learned.md`.
- Manual smoke ownership is documented in `docs/Workflow_Improvements.md`.
- Codex-started manual smoke scripts exist: `tools/StartManualSmoke.ps1` and `tools/StopManualSmoke.ps1`.
- Background-click validation was removed from the smoke flow after manual testing showed it confused the actual acceptance goal; background clicks are not a product interaction.

Next target:

- Run Codex-started manual smoke and record the user's observation.
- Tune subjective soft-body feel using the debug overlay.
- Document any native-window limitations before moving to M2.
- Manually smoke the M2 panel: `F2`, Pomodoro completion, ToDo restart persistence, slot image mounting, and panel hide/restore passthrough.
- Manually smoke M3 with helper running: keyboard frequency, real Git push, and token log growth.
- Continue M4 packaging prep: export preset, Windows package dry run, and startup/tray decisions.
