extends RefCounted

var head_image_path := ""
var face_image_path := ""


func set_slot_path(slot_name: StringName, path: String) -> void:
	var trimmed := path.strip_edges()
	if slot_name == &"head":
		head_image_path = trimmed
	elif slot_name == &"face":
		face_image_path = trimmed


func get_slot_path(slot_name: StringName) -> String:
	if slot_name == &"head":
		return head_image_path
	if slot_name == &"face":
		return face_image_path
	return ""


func to_dict() -> Dictionary:
	return {
		"head_image_path": head_image_path,
		"face_image_path": face_image_path,
	}


func apply_dict(data: Dictionary) -> void:
	head_image_path = str(data.get("head_image_path", "")).strip_edges()
	face_image_path = str(data.get("face_image_path", "")).strip_edges()
