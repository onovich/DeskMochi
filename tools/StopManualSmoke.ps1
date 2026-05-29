Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$statePath = Join-Path $repoRoot ".codex\manual-smoke-session.json"

if (-not (Test-Path -LiteralPath $statePath)) {
  Write-Host "No manual smoke session state file found."
  return
}

$state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json

foreach ($processInfo in $state.processes) {
  $pidValue = [int]$processInfo.pid
  if ($processInfo.shutdown -eq "http" -and $processInfo.PSObject.Properties.Name -contains "port") {
    try {
      Invoke-WebRequest -Uri "http://127.0.0.1:$($processInfo.port)/shutdown" -UseBasicParsing -TimeoutSec 1 | Out-Null
      Start-Sleep -Milliseconds 500
    } catch {
    }
  }

  $process = Get-Process -Id $pidValue -ErrorAction SilentlyContinue
  if ($process -ne $null) {
    Stop-Process -Id $pidValue -Force
    Write-Host "Stopped $($processInfo.name) pid=$pidValue"
  }
}

Remove-Item -LiteralPath $statePath -Force
Write-Host "Manual smoke session stopped."
