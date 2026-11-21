$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
& .\scripts\bootstrap.ps1
flutter analyze --no-fatal-infos
if ($LASTEXITCODE -ne 0) { throw 'Analysis failed' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'Tests failed' }
flutter run -d windows
