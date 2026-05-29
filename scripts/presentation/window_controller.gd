extends RefCounted

const WINDOW_SIZE := Vector2i(420, 360)
const PANEL_WINDOW_SIZE := Vector2i(760, 560)

var _window: Window
var _viewport: Viewport


func configure(window: Window, viewport: Viewport) -> void:
	_window = window
	_viewport = viewport

	_viewport.transparent_bg = true
	_window.size = WINDOW_SIZE
	_window.min_size = Vector2i(260, 220)
	_window.borderless = true
	_window.always_on_top = true
	_window.transparent = true
	_window.unresizable = false

	reset_position()


func apply_saved_position(position: Vector2i) -> void:
	if _window == null:
		return
	_window.position = _clamp_to_screen(position)


func update_passthrough(points: PackedVector2Array) -> void:
	if points.size() < 3:
		clear_passthrough()
		return

	DisplayServer.window_set_mouse_passthrough(points)


func move_by(delta: Vector2) -> void:
	if _window == null or delta.length_squared() < 0.01:
		return

	_window.position = _clamp_to_screen(_window.position + Vector2i(roundi(delta.x), roundi(delta.y)))


func reset_position() -> void:
	if _window == null:
		return

	var screen := DisplayServer.window_get_current_screen()
	var screen_position := DisplayServer.screen_get_position(screen)
	var screen_size := DisplayServer.screen_get_size(screen)
	var target := Vector2i(
		screen_position.x + maxi(40, screen_size.x - WINDOW_SIZE.x - 80),
		screen_position.y + maxi(40, screen_size.y - WINDOW_SIZE.y - 120)
	)
	_window.position = _clamp_to_screen(target)


func set_panel_mode(enabled: bool) -> void:
	if _window == null:
		return

	_window.size = PANEL_WINDOW_SIZE if enabled else WINDOW_SIZE
	_window.position = _clamp_to_screen(_window.position)


func get_position() -> Vector2i:
	if _window == null:
		return Vector2i.ZERO
	return _window.position


func clear_passthrough() -> void:
	DisplayServer.window_set_mouse_passthrough(PackedVector2Array())


func _clamp_to_screen(position: Vector2i) -> Vector2i:
	var screen := DisplayServer.window_get_current_screen()
	var screen_position := DisplayServer.screen_get_position(screen)
	var screen_size := DisplayServer.screen_get_size(screen)
	var max_position := screen_position + screen_size - _window.size
	return Vector2i(
		clampi(position.x, screen_position.x, max_position.x),
		clampi(position.y, screen_position.y, max_position.y)
	)
