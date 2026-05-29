Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$scripts = @(
	"tools\StartManualSmoke.ps1",
	"tools\StopManualSmoke.ps1"
)
$cmdScripts = @(
  "StartManualSmoke.cmd",
  "StopManualSmoke.cmd"
)

foreach ($relativePath in $scripts) {
  $path = Join-Path $repoRoot $relativePath
  $tokens = $null
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors) | Out-Null
  if ($errors -and $errors.Count -gt 0) {
    foreach ($parseError in $errors) {
      Write-Error "${relativePath}: $parseError"
    }
    throw "PowerShell parse errors in $relativePath"
  }
}

& (Join-Path $repoRoot "tools\StartManualSmoke.ps1") -SkipPreflight -NoHelper -WhatIf 2>$null

foreach ($relativePath in $cmdScripts) {
  $path = Join-Path $repoRoot $relativePath
  $content = Get-Content -LiteralPath $path -Raw
  if ($content -notmatch "powershell .*tools\\") {
    throw "Unexpected smoke command launcher content in $relativePath"
  }
}

Write-Host "Workflow script parse OK"
