Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$godot = "D:\Godot\Godot_v4.6.1-stable_mono_win64\Godot_v4.6.1-stable_mono_win64_console.exe"
if (-not (Test-Path -LiteralPath $godot)) {
  throw "Godot console executable not found: $godot"
}

& $godot --version
if ($LASTEXITCODE -ne 0) {
  throw "Godot version check failed with exit code $LASTEXITCODE."
}
