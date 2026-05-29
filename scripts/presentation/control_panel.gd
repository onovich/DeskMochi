extends PanelContainer

signal start_pause_requested
signal reset_requested
signal close_requested
signal todo_add_requested(text: String)
signal todo_toggle_requested(id: int, done: bool)
signal todo_delete_requested(id: int)
signal slot_apply_requested(slot_name: StringName, path: String)
signal performance_mode_requested
signal debug_toggle_requested

@onready var _timer_label: Label = $Margin/Rows/TimerLabel
@onready var _status_label: Label = $Margin/Rows/StatusLabel
@onready var _start_pause_button: Button = $Margin/Rows/PomodoroButtons/StartPauseButton
@onready var _reset_button: Button = $Margin/Rows/PomodoroButtons/ResetButton
@onready var _performance_button: Button = $Margin/Rows/PerformanceRow/PerformanceButton
@onready var _fps_label: Label = $Margin/Rows/PerformanceRow/FpsLabel
@onready var _debug_button: Button = $Margin/Rows/PerformanceRow/DebugButton
@onready var _close_button: Button = $Margin/Rows/Header/CloseButton
@onready var _todo_input: LineEdit = $Margin/Rows/TodoAddRow/TodoInput
@onready var _todo_add_button: Button = $Margin/Rows/TodoAddRow/TodoAddButton
@onready var _todo_list: VBoxContainer = $Margin/Rows/TodoScroll/TodoList
@onready var _head_slot_input: LineEdit = $Margin/Rows/HeadSlotRow/HeadSlotInput
@onready var _head_slot_button: Button = $Margin/Rows/HeadSlotRow/HeadSlotButton
@onready var _head_slot_browse_button: Button = $Margin/Rows/HeadSlotRow/HeadSlotBrowseButton
@onready var _face_slot_input: LineEdit = $Margin/Rows/FaceSlotRow/FaceSlotInput
@onready var _face_slot_button: Button = $Margin/Rows/FaceSlotRow/FaceSlotButton
@onready var _face_slot_browse_button: Button = $Margin/Rows/FaceSlotRow/FaceSlotBrowseButton
@onready var _slot_file_dialog: FileDialog = $SlotFileDialog

var _todo_signature := ""
var _pending_slot_name := &"head"


func _ready() -> void:
	_start_pause_button.pressed.connect(_on_start_pause_pressed)
	_reset_button.pressed.connect(_on_reset_pressed)
	_performance_button.pressed.connect(_on_performance_pressed)
	_debug_button.pressed.connect(_on_debug_pressed)
	_close_button.pressed.connect(_on_close_pressed)
	_todo_add_button.pressed.connect(_on_todo_add_pressed)
	_todo_input.text_submitted.connect(_on_todo_text_submitted)
	_head_slot_button.pressed.connect(_on_head_slot_pressed)
	_head_slot_input.text_submitted.connect(_on_head_slot_submitted)
	_head_slot_browse_button.pressed.connect(_on_head_slot_browse_pressed)
	_face_slot_button.pressed.connect(_on_face_slot_pressed)
	_face_slot_input.text_submitted.connect(_on_face_slot_submitted)
	_face_slot_browse_button.pressed.connect(_on_face_slot_browse_pressed)
	_slot_file_dialog.file_selected.connect(_on_slot_file_selected)


func update_from_state(pomodoro_state, todo_state, slot_state, performance_mode: StringName, fps_cap: int) -> void:
	_timer_label.text = pomodoro_state.get_time_text()
	_status_label.text = pomodoro_state.get_status_text()
	_start_pause_button.text = "Pause" if pomodoro_state.status == &"running" else "Start"
	_performance_button.text = _performance_text(performance_mode)
	_fps_label.text = "FPS cap: %d" % fps_cap
	_sync_slot_input(_head_slot_input, slot_state.head_image_path)
	_sync_slot_input(_face_slot_input, slot_state.face_image_path)
	_rebuild_todo_list_if_needed(todo_state)


func clear_todo_input() -> void:
	_todo_input.text = ""


func _rebuild_todo_list_if_needed(todo_state) -> void:
	var signature := JSON.stringify(todo_state.to_array())
	if signature == _todo_signature:
		return
	_todo_signature = signature

	for child in _todo_list.get_children():
		child.queue_free()

	if todo_state.items.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No tasks"
		empty_label.modulate = Color(0.28, 0.17, 0.20, 0.58)
		_todo_list.add_child(empty_label)
		return

	for item in todo_state.items:
		var id := int(item.get("id", 0))
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0.0, 24.0)

		var check := CheckBox.new()
		check.button_pressed = bool(item.get("done", false))
		check.text = str(item.get("text", ""))
		check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		check.clip_text = true
		check.toggled.connect(_on_todo_toggled.bind(id))
		row.add_child(check)

		var delete_button := Button.new()
		delete_button.text = "Del"
		delete_button.custom_minimum_size = Vector2(42.0, 24.0)
		delete_button.pressed.connect(_on_todo_delete_pressed.bind(id))
		row.add_child(delete_button)

		_todo_list.add_child(row)


func _on_start_pause_pressed() -> void:
	start_pause_requested.emit()


func _on_reset_pressed() -> void:
	reset_requested.emit()


func _on_close_pressed() -> void:
	close_requested.emit()


func _on_performance_pressed() -> void:
	performance_mode_requested.emit()


func _on_debug_pressed() -> void:
	debug_toggle_requested.emit()


func _on_todo_add_pressed() -> void:
	todo_add_requested.emit(_todo_input.text)


func _on_todo_text_submitted(text: String) -> void:
	todo_add_requested.emit(text)


func _on_todo_toggled(done: bool, id: int) -> void:
	todo_toggle_requested.emit(id, done)


func _on_todo_delete_pressed(id: int) -> void:
	todo_delete_requested.emit(id)


func _sync_slot_input(input: LineEdit, path: String) -> void:
	if input.has_focus():
		return
	if input.text != path:
		input.text = path


func _on_head_slot_pressed() -> void:
	slot_apply_requested.emit(&"head", _head_slot_input.text)


func _on_head_slot_submitted(path: String) -> void:
	slot_apply_requested.emit(&"head", path)


func _on_face_slot_pressed() -> void:
	slot_apply_requested.emit(&"face", _face_slot_input.text)


func _on_face_slot_submitted(path: String) -> void:
	slot_apply_requested.emit(&"face", path)


func _on_head_slot_browse_pressed() -> void:
	_open_slot_dialog(&"head")


func _on_face_slot_browse_pressed() -> void:
	_open_slot_dialog(&"face")


func _open_slot_dialog(slot_name: StringName) -> void:
	_pending_slot_name = slot_name
	_slot_file_dialog.popup_centered_ratio(0.96)


func _on_slot_file_selected(path: String) -> void:
	if _pending_slot_name == &"head":
		_head_slot_input.text = path
	elif _pending_slot_name == &"face":
		_face_slot_input.text = path
	slot_apply_requested.emit(_pending_slot_name, path)


func _performance_text(mode: StringName) -> String:
	if mode == &"eco":
		return "Eco 60/12"
	if mode == &"quality":
		return "Quality 120/30"
	return "Balanced 90/24"
