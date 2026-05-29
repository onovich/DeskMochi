Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$godot = "D:\Godot\Godot_v4.6.1-stable_mono_win64\Godot_v4.6.1-stable_mono_win64_console.exe"
$exportPresets = Join-Path $repoRoot "export_presets.cfg"

if (-not (Test-Path -LiteralPath $exportPresets)) {
  throw "Missing export_presets.cfg."
}

$version = & $godot --version
if ($LASTEXITCODE -ne 0) {
  throw "Could not query Godot version."
}

if ($version -notmatch "4\.6\.1") {
  throw "Expected Godot 4.6.1, got $version"
}

$templateRoot = Join-Path $env:APPDATA "Godot\export_templates"
$templateCandidates = @(
  (Join-Path $templateRoot "4.6.1.stable.mono"),
  (Join-Path $templateRoot "4.6.1.stable")
)
$templateFound = $false
foreach ($candidate in $templateCandidates) {
  if (Test-Path -LiteralPath $candidate) {
    $templateFound = $true
    break
  }
}

if ($templateFound) {
  Write-Host "Godot export templates found."
} else {
  Write-Host "Godot export templates not found; Windows export will need template installation before packaging."
}

Write-Host "Export readiness check OK"
