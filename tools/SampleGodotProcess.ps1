Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$processes = @(Get-Process | Where-Object { $_.ProcessName -like "Godot*" })
if ($processes.Count -eq 0) {
  Write-Host "No Godot process is currently running."
  exit 0
}

$processes |
  Select-Object ProcessName, Id, CPU, WorkingSet64, PrivateMemorySize64 |
  Format-Table -AutoSize
