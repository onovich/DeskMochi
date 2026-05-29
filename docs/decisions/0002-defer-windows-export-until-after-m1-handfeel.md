# 0002: Defer Windows Export Until After M1 Handfeel Validation

Date: 2026-05-29

## Status

Accepted for M1.

## Context

M1 exists to validate the desktop pet foundation: transparent window, body-shaped input region, drag/poke/fall/bounce, and soft-body handfeel. Godot export setup can be added at any time, but exported builds do not reduce the current product risk unless the interactive prototype already feels right.

## Decision

M1 remains an editor-run Godot prototype. Windows export presets and packaged build output are deferred until after:

- visible mochi interaction verification passes;
- handfeel is judged good enough for M1;
- known native-window limitations are documented.

## Consequences

- The team avoids spending time on packaging before the core desktop pet feel is validated.
- `Validate.cmd` remains the mechanical gate for now.
- Export setup becomes a Phase 1 exit polish task or a Phase 4 distribution task, depending on how much sharing is needed after M1.
