#!/usr/bin/env bash
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
cd "$(dirname "$0")"
bash scripts/bootstrap.sh
flutter analyze --no-fatal-infos
flutter test
flutter build macos --release
app=$(find build/macos/Build/Products/Release -maxdepth 1 -name '*.app' -print -quit)
[[ -n "$app" ]] || { echo 'Build succeeded but app bundle not found.'; exit 1; }
mkdir -p dist
hdiutil create -volname FinScope -srcfolder "$app" -ov -format UDZO dist/FinScope-macOS.dmg
printf '\nBuilt package: %s/dist/FinScope-macOS.dmg\n' "$PWD"
open "$app"
