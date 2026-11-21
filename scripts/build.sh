#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/bootstrap.sh
flutter analyze --no-fatal-infos
flutter test
mkdir -p dist
case "${1:-}" in
 macos) flutter build macos --release; app=$(find build/macos/Build/Products/Release -maxdepth 1 -name '*.app' -print -quit); test -n "$app"; bash scripts/package-macos.sh "$app" ;;
 android) flutter build apk --release; cp build/app/outputs/flutter-apk/app-release.apk dist/Finscope-Android.apk ;;
 ios) flutter build ios --release --no-codesign ;;
 *) echo 'Usage: scripts/build.sh macos|android|ios'; exit 1 ;;
esac
