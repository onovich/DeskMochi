extends RefCounted

const InputFrame = preload("res://scripts/input/input_frame.gd")

var _elapsed := 0.0
var _was_left_down := false
var _last_mouse_position := Vector2.ZERO
var _last_screen_mouse_position := Vector2.ZERO
var _has_position := false


func collect(viewport: Viewport, delta: float) -> InputFrame:
	_elapsed += delta

	var viewport_size := viewport.get_visible_rect().size
	var center := viewport_size * 0.5
	var phase := fmod(_elapsed, 4.8)
	var local_position := center
	var left_down := false

	if phase < 0.20:
		local_position = center + Vector2(18.0, -8.0)
		left_down = phase < 0.12
	elif phase < 2.90:
		var t := (phase - 0.20) / 2.70
		local_position = center + Vector2(
			sin(t * TAU * 1.2) * 62.0,
			cos(t * TAU * 0.8) * 28.0 - 8.0
		)
		left_down = true
	else:
		var t := (phase - 2.90) / 1.90
		local_position = center + Vector2(24.0 * sin(t * TAU), 12.0 * cos(t * TAU))
		left_down = false

	var frame := InputFrame.new()
	frame.mouse_position = local_position
	frame.screen_mouse_position = local_position
	frame.screen_mouse_delta = Vector2.ZERO if not _has_position else local_position - _last_screen_mouse_position
	frame.left_down = left_down
	frame.left_pressed = left_down and not _was_left_down
	frame.left_released = not left_down and _was_left_down

	_was_left_down = left_down
	_last_mouse_position = local_position
	_last_screen_mouse_position = local_position
	_has_position = true
	return frame
