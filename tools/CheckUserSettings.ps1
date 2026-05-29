Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$godot = "D:\Godot\Godot_v4.6.1-stable_mono_win64\Godot_v4.6.1-stable_mono_win64_console.exe"
$runtimeDir = Join-Path $repoRoot ".godot_runtime"
$logDir = Join-Path $runtimeDir "logs"
$appDataDir = Join-Path $runtimeDir "appdata"
$scriptPath = Join-Path $runtimeDir "check_user_settings.gd"
$logPath = Join-Path $logDir "check-user-settings.log"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
New-Item -ItemType Directory -Force -Path $appDataDir | Out-Null

$env:APPDATA = $appDataDir
$env:LOCALAPPDATA = $appDataDir

$script = @'
extends SceneTree

const UserSettings = preload("res://scripts/persistence/user_settings.gd")
const MochiState = preload("res://scripts/simulation/mochi_state.gd")
const PomodoroState = preload("res://scripts/productivity/pomodoro_state.gd")
const TodoState = preload("res://scripts/productivity/todo_state.gd")
const SlotState = preload("res://scripts/customization/slot_state.gd")

func _init() -> void:
	var settings := UserSettings.new()
	var state := MochiState.new()
	state.apply_tuning_preset(&"snappy")
	settings.capture_mochi_state(state)
	settings.capture_window_position(Vector2i(123, 456))

	var pomodoro := PomodoroState.new()
	pomodoro.start_or_pause()
	pomodoro.step(12.0)
	settings.capture_pomodoro_state(pomodoro)

	var todos := TodoState.new()
	todos.add_item("write smoke notes")
	todos.add_item("tune focus pose")
	todos.toggle_item(1, true)
	settings.capture_todo_state(todos)
	settings.capture_control_panel_visible(true)
	settings.capture_helper_endpoint("http://127.0.0.1:9999/events")
	settings.capture_performance_mode(&"eco")

	var slots := SlotState.new()
	slots.set_slot_path(&"head", "D:/DeskMochi/head.png")
	slots.set_slot_path(&"face", "D:/DeskMochi/face.png")
	settings.capture_slot_state(slots)
	settings.save()

	var loaded := UserSettings.new()
	loaded.load()
	var loaded_state := MochiState.new()
	loaded.apply_to_mochi_state(loaded_state)
	var loaded_position := loaded.get_window_position(Vector2i.ZERO)
	var loaded_pomodoro := PomodoroState.new()
	loaded.apply_to_pomodoro_state(loaded_pomodoro)
	var loaded_todos := TodoState.new()
	loaded.apply_to_todo_state(loaded_todos)
	var loaded_slots := SlotState.new()
	loaded.apply_to_slot_state(loaded_slots)

	if loaded_state.tuning_preset != &"snappy":
		push_error("Expected snappy preset, got %s" % loaded_state.tuning_preset)
		quit(1)
		return
	if loaded_position != Vector2i(123, 456):
		push_error("Expected saved window position, got %s" % loaded_position)
		quit(1)
		return
	if loaded_pomodoro.status != &"paused":
		push_error("Expected running pomodoro to restore as paused, got %s" % loaded_pomodoro.status)
		quit(1)
		return
	if loaded_todos.items.size() != 2 or not bool(loaded_todos.items[0].get("done", false)):
		push_error("Expected saved todo items to roundtrip")
		quit(1)
		return
	if not loaded.get_control_panel_visible(false):
		push_error("Expected control panel visibility to roundtrip")
		quit(1)
		return
	if loaded.get_helper_endpoint("") != "http://127.0.0.1:9999/events":
		push_error("Expected helper endpoint to roundtrip")
		quit(1)
		return
	if loaded.get_performance_mode() != &"eco":
		push_error("Expected performance mode to roundtrip")
		quit(1)
		return
	if loaded_slots.head_image_path != "D:/DeskMochi/head.png" or loaded_slots.face_image_path != "D:/DeskMochi/face.png":
		push_error("Expected slot paths to roundtrip")
		quit(1)
		return

	print("UserSettings roundtrip OK")
	quit(0)
'@
[System.IO.File]::WriteAllText($scriptPath, $script, [System.Text.UTF8Encoding]::new($false))

& $godot --headless --path $repoRoot --log-file $logPath --script $scriptPath
if ($LASTEXITCODE -ne 0) {
  throw "User settings check failed with exit code $LASTEXITCODE."
}

$log = Get-Content -LiteralPath $logPath -Raw -ErrorAction SilentlyContinue
if ($log -match "SCRIPT ERROR|Parse Error|Compile Error|Failed to load script|Expected") {
  throw "User settings check log contains errors. See $logPath"
}
