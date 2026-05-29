# M2 Checklist

Source: `docs/Godot_Development_Plan.md`

## Done / Started

- User preference persistence exists through `scripts/persistence/user_settings.gd`.
- Handfeel settings persist locally.
- Window position persists locally.
- Settings roundtrip is covered by `tools/CheckUserSettings.ps1` and `Validate.cmd`.
- Compact control panel exists behind `F2`, with an in-panel close button.
- Pomodoro timer supports start, pause, reset, and a completion reminder.
- Focus mode is connected: while Pomodoro is running, mochi uses a quieter face, softer pulse, and reduced interaction effects.
- ToDo list supports add, complete, delete, and local persistence.
- Productivity settings and control panel visibility persist through `user://deskmochi_settings.json`.
- Productivity state behavior is covered by `tools/CheckProductivityState.ps1` and `Validate.cmd`.
- Custom slot system V1 exists for face and head image paths.
- Mochi rendering loads local image paths into face and head slots when files exist.
- Slot paths persist through `user://deskmochi_settings.json`.
- Slot images can be selected through an in-panel file picker or entered as raw paths.
- The compact panel can be opened with `F2` or the small in-body toggle button.

## Remaining

- Add a short manual smoke pass for control panel input, Pomodoro completion, and ToDo persistence.

## M2 Exit Criteria

- One Pomodoro focus cycle can be completed. Automated state is implemented; manual runtime smoke is still needed.
- ToDo data survives restart. Automated settings roundtrip passes; manual app restart smoke is still needed.
- At least one local image can be mounted onto the mochi body. Runtime support and file picker are implemented; manual visual smoke with a real image is still needed.
