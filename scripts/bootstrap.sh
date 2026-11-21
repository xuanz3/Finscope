#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
command -v flutter >/dev/null 2>&1 || { echo 'Flutter SDK not found. Install Flutter stable and add flutter to PATH: https://docs.flutter.dev/get-started/install'; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
flutter create --project-name finscope --org com.finscope --platforms=android,ios,macos,windows "$tmp/finscope"
for platform in android ios macos windows; do
  if [ ! -d "$platform" ]; then
    cp -R "$tmp/finscope/$platform" "$platform"
  fi
done
if [ ! -f .metadata ]; then cp "$tmp/finscope/.metadata" .metadata; fi
if [ -d macos/Runner ]; then
  python3 - <<'PYTHON'
import plistlib
from pathlib import Path
for file in Path('macos/Runner').glob('*.entitlements'):
    with file.open('rb') as f: data=plistlib.load(f)
    data['com.apple.security.files.user-selected.read-only']=True
        data['com.apple.security.network.client']=True
    with file.open('wb') as f: plistlib.dump(data,f)
file=Path('ios/Runner/Info.plist')
if file.exists():
    with file.open('rb') as f: data=plistlib.load(f)
    data['CADisableMinimumFrameDurationOnPhone']=True
    with file.open('wb') as f: plistlib.dump(data,f)
PYTHON
fi
python3 - <<'PYANDROID'
from pathlib import Path
p=Path('android/app/src/main/AndroidManifest.xml')
if p.exists():
    s=p.read_text()
    if 'android.permission.INTERNET' not in s:
        s=s.replace('<application','<uses-permission android:name="android.permission.INTERNET" />\n    <application',1)
        p.write_text(s)
PYANDROID
flutter pub get
