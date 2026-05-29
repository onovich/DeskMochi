extends RefCounted

const SETTINGS_PATH := "user://deskmochi_settings.json"

var data := {
	"schema_version": 1,
	"window": {},
	"handfeel": {
		"preset": "balanced",
		"spring_strength": 78.0,
		"damping": 14.0,
		"poke_depth": 34.0,
		"inertia_strength": 0.030,
	},
	"ui": {
		"control_panel_visible": false,
	},
	"productivity": {
		"pomodoro": {
			"focus_seconds": 1500.0,
			"remaining_seconds": 1500.0,
			"status": "stopped",
			"phase": "focus",
			"completed_cycles": 0,
		},
		"todos": [],
	},
	"customization": {
		"slots": {
			"head_image_path": "",
			"face_image_path": "",
		},
	},
	"integration": {
		"helper_endpoint": "http://127.0.0.1:8765/events",
	},
	"performance": {
		"mode": "balanced",
	},
}


func load() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not read settings file: %s" % SETTINGS_PATH)
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Settings file is not a JSON object: %s" % SETTINGS_PATH)
		return

	_merge_dict(data, parsed)


func save() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write settings file: %s" % SETTINGS_PATH)
		return

	file.store_string(JSON.stringify(data, "\t"))


func apply_to_mochi_state(state) -> void:
	var handfeel: Dictionary = data.get("handfeel", {})
	state.tuning_preset = StringName(str(handfeel.get("preset", "balanced")))
	state.spring_strength = float(handfeel.get("spring_strength", state.spring_strength))
	state.damping = float(handfeel.get("damping", state.damping))
	state.poke_depth = float(handfeel.get("poke_depth", state.poke_depth))
	state.inertia_strength = float(handfeel.get("inertia_strength", state.inertia_strength))


func capture_mochi_state(state) -> void:
	data["handfeel"] = {
		"preset": str(state.tuning_preset),
		"spring_strength": state.spring_strength,
		"damping": state.damping,
		"poke_depth": state.poke_depth,
		"inertia_strength": state.inertia_strength,
	}


func get_window_position(default_position: Vector2i) -> Vector2i:
	var window_data: Dictionary = data.get("window", {})
	if not window_data.has("x") or not window_data.has("y"):
		return default_position
	return Vector2i(int(window_data.get("x", default_position.x)), int(window_data.get("y", default_position.y)))


func capture_window_position(position: Vector2i) -> void:
	data["window"] = {
		"x": position.x,
		"y": position.y,
	}


func apply_to_pomodoro_state(state) -> void:
	var productivity: Dictionary = data.get("productivity", {})
	var pomodoro: Dictionary = productivity.get("pomodoro", {})
	state.apply_dict(pomodoro)


func capture_pomodoro_state(state) -> void:
	var productivity: Dictionary = data.get("productivity", {})
	productivity["pomodoro"] = state.to_dict()
	data["productivity"] = productivity


func apply_to_todo_state(state) -> void:
	var productivity: Dictionary = data.get("productivity", {})
	var todos: Array = productivity.get("todos", [])
	state.apply_array(todos)


func capture_todo_state(state) -> void:
	var productivity: Dictionary = data.get("productivity", {})
	productivity["todos"] = state.to_array()
	data["productivity"] = productivity


func get_control_panel_visible(default_visible: bool = false) -> bool:
	var ui: Dictionary = data.get("ui", {})
	return bool(ui.get("control_panel_visible", default_visible))


func capture_control_panel_visible(visible: bool) -> void:
	var ui: Dictionary = data.get("ui", {})
	ui["control_panel_visible"] = visible
	data["ui"] = ui


func apply_to_slot_state(state) -> void:
	var customization: Dictionary = data.get("customization", {})
	var slots: Dictionary = customization.get("slots", {})
	state.apply_dict(slots)


func capture_slot_state(state) -> void:
	var customization: Dictionary = data.get("customization", {})
	customization["slots"] = state.to_dict()
	data["customization"] = customization


func get_helper_endpoint(default_endpoint: String) -> String:
	var integration: Dictionary = data.get("integration", {})
	return str(integration.get("helper_endpoint", default_endpoint)).strip_edges()


func capture_helper_endpoint(endpoint: String) -> void:
	var integration: Dictionary = data.get("integration", {})
	integration["helper_endpoint"] = endpoint.strip_edges()
	data["integration"] = integration


func get_performance_mode(default_mode: StringName = &"balanced") -> StringName:
	var performance: Dictionary = data.get("performance", {})
	var mode := StringName(str(performance.get("mode", default_mode)))
	if mode != &"eco" and mode != &"quality":
		return &"balanced"
	return mode


func capture_performance_mode(mode: StringName) -> void:
	var performance: Dictionary = data.get("performance", {})
	performance["mode"] = str(mode)
	data["performance"] = performance


func _merge_dict(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		if typeof(target.get(key)) == TYPE_DICTIONARY and typeof(source[key]) == TYPE_DICTIONARY:
			_merge_dict(target[key], source[key])
		else:
			target[key] = source[key]
