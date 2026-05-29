# M1 Checklist

Source: `docs/Godot_Development_Plan.md`

## Done

- Godot 4.6.1 project initializes and loads.
- Transparent, borderless, always-on-top window starts on Windows.
- Mouse passthrough polygon is generated from the mochi body contour.
- Input -> Simulation -> Presentation loop exists.
- Basic states exist: `Idle`, `Dragged`, `Poked`, `Falling`, `Settled`.
- Dragging the mochi moves the desktop window.
- Poking and movement deform a multi-point spring body contour.
- Release enters falling, floor bounce, settled, and idle flow.
- Face anchors follow body squash/stretch and motion lean.
- Short click produces poke feedback; landing produces bounce feedback.
- Debug overlay includes current tuning values, active effect count, and passthrough outline.
- Idle frame budget throttles after calm time and restores during interaction.
- Project ops validation is configured through `Validate.cmd`.
- Manual smoke checklist exists in `docs/manual-smoke/`.
- Rough idle and active resource usage has an automated measurement script and recorded sample.
- M1 export decision is documented: editor-run prototype for now.
- Handfeel presets exist: soft, balanced, snappy.
- Handfeel settings and window position persist locally.
- Smoke flow now prioritizes visible mochi click and drag behavior.

## Remaining

- Continue tuning subjective soft-body feel.
- Verify visible mochi interaction manually after the drag logic simplification.
- Fill in manual smoke results for click and drag handfeel.

## M1 Exit Criteria

- User can launch the prototype and interact with the mochi for several minutes without losing the window.
- Visible mochi and controls are always interactable.
- Drag, poke, fall, bounce, and idle all feel intentional.
- Validation wrapper passes.
- Any known Godot native-window limitations are documented before moving to M2.
