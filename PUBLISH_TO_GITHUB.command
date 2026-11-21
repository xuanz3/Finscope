#!/usr/bin/env bash
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
source_dir=$(cd "$(dirname "$0")" && pwd)
remote='https://github.com/xuanz3/Finscope.git'
branch="feature/studio-release-$(date +%Y%m%d-%H%M%S)"
cd "$source_dir"
flutter analyze --no-fatal-infos
flutter test
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
git clone "$remote" "$work/repo"
cd "$work/repo"
if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
 git switch -c main 2>/dev/null || git checkout --orphan main
 cp "$source_dir/README.md" .; cp "$source_dir/.gitignore" .
 git add README.md .gitignore; git commit -m 'docs: establish FinScope release scope'; git push -u origin main
fi
base=$(git branch --show-current)
git switch -c "$branch"
# Replace only owned source modules; preserve unrelated files and commit history.
for item in lib test docs scripts .github data; do mkdir -p "$item"; cp -R "$source_dir/$item/." "$item/"; done
for item in README.md pubspec.yaml analysis_options.yaml SETUP_AND_RUN.command PUBLISH_TO_GITHUB.command RUN_WINDOWS.ps1 .gitignore; do cp "$source_dir/$item" "$item"; done
if [[ -f "$source_dir/pubspec.lock" ]]; then cp "$source_dir/pubspec.lock" .; fi
git add -A
if git diff --cached --quiet; then echo 'No new changes'; exit 0; fi
git commit -m 'feat: integrate market terminal, research and release tooling'
git push -u origin "$branch"
if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
 gh pr create --repo xuanz3/Finscope --base "$base" --head "$branch" --title 'FinScope studio release candidate' --body 'Independent chart overlays, reference data ingestion, research and backtesting. Review CI and platform builds before merging.'
else
 echo "Open pull request: https://github.com/xuanz3/Finscope/compare/$base...$branch?expand=1"
fi
