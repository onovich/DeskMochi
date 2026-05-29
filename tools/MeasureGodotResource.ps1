param(
  [int]$TimeoutSeconds = 18
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$godot = "D:\Godot\Godot_v4.6.1-stable_mono_win64\Godot_v4.6.1-stable_mono_win64_console.exe"
$runtimeDir = Join-Path $repoRoot ".godot_runtime"
$logDir = Join-Path $runtimeDir "logs"
$appDataDir = Join-Path $runtimeDir "appdata"
$resultsPath = Join-Path $repoRoot "docs\manual-smoke\results.md"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
New-Item -ItemType Directory -Force -Path $appDataDir | Out-Null

$env:APPDATA = $appDataDir
$env:LOCALAPPDATA = $appDataDir

function Invoke-Measurement {
  param(
    [string]$Name,
    [string[]]$ExtraArgs,
    [int]$QuitAfter
  )

  $logPath = Join-Path $logDir "measure-$Name.log"
  $args = @(
    "--path", $repoRoot,
    "--log-file", $logPath,
    "--quit-after", [string]$QuitAfter
  ) + $ExtraArgs

  $processInfo = [System.Diagnostics.ProcessStartInfo]::new()
  $processInfo.FileName = $godot
  $processInfo.WorkingDirectory = $repoRoot
  $processInfo.UseShellExecute = $false
  $processInfo.CreateNoWindow = $false
  $processInfo.Arguments = ($args | ForEach-Object {
    if ($_ -match '\s') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ }
  }) -join ' '
  $process = [System.Diagnostics.Process]::Start($processInfo)
  $samples = @()
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)

  try {
    while (-not $process.HasExited -and (Get-Date) -lt $deadline) {
      Start-Sleep -Milliseconds 500
      $process.Refresh()
      if (-not $process.HasExited) {
        $godotProcesses = @(Get-Process | Where-Object { $_.ProcessName -like "Godot*" })
        $samples += [pscustomobject]@{
          Time = Get-Date
          ProcessCount = $godotProcesses.Count
          CPU = ($godotProcesses | Measure-Object -Property CPU -Sum).Sum
          WorkingSet64 = ($godotProcesses | Measure-Object -Property WorkingSet64 -Sum).Sum
          PrivateMemorySize64 = ($godotProcesses | Measure-Object -Property PrivateMemorySize64 -Sum).Sum
        }
      }
    }

    if (-not $process.HasExited) {
      Stop-Process -Id $process.Id -Force
      throw "Measurement '$Name' exceeded timeout and was stopped."
    }
  } finally {
    if (-not $process.HasExited) {
      Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    }
  }

  $log = Get-Content -LiteralPath $logPath -Raw -ErrorAction SilentlyContinue
  if ($log -match "SCRIPT ERROR|Parse Error|Compile Error|Failed to load script") {
    throw "Measurement '$Name' log contains script errors. See $logPath"
  }

  if ($samples.Count -lt 2) {
    throw "Measurement '$Name' did not collect enough samples."
  }

  $first = $samples[0]
  $last = $samples[$samples.Count - 1]
  $elapsedSeconds = [Math]::Max(0.001, ($last.Time - $first.Time).TotalSeconds)
  $cpuDelta = [Math]::Max(0.0, [double]$last.CPU - [double]$first.CPU)
  $logicalProcessors = [Math]::Max(1, [Environment]::ProcessorCount)
  $averageCpuPercent = ($cpuDelta / $elapsedSeconds / $logicalProcessors) * 100.0
  $maxWorkingSet = ($samples | Measure-Object -Property WorkingSet64 -Maximum).Maximum
  $maxPrivateMemory = ($samples | Measure-Object -Property PrivateMemorySize64 -Maximum).Maximum

  return [pscustomobject]@{
    Name = $Name
    Samples = $samples.Count
    MaxProcessCount = ($samples | Measure-Object -Property ProcessCount -Maximum).Maximum
    ElapsedSeconds = [Math]::Round($elapsedSeconds, 2)
    AverageCpuPercent = [Math]::Round($averageCpuPercent, 2)
    MaxWorkingSetMB = [Math]::Round($maxWorkingSet / 1MB, 1)
    MaxPrivateMemoryMB = [Math]::Round($maxPrivateMemory / 1MB, 1)
  }
}

$idle = Invoke-Measurement -Name "idle" -ExtraArgs @() -QuitAfter 360
$active = Invoke-Measurement -Name "active-demo" -ExtraArgs @("--", "--demo-motion") -QuitAfter 720
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"

$table = @"
| Mode | Samples | Processes | Seconds | Avg CPU % | Max Working Set MB | Max Private MB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| $($idle.Name) | $($idle.Samples) | $($idle.MaxProcessCount) | $($idle.ElapsedSeconds) | $($idle.AverageCpuPercent) | $($idle.MaxWorkingSetMB) | $($idle.MaxPrivateMemoryMB) |
| $($active.Name) | $($active.Samples) | $($active.MaxProcessCount) | $($active.ElapsedSeconds) | $($active.AverageCpuPercent) | $($active.MaxWorkingSetMB) | $($active.MaxPrivateMemoryMB) |
"@

$content = Get-Content -LiteralPath $resultsPath -Raw
$replacement = @"
Status: measured automatically at $timestamp.

$table
"@
$content = [regex]::Replace($content, '(?s)Status: (not yet measured|measured automatically).*$', $replacement.TrimEnd())
[System.IO.File]::WriteAllText($resultsPath, $content, [System.Text.UTF8Encoding]::new($false))

Write-Host $table
