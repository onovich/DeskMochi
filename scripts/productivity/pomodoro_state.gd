extends RefCounted

const DEFAULT_FOCUS_SECONDS := 25.0 * 60.0

var focus_seconds := DEFAULT_FOCUS_SECONDS
var remaining_seconds := DEFAULT_FOCUS_SECONDS
var status := &"stopped"
var phase := &"focus"
var completed_cycles := 0


func step(delta: float) -> bool:
	if status != &"running":
		return false

	remaining_seconds = maxf(0.0, remaining_seconds - delta)
	if remaining_seconds > 0.0:
		return false

	status = &"complete"
	completed_cycles += 1
	return true


func start_or_pause() -> void:
	if status == &"running":
		status = &"paused"
		return

	if status == &"complete":
		reset()

	if remaining_seconds <= 0.0:
		remaining_seconds = focus_seconds

	status = &"running"


func reset() -> void:
	phase = &"focus"
	status = &"stopped"
	remaining_seconds = focus_seconds


func is_focus_running() -> bool:
	return phase == &"focus" and status == &"running"


func get_time_text() -> String:
	var total_seconds := ceili(remaining_seconds)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func get_status_text() -> String:
	if status == &"running":
		return "Focus running"
	if status == &"paused":
		return "Paused"
	if status == &"complete":
		return "Focus complete"
	return "Ready"


func to_dict() -> Dictionary:
	return {
		"focus_seconds": focus_seconds,
		"remaining_seconds": remaining_seconds,
		"status": str(status),
		"phase": str(phase),
		"completed_cycles": completed_cycles,
	}


func apply_dict(data: Dictionary) -> void:
	focus_seconds = maxf(60.0, float(data.get("focus_seconds", focus_seconds)))
	remaining_seconds = clampf(float(data.get("remaining_seconds", remaining_seconds)), 0.0, focus_seconds)
	status = StringName(str(data.get("status", status)))
	phase = StringName(str(data.get("phase", phase)))
	completed_cycles = maxi(0, int(data.get("completed_cycles", completed_cycles)))

	if status == &"running":
		status = &"paused"
	if status != &"stopped" and status != &"paused" and status != &"complete":
		status = &"stopped"
	if phase != &"focus":
		phase = &"focus"
