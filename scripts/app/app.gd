extends Node2D

const InputCollector = preload("res://scripts/input/input_collector.gd")
const DemoInputDriver = preload("res://scripts/dev/demo_input_driver.gd")
const MochiSimulation = preload("res://scripts/simulation/mochi_simulation.gd")
const MochiState = preload("res://scripts/simulation/mochi_state.gd")
const WindowController = preload("res://scripts/presentation/window_controller.gd")
const UserSettings = preload("res://scripts/persistence/user_settings.gd")
const PomodoroState = preload("res://scripts/productivity/pomodoro_state.gd")
const TodoState = preload("res://scripts/productivity/todo_state.gd")
const SlotState = preload("res://scripts/customization/slot_state.gd")

const IDLE_THROTTLE_DELAY := 2.0
const KEYBOARD_ACTIVITY_COLOR := Color(0.42, 0.74, 1.0, 0.58)
const GIT_PUSH_COLOR := Color(0.44, 1.0, 0.58, 0.72)
const TOKEN_USAGE_COLOR := Color(0.78, 0.56, 1.0, 0.62)

@onready var mochi_view = $MochiView
@onready var debug_layer = $DebugLayer
@onready var debug_label = $DebugLayer/DebugLabel
@onready var control_panel = $ControlLayer/ControlPanel
@onready var panel_toggle_button: Button = $ControlLayer/PanelToggleButton
@onready var helper_event_client = $HelperEventClient
@onready var smoke_layer = $SmokeLayer
@onready var smoke_label = $SmokeLayer/SmokeLabel

var input_collector := InputCollector.new()
var demo_input_driver := DemoInputDriver.new()
var mochi_simulation := MochiSimulation.new()
var mochi_state := MochiState.new()
var window_controller := WindowController.new()
var user_settings := UserSettings.new()
var pomodoro_state := PomodoroState.new()
var todo_state := TodoState.new()
var slot_state := SlotState.new()
var performance_mode := &"balanced"
var _debug_visible := false
var _control_panel_visible := false
var _active_max_fps := 90
var _idle_max_fps := 24
var _idle_seconds := 0.0
var _demo_motion_enabled := false
var _smoke_mode_enabled := false
var _smoke_cue_timer := 0.0
var _save_requested := false
var _save_timer := 0.0


func _ready() -> void:
	_demo_motion_enabled = OS.get_cmdline_user_args().has("--demo-motion")
	_smoke_mode_enabled = OS.get_cmdline_user_args().has("--smoke-mode")
	user_settings.load()
	performance_mode = user_settings.get_performance_mode()
	_apply_performance_mode()
	window_controller.configure(get_window(), get_viewport())
	window_controller.apply_saved_position(user_settings.get_window_position(window_controller.get_position()))
	mochi_state.position = get_viewport_rect().size * 0.5
	mochi_state.initialize_contour()
	user_settings.apply_to_mochi_state(mochi_state)
	user_settings.apply_to_pomodoro_state(pomodoro_state)
	if _smoke_mode_enabled:
		pomodoro_state.focus_seconds = 15.0
		pomodoro_state.remaining_seconds = 15.0
		pomodoro_state.status = &"stopped"
	user_settings.apply_to_todo_state(todo_state)
	user_settings.apply_to_slot_state(slot_state)
	mochi_view.state = mochi_state
	mochi_view.slot_state = slot_state
	helper_event_client.endpoint = helper_event_client.DEFAULT_ENDPOINT if _smoke_mode_enabled else user_settings.get_helper_endpoint(helper_event_client.endpoint)
	panel_toggle_button.pressed.connect(_on_panel_toggle_pressed)
	helper_event_client.events_received.connect(_on_helper_events_received)
	_connect_control_panel()
	_set_control_panel_visible(user_settings.get_control_panel_visible(false), false)
	_update_control_panel()
	_update_panel_toggle_button()
	smoke_layer.visible = _smoke_mode_enabled
	if _smoke_mode_enabled:
		_show_smoke_cue("Smoke mode: visible mochi should always drag immediately")
	_update_passthrough()


