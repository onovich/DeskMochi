Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$godot = "D:\Godot\Godot_v4.6.1-stable_mono_win64\Godot_v4.6.1-stable_mono_win64_console.exe"
$runtimeDir = Join-Path $repoRoot ".godot_runtime"
$logDir = Join-Path $runtimeDir "logs"
$appDataDir = Join-Path $runtimeDir "appdata"
$scriptPath = Join-Path $runtimeDir "check_productivity_state.gd"
$logPath = Join-Path $logDir "check-productivity-state.log"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
New-Item -ItemType Directory -Force -Path $appDataDir | Out-Null

$env:APPDATA = $appDataDir
$env:LOCALAPPDATA = $appDataDir

$script = @'
extends SceneTree

const PomodoroState = preload("res://scripts/productivity/pomodoro_state.gd")
const TodoState = preload("res://scripts/productivity/todo_state.gd")

func _init() -> void:
	var pomodoro := PomodoroState.new()
	pomodoro.focus_seconds = 3.0
	pomodoro.remaining_seconds = 3.0
	pomodoro.start_or_pause()

	if not pomodoro.is_focus_running():
		push_error("Expected Pomodoro to enter running focus mode")
		quit(1)
		return

	var completed := pomodoro.step(3.2)
	if not completed or pomodoro.status != &"complete" or pomodoro.completed_cycles != 1:
		push_error("Expected Pomodoro to complete one cycle")
		quit(1)
		return

	var todos := TodoState.new()
	todos.add_item("first")
	todos.add_item("second")
	todos.toggle_item(2, true)
	todos.delete_item(1)

	if todos.items.size() != 1:
		push_error("Expected one remaining todo")
		quit(1)
		return
	if str(todos.items[0].get("text", "")) != "second" or not bool(todos.items[0].get("done", false)):
		push_error("Expected remaining todo to be completed second task")
		quit(1)
		return

	print("Productivity state OK")
	quit(0)
'@
[System.IO.File]::WriteAllText($scriptPath, $script, [System.Text.UTF8Encoding]::new($false))

& $godot --headless --path $repoRoot --log-file $logPath --script $scriptPath
if ($LASTEXITCODE -ne 0) {
  throw "Productivity state check failed with exit code $LASTEXITCODE."
}

$log = Get-Content -LiteralPath $logPath -Raw -ErrorAction SilentlyContinue
if ($log -match "SCRIPT ERROR|Parse Error|Compile Error|Failed to load script|Expected") {
  throw "Productivity state check log contains errors. See $logPath"
}
