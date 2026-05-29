# 0001: Godot Native Window First For M1

Date: 2026-05-29

## Status

Accepted for M1.

## Context

DeskMochi needs a transparent, borderless, always-on-top desktop pet window where transparent areas do not block desktop input. A reference Unity project, `D:\UnityProjects\Lo-Fi-Mate-Cozy-Time`, uses `Kirurobo.UniWindowController`, backed by the native `LibUniWinC` plugin.

Godot 4.6.1 provides native window transparency and mouse passthrough polygon APIs. For M1, the product only needs a single small desktop pet window and a body-shaped interaction region.

## Decision

Use Godot native window APIs first:

- transparent window
- borderless window
- always-on-top window
- `DisplayServer.window_set_mouse_passthrough(...)`

Do not port `UniWindowController` or add a Windows native plugin in M1.

For soft-body behavior, use simplified visual soft-body simulation instead of a full physical soft body. The first prototype moves the window while the mochi body stays near the window center, with stretch and poke deformation driven by input velocity and poke position.

## Consequences

- M1 stays small and mostly GDScript-only.
- The first high-risk item becomes a simple Godot spike, not native plugin development.
- If Godot's native transparency or passthrough is insufficient on Windows, a later fallback can use C# P/Invoke or GDExtension.
- Pixel-perfect alpha hit testing is intentionally deferred.
