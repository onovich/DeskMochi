Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$helperProject = Join-Path $repoRoot "helper\DeskMochi.Helper\DeskMochi.Helper.csproj"
$dotnetRuntime = Join-Path $repoRoot ".dotnet_runtime"
$dotnetHome = Join-Path $dotnetRuntime "home"
$appData = Join-Path $dotnetRuntime "appdata"
$packages = Join-Path $dotnetRuntime "packages"
New-Item -ItemType Directory -Force -Path $dotnetHome, $appData, $packages | Out-Null

$env:DOTNET_CLI_HOME = $dotnetHome
$env:APPDATA = $appData
$env:LOCALAPPDATA = $appData
$env:NUGET_PACKAGES = $packages
$env:DOTNET_NOLOGO = "1"
$env:DOTNET_CLI_TELEMETRY_OPTOUT = "1"
$env:DOTNET_SKIP_FIRST_TIME_EXPERIENCE = "1"

dotnet run --project $helperProject --no-build -- --self-test
if ($LASTEXITCODE -ne 0) {
  throw "DeskMochi helper self-test failed with exit code $LASTEXITCODE."
}

$port = 8766
$helperExe = Join-Path $repoRoot "helper\DeskMochi.Helper\bin\Debug\net10.0\DeskMochi.Helper.exe"
$process = Start-Process -FilePath $helperExe -ArgumentList @("--port", "$port") -WindowStyle Hidden -PassThru
try {
  $healthy = $false
  for ($i = 0; $i -lt 20; $i++) {
    try {
      $response = Invoke-WebRequest -Uri "http://127.0.0.1:$port/health" -UseBasicParsing -TimeoutSec 1
      if ($response.StatusCode -eq 200 -and $response.Content -match '"ok"\s*:\s*true') {
        $healthy = $true
        break
      }
    } catch {
      Start-Sleep -Milliseconds 200
    }
  }

  if (-not $healthy) {
    throw "DeskMochi helper health endpoint did not respond."
  }

  try {
    Invoke-WebRequest -Uri "http://127.0.0.1:$port/shutdown" -UseBasicParsing -TimeoutSec 1 | Out-Null
  } catch {
  }

  if (-not $process.WaitForExit(3000)) {
    throw "DeskMochi helper did not exit after shutdown request."
  }
} finally {
  if ($process -and -not $process.HasExited) {
    Stop-Process -Id $process.Id -Force
  }
}
