$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
& .\scripts\bootstrap.ps1
flutter analyze --no-fatal-infos
if ($LASTEXITCODE -ne 0) { throw 'Analysis failed' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'Tests failed' }
flutter build windows --release
if ($LASTEXITCODE -ne 0) { throw 'Build failed' }
$compiler = Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'
if (-not (Test-Path $compiler)) { throw 'Install Inno Setup 6 to create the installer.' }
& $compiler scripts\windows.iss
if ($LASTEXITCODE -ne 0) { throw 'Installer build failed' }
