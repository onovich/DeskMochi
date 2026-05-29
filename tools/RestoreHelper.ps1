Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$helperProject = Join-Path $repoRoot "helper\DeskMochi.Helper\DeskMochi.Helper.csproj"
$nugetConfig = Join-Path $repoRoot "NuGet.Config"
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

dotnet restore $helperProject --configfile $nugetConfig
if ($LASTEXITCODE -ne 0) {
  throw "DeskMochi helper restore failed with exit code $LASTEXITCODE."
}
