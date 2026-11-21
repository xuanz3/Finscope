$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Install Flutter stable and add flutter to PATH: https://docs.flutter.dev/get-started/install' }
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
try {
  flutter create --project-name finscope --org com.finscope --platforms=android,ios,macos,windows "$tmp/finscope"
  if ($LASTEXITCODE -ne 0) { throw 'Flutter create failed' }
  foreach ($platform in @('android','ios','macos','windows')) {
    if (-not (Test-Path $platform)) { Copy-Item "$tmp/finscope/$platform" $platform -Recurse }
  }
  if (-not (Test-Path '.metadata')) { Copy-Item "$tmp/finscope/.metadata" '.metadata' }
  flutter pub get
  if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed' }
} finally { if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force } }
