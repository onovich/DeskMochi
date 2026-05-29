param(
  [switch]$SkipPreflight,
  [switch]$FullPreflight,
  [switch]$NoHelper,
  [switch]$DemoEvents,
  [switch]$WhatIf,
  [int]$HelperPort = 8765
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$statePath = Join-Path $repoRoot ".codex\manual-smoke-session.json"
$logDir = Join-Path $repoRoot ".godot_runtime\logs"
$manualAppData = Join-Path $repoRoot ".godot_runtime\manual-appdata"
$helperExe = Join-Path $repoRoot "helper\DeskMochi.Helper\bin\Debug\net10.0\DeskMochi.Helper.exe"
$godotGui = "D:\Godot\Godot_v4.6.1-stable_mono_win64\Godot_v4.6.1-stable_mono_win64.exe"
$godotConsole = "D:\Godot\Godot_v4.6.1-stable_mono_win64\Godot_v4.6.1-stable_mono_win64_console.exe"

if ($WhatIf) {
  Write-Host "StartManualSmoke parameter binding OK"
  return
}

if (Test-Path -LiteralPath $statePath) {
  throw "A manual smoke session already exists. Run tools\StopManualSmoke.ps1 first."
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $statePath), $logDir, $manualAppData | Out-Null

if (-not $SkipPreflight) {
  & (Join-Path $repoRoot "tools\RestoreHelper.ps1")
  & (Join-Path $repoRoot "tools\BuildHelper.ps1")

  if ($FullPreflight) {
    & (Join-Path $repoRoot "tools\EnvCheck.ps1")
    & (Join-Path $repoRoot "tools\ValidateGodot.ps1")
    & (Join-Path $repoRoot "tools\CheckUserSettings.ps1")
    & (Join-Path $repoRoot "tools\CheckProductivityState.ps1")
    & (Join-Path $repoRoot "tools\CheckHelperService.ps1")
  }
}

$processes = @()
$helperConfigPath = Join-Path $repoRoot ".codex\manual-smoke-helper.config.json"
$tokenLogPath = Join-Path $repoRoot ".codex\manual-smoke-token.log"
$godotLogPath = Join-Path $logDir "manual-smoke-godot.log"

if (-not $NoHelper) {
  if (-not (Test-Path -LiteralPath $helperExe)) {
    throw "Missing helper executable. Build failed or was skipped before helper exe existed: $helperExe"
  }

  [System.IO.File]::WriteAllText($tokenLogPath, "", [System.Text.UTF8Encoding]::new($false))
  $helperConfig = [ordered]@{
    port = $HelperPort
    keyboardEnabled = $true
    gitRepo = $repoRoot
    tokenLog = $tokenLogPath
    demoEvents = [bool]$DemoEvents
  }
  [System.IO.File]::WriteAllText($helperConfigPath, ($helperConfig | ConvertTo-Json -Depth 6), [System.Text.UTF8Encoding]::new($false))

  $helper = Start-Process -FilePath $helperExe -ArgumentList @("--config", $helperConfigPath) -WindowStyle Hidden -PassThru
  $processes += [ordered]@{
    name = "helper"
    pid = $helper.Id
    shutdown = "http"
    port = $HelperPort
  }
}

$godot = $godotGui
if (-not (Test-Path -LiteralPath $godot)) {
  $godot = $godotConsole
}
if (-not (Test-Path -LiteralPath $godot)) {
  throw "Godot executable not found."
}

$env:APPDATA = $manualAppData
$env:LOCALAPPDATA = $manualAppData
$godotProcess = Start-Process -FilePath $godot -ArgumentList @("--path", $repoRoot, "--log-file", $godotLogPath, "--", "--smoke-mode") -PassThru
$processes += [ordered]@{
  name = "godot"
  pid = $godotProcess.Id
  shutdown = "process"
}

$state = [ordered]@{
  startedAt = (Get-Date).ToString("o")
  repoRoot = $repoRoot
  godotLogPath = $godotLogPath
  helperConfigPath = $helperConfigPath
  tokenLogPath = $tokenLogPath
  helperPort = $HelperPort
  demoEvents = [bool]$DemoEvents
  processes = $processes
}
[System.IO.File]::WriteAllText($statePath, ($state | ConvertTo-Json -Depth 8), [System.Text.UTF8Encoding]::new($false))

Write-Host "DeskMochi manual smoke started."
Write-Host "State: $statePath"
Write-Host "Godot log: $godotLogPath"
Write-Host ""
Write-Host "Please observe:"
Write-Host "1. DeskMochi window appears, transparent and always on top."
Write-Host "2. Mochi body always receives poke/drag input immediately, with no cooldown."
Write-Host "3. F2 or the in-body ... button opens the panel."
Write-Host "4. Pomodoro is shortened to 15 seconds; ToDo, Head/Face image slots, Debug, and performance mode are usable."
if ($DemoEvents) {
  Write-Host "5. Demo helper events show text cues and trigger blue, purple, then green feedback within about 15 seconds."
} else {
  Write-Host "5. Type quickly, append token lines, or push Git to observe helper-driven feedback."
}
Write-Host ""
Write-Host "When finished, run: powershell -NoProfile -ExecutionPolicy Bypass -File tools\StopManualSmoke.ps1"
