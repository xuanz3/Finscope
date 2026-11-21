#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
app="${1:?Missing application bundle}"
test -d "$app"
work=$(mktemp -d "${TMPDIR:-/tmp}/finscope-dmg.XXXXXX")
trap 'rm -rf "$work"' EXIT
python3 -m venv "$work/venv"
"$work/venv/bin/python" -m pip install --disable-pip-version-check 'dmgbuild==1.6.7'
"$work/venv/bin/dmgbuild" -s scripts/dmg-settings.py -D "app=$app" FinScope "$work/FinScope-macOS.dmg"
hdiutil verify "$work/FinScope-macOS.dmg"
mkdir -p dist
mv -f "$work/FinScope-macOS.dmg" dist/FinScope-macOS.dmg
