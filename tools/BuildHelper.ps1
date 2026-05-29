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

dotnet build $helperProject --no-restore
if ($LASTEXITCODE -ne 0) {
  throw "DeskMochi helper build failed with exit code $LASTEXITCODE."
}