func _input(event: InputEvent) -> void:
	if _demo_motion_enabled:
		return

	input_collector.handle_event(event)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			_debug_visible = not _debug_visible
			debug_layer.visible = _debug_visible
			mochi_view.show_debug_overlay = _debug_visible
			mochi_view.queue_redraw()
		elif event.keycode == KEY_F2:
			_set_control_panel_visible(not _control_panel_visible)
		elif event.keycode == KEY_BRACKETLEFT:
			mochi_state.spring_strength = maxf(18.0, mochi_state.spring_strength - 8.0)
			_request_save()
		elif event.keycode == KEY_BRACKETRIGHT:
			mochi_state.spring_strength = minf(180.0, mochi_state.spring_strength + 8.0)
			_request_save()
		elif event.keycode == KEY_SEMICOLON:
			mochi_state.damping = maxf(3.0, mochi_state.damping - 1.0)
			_request_save()
		elif event.keycode == KEY_APOSTROPHE:
			mochi_state.damping = minf(36.0, mochi_state.damping + 1.0)
			_request_save()
		elif event.keycode == KEY_1:
			mochi_state.apply_tuning_preset(&"soft")
			_request_save()
		elif event.keycode == KEY_2:
			mochi_state.apply_tuning_preset(&"balanced")
			_request_save()
		elif event.keycode == KEY_3:
			mochi_state.apply_tuning_preset(&"snappy")
			_request_save()


func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		_save_settings()
		window_controller.clear_passthrough()
		get_tree().quit()
	if Input.is_key_pressed(KEY_R):
		window_controller.reset_position()
		_request_save()

	var input_frame = demo_input_driver.collect(get_viewport(), delta) if _demo_motion_enabled else input_collector.collect(get_viewport())
	var pomodoro_completed := pomodoro_state.step(delta)
	mochi_state.focus_mode = pomodoro_state.is_focus_running()
	mochi_simulation.step(mochi_state, input_frame, delta, get_viewport_rect())
	if pomodoro_completed:
		_handle_pomodoro_complete()
	window_controller.move_by(mochi_state.window_delta)
	if mochi_state.window_delta.length_squared() > 0.01:
		_request_save()
	_update_frame_budget(delta)
	_update_deferred_save(delta)
	_update_control_panel()
	_update_panel_toggle_button()
	_update_smoke_cue(delta)
	mochi_view.queue_redraw()
	_update_debug_label()
	_update_passthrough()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_settings()
		window_controller.clear_passthrough()
		get_tree().quit()


func _update_passthrough() -> void:
	if _control_panel_visible:
		window_controller.clear_passthrough()
		return

	window_controller.update_passthrough(mochi_view.get_passthrough_polygon())


func _update_debug_label() -> void:
	if not _debug_visible:
		return

	debug_label.text = "mode: %s\npreset: %s\nperf: %s\nfocus: %s\npomodoro: %s %s\nspeed: %.0f\nspring: %.0f\ndamping: %.0f\nfps cap: %d\npoints: %d\neffects: %d\ndemo: %s\nF2 panel | 1 soft | 2 balanced | 3 snappy\n[] spring | ;' damping | R reset | Esc quit" % [
		mochi_state.mode,
		mochi_state.tuning_preset,
		performance_mode,
		"on" if mochi_state.focus_mode else "off",
		pomodoro_state.get_time_text(),
		pomodoro_state.status,
		mochi_state.velocity.length(),
		mochi_state.spring_strength,
		mochi_state.damping,
		Engine.max_fps,
		mochi_state.contour_offsets.size(),
		mochi_state.visual_effects.size(),
		"on" if _demo_motion_enabled else "off"
	]


func _update_frame_budget(delta: float) -> void:
	var calm := mochi_state.mode == &"idle" and mochi_state.velocity.length() < 4.0 and mochi_state.poke_strength <= 0.01
	if calm:
		_idle_seconds += delta
	else:
		_idle_seconds = 0.0

	var target_fps := _idle_max_fps if _idle_seconds >= IDLE_THROTTLE_DELAY else _active_max_fps
	if Engine.max_fps != target_fps:
		Engine.max_fps = target_fps


