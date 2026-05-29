extends RefCounted

var items: Array[Dictionary] = []
var next_id := 1


func add_item(text: String) -> void:
	var trimmed := text.strip_edges()
	if trimmed.is_empty():
		return

	items.append({
		"id": next_id,
		"text": trimmed,
		"done": false,
	})
	next_id += 1


func toggle_item(id: int, done: bool) -> void:
	for index in items.size():
		if int(items[index].get("id", -1)) == id:
			items[index]["done"] = done
			return


func delete_item(id: int) -> void:
	for index in range(items.size() - 1, -1, -1):
		if int(items[index].get("id", -1)) == id:
			items.remove_at(index)
			return


func to_array() -> Array:
	var result := []
	for item in items:
		result.append({
			"id": int(item.get("id", 0)),
			"text": str(item.get("text", "")),
			"done": bool(item.get("done", false)),
		})
	return result


func apply_array(data: Array) -> void:
	items.clear()
	next_id = 1

	for raw_item in data:
		if typeof(raw_item) != TYPE_DICTIONARY:
			continue

		var id := maxi(1, int(raw_item.get("id", next_id)))
		var text := str(raw_item.get("text", "")).strip_edges()
		if text.is_empty():
			continue

		items.append({
			"id": id,
			"text": text,
			"done": bool(raw_item.get("done", false)),
		})
		next_id = maxi(next_id, id + 1)
