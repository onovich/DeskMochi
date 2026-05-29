Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$godot = "D:\Godot\Godot_v4.6.1-stable_mono_win64\Godot_v4.6.1-stable_mono_win64_console.exe"
$logDir = Join-Path $repoRoot ".godot_runtime\logs"
$appDataDir = Join-Path $repoRoot ".godot_runtime\appdata"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
New-Item -ItemType Directory -Force -Path $appDataDir | Out-Null

$env:APPDATA = $appDataDir
$env:LOCALAPPDATA = $appDataDir

$logPath = Join-Path $logDir "godot-window.log"

& $godot --path $repoRoot --log-file $logPath --quit-after 30
if ($LASTEXITCODE -ne 0) {
  throw "Godot window smoke failed with exit code $LASTEXITCODE."
}

$log = Get-Content -LiteralPath $logPath -Raw -ErrorAction SilentlyContinue
if ($log -match "SCRIPT ERROR|Parse Error|Compile Error|Failed to load script") {
  throw "Godot window smoke log contains script errors. See $logPath"
}