func _request_save() -> void:
	if _demo_motion_enabled:
		return
	_save_requested = true
	_save_timer = 0.0


func _update_deferred_save(delta: float) -> void:
	if not _save_requested:
		return

	_save_timer += delta
	if _save_timer >= 0.75:
		_save_settings()


func _save_settings() -> void:
	if _demo_motion_enabled:
		return
	user_settings.capture_mochi_state(mochi_state)
	user_settings.capture_window_position(window_controller.get_position())
	user_settings.capture_pomodoro_state(pomodoro_state)
	user_settings.capture_todo_state(todo_state)
	user_settings.capture_control_panel_visible(_control_panel_visible)
	user_settings.capture_slot_state(slot_state)
	user_settings.capture_helper_endpoint(helper_event_client.endpoint)
	user_settings.capture_performance_mode(performance_mode)
	user_settings.save()
	_save_requested = false
	_save_timer = 0.0


func _connect_control_panel() -> void:
	control_panel.start_pause_requested.connect(_on_pomodoro_start_pause_requested)
	control_panel.reset_requested.connect(_on_pomodoro_reset_requested)
	control_panel.close_requested.connect(_on_control_panel_close_requested)
	control_panel.todo_add_requested.connect(_on_todo_add_requested)
	control_panel.todo_toggle_requested.connect(_on_todo_toggle_requested)
	control_panel.todo_delete_requested.connect(_on_todo_delete_requested)
	control_panel.slot_apply_requested.connect(_on_slot_apply_requested)
	control_panel.performance_mode_requested.connect(_on_performance_mode_requested)
	control_panel.debug_toggle_requested.connect(_on_debug_toggle_requested)


func _set_control_panel_visible(visible: bool, request_save: bool = true) -> void:
	_control_panel_visible = visible
	window_controller.set_panel_mode(visible)
	control_panel.visible = visible
	panel_toggle_button.visible = not visible
	if request_save:
		_request_save()
	_update_passthrough()


func _update_control_panel() -> void:
	control_panel.update_from_state(pomodoro_state, todo_state, slot_state, performance_mode, Engine.max_fps)


func _update_panel_toggle_button() -> void:
	if _control_panel_visible:
		return

	var button_size := panel_toggle_button.size
	var target_position := mochi_state.get_local_anchor(Vector2(0.58, -0.42), 0.02) - button_size * 0.5
	panel_toggle_button.position = target_position.round()


func _handle_pomodoro_complete() -> void:
	_show_smoke_cue("Pomodoro complete")
	mochi_state.focus_mode = false
	mochi_state.poke_strength = maxf(mochi_state.poke_strength, 0.65)
	mochi_state.poke_point = mochi_state.position + Vector2(0.0, -mochi_state.radius.y * 0.55)
	mochi_state.emit_ring(mochi_state.position, Color(1.0, 0.70, 0.36, 0.62), 18.0, 72.0, 0.65)
	_set_control_panel_visible(true)
	_request_save()


func _on_pomodoro_start_pause_requested() -> void:
	pomodoro_state.start_or_pause()
	_request_save()


func _on_pomodoro_reset_requested() -> void:
	pomodoro_state.reset()
	mochi_state.focus_mode = false
	_request_save()


func _on_control_panel_close_requested() -> void:
	_set_control_panel_visible(false)


func _on_panel_toggle_pressed() -> void:
	_set_control_panel_visible(true)


func _on_todo_add_requested(text: String) -> void:
	todo_state.add_item(text)
	control_panel.clear_todo_input()
	_request_save()


func _on_todo_toggle_requested(id: int, done: bool) -> void:
	todo_state.toggle_item(id, done)
	_request_save()


func _on_todo_delete_requested(id: int) -> void:
	todo_state.delete_item(id)
	_request_save()


func _on_slot_apply_requested(slot_name: StringName, path: String) -> void:
	slot_state.set_slot_path(slot_name, path)
	mochi_view.queue_redraw()
	_request_save()


