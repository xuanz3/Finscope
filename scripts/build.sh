#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/bootstrap.sh
flutter analyze --no-fatal-infos
flutter test
case "${1:-}" in
  macos) flutter build macos --release; mkdir -p dist; hdiutil create -volname FinScope -srcfolder build/macos/Build/Products/Release/finscope.app -ov -format UDZO dist/FinScope-macOS.dmg ;;
  android) flutter build apk --release; flutter build appbundle --release ;;
  ios) flutter build ios --release --no-codesign ;;
  *) echo 'Usage: scripts/build.sh macos|android|ios'; exit 1 ;;
esac
