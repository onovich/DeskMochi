extends RefCounted

const InputFrame = preload("res://scripts/input/input_frame.gd")

var _was_left_down := false
var _last_screen_mouse_position := Vector2.ZERO
var _has_screen_mouse_position := false
var _event_left_pressed := false
var _event_left_released := false
var _event_mouse_position := Vector2.ZERO
var _has_event_mouse_position := false


func handle_event(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_event_mouse_position = event.position
		_has_event_mouse_position = true
		if event.pressed:
			_event_left_pressed = true
		else:
			_event_left_released = true


func collect(viewport: Viewport) -> InputFrame:
	var left_down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var screen_mouse_position := Vector2(DisplayServer.mouse_get_position())
	var frame := InputFrame.new()
	frame.mouse_position = _event_mouse_position if _has_event_mouse_position and _event_left_pressed else viewport.get_mouse_position()
	frame.screen_mouse_position = screen_mouse_position
	frame.screen_mouse_delta = Vector2.ZERO if not _has_screen_mouse_position else screen_mouse_position - _last_screen_mouse_position
	frame.left_down = left_down
	frame.left_pressed = _event_left_pressed or (left_down and not _was_left_down)
	frame.left_released = _event_left_released or (not left_down and _was_left_down)
	_was_left_down = left_down
	_last_screen_mouse_position = screen_mouse_position
	_has_screen_mouse_position = true
	_event_left_pressed = false
	_event_left_released = false
	_has_event_mouse_position = false
	return frame
