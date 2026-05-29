# 0003: Background Click Validation Removed From Smoke

Date: 2026-05-29

## Status

Accepted.

## Context

DeskMochi uses Godot's native mouse passthrough polygon to keep transparent window areas from blocking desktop interaction. A repeatable automated smoke was attempted with a separate background validation surface and synthetic mouse clicks.

During manual smoke, that validation surface confused the real acceptance question. DeskMochi has no product requirement for clicking transparent background space. The test must focus on visible mochi interaction: click and drag the visible body any time, with no cooldown.

## Decision

Remove background-click validation from the smoke flow. M1 smoke focuses on visible DeskMochi interaction and control usability.

## Consequences

- Visible mochi click and drag behavior is the primary manual acceptance path.
- `Validate.cmd` remains the mechanical gate for project loading and startup.
- Transparent-area passthrough remains an internal window behavior, not a background-click product interaction.