func _on_performance_mode_requested() -> void:
	if performance_mode == &"eco":
		performance_mode = &"balanced"
	elif performance_mode == &"balanced":
		performance_mode = &"quality"
	else:
		performance_mode = &"eco"
	_apply_performance_mode()
	_show_smoke_cue("Performance: %s active / %s idle FPS" % [_active_max_fps, _idle_max_fps])
	_request_save()


func _on_debug_toggle_requested() -> void:
	_debug_visible = not _debug_visible
	debug_layer.visible = _debug_visible
	mochi_view.show_debug_overlay = _debug_visible
	mochi_view.queue_redraw()


func _apply_performance_mode() -> void:
	if performance_mode == &"eco":
		_active_max_fps = 60
		_idle_max_fps = 12
	elif performance_mode == &"quality":
		_active_max_fps = 120
		_idle_max_fps = 30
	else:
		performance_mode = &"balanced"
		_active_max_fps = 90
		_idle_max_fps = 24
	Engine.max_fps = _active_max_fps


func _on_helper_events_received(events: Array) -> void:
	for raw_event in events:
		if typeof(raw_event) != TYPE_DICTIONARY:
			continue

		var event_type := StringName(str(raw_event.get("type", "")))
		var payload: Dictionary = raw_event.get("payload", {})
		if event_type == &"keyboard_activity":
			_apply_keyboard_activity(payload)
		elif event_type == &"git_push":
			_apply_git_push(payload)
		elif event_type == &"token_usage":
			_apply_token_usage(payload)


func _apply_keyboard_activity(payload: Dictionary) -> void:
	_show_smoke_cue("Helper event: keyboard activity")
	var keys_per_minute := float(payload.get("keys_per_minute", 0.0))
	var intensity: float = clampf(keys_per_minute / 180.0, 0.25, 1.0)
	var origin := mochi_state.position + Vector2(0.0, -mochi_state.radius.y * 0.35)
	mochi_state.emit_ring(origin, KEYBOARD_ACTIVITY_COLOR, 12.0, 34.0 + intensity * 24.0, 0.38)
	for index in ceili(2.0 + intensity * 4.0):
		var angle: float = -PI * 0.9 + float(index) * PI * 0.36
		mochi_state.emit_spark(origin, Vector2(cos(angle), sin(angle)) * (70.0 + intensity * 70.0), KEYBOARD_ACTIVITY_COLOR, 3.4, 0.36)


func _apply_git_push(_payload: Dictionary) -> void:
	_show_smoke_cue("Helper event: Git push")
	var origin := mochi_state.position + Vector2(0.0, -mochi_state.radius.y * 0.72)
	mochi_state.poke_strength = maxf(mochi_state.poke_strength, 0.80)
	mochi_state.poke_point = origin
	mochi_state.emit_ring(origin, GIT_PUSH_COLOR, 18.0, 86.0, 0.72)
	for index in 10:
		var angle: float = -PI + float(index) * TAU / 10.0
		mochi_state.emit_spark(origin, Vector2(cos(angle), sin(angle)) * 135.0, GIT_PUSH_COLOR, 5.0, 0.62)


func _apply_token_usage(payload: Dictionary) -> void:
	_show_smoke_cue("Helper event: token usage")
	var tokens := float(payload.get("tokens", 0.0))
	var intensity: float = clampf(tokens / 16000.0, 0.28, 1.0)
	var origin := mochi_state.position
	mochi_state.emit_ring(origin, TOKEN_USAGE_COLOR, 22.0, 48.0 + intensity * 44.0, 0.55)
	mochi_state.poke_strength = maxf(mochi_state.poke_strength, 0.35 + intensity * 0.35)
	mochi_state.poke_point = mochi_state.position + Vector2(mochi_state.radius.x * 0.55, 0.0)


func _show_smoke_cue(text: String) -> void:
	if not _smoke_mode_enabled:
		return

	smoke_label.text = text
	smoke_label.visible = true
	_smoke_cue_timer = 3.0


func _update_smoke_cue(delta: float) -> void:
	if not _smoke_mode_enabled or not smoke_label.visible:
		return

	_smoke_cue_timer -= delta
	if _smoke_cue_timer <= 0.0:
		smoke_label.visible = false
