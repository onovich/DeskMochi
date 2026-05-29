extends HTTPRequest

signal events_received(events: Array)

const DEFAULT_ENDPOINT := "http://127.0.0.1:8765/events"
const POLL_SECONDS := 2.0
const RETRY_SECONDS := 6.0

var endpoint := DEFAULT_ENDPOINT
var enabled := true
var _last_id := 0
var _timer := 0.5
var _request_active := false


func _ready() -> void:
	timeout = 1.0
	request_completed.connect(_on_request_completed)


func _process(delta: float) -> void:
	if not enabled or _request_active:
		return

	_timer -= delta
	if _timer <= 0.0:
		_request_events()


func _request_events() -> void:
	_request_active = true
	var separator := "?" if not endpoint.contains("?") else "&"
	var error := request("%s%slast_id=%d" % [endpoint, separator, _last_id])
	if error != OK:
		_request_active = false
		_timer = RETRY_SECONDS


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_request_active = false
	if result != RESULT_SUCCESS or response_code != 200:
		_timer = RETRY_SECONDS
		return

	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		_timer = RETRY_SECONDS
		return

	var events: Array = parsed.get("events", [])
	for raw_event in events:
		if typeof(raw_event) != TYPE_DICTIONARY:
			continue
		_last_id = maxi(_last_id, int(raw_event.get("id", _last_id)))

	if not events.is_empty():
		events_received.emit(events)

	_timer = POLL_SECONDS
