#!/usr/bin/env bash
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
source_dir=$(cd "$(dirname "$0")" && pwd)
repo=xuanz3/Finscope
cd "$source_dir"
command -v gh >/dev/null || { echo 'Install GitHub CLI: brew install gh'; exit 1; }
gh auth status
flutter pub get
flutter analyze --no-fatal-infos
flutter test
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
gh repo clone "$repo" "$work/repo"
cd "$work/repo"
git switch main
git pull --ff-only
branch="feature/launch-$(date +%Y%m%d-%H%M%S)"
git switch -c "$branch"
commit_if_changed(){ if ! git diff --cached --quiet; then git commit -m "$1"; fi; }
copy_group(){ for item in "$@"; do if [[ -d "$source_dir/$item" ]]; then mkdir -p "$item"; cp -R "$source_dir/$item/." "$item/"; else mkdir -p "$(dirname "$item")"; cp "$source_dir/$item" "$item"; fi; git add -- "$item"; done; }
copy_group lib test assets pubspec.yaml analysis_options.yaml data
if [[ -f "$source_dir/pubspec.lock" ]]; then copy_group pubspec.lock; fi
commit_if_changed 'feat: integrate local workspace and official Finscope identity'
copy_group site
commit_if_changed 'feat(web): introduce interactive product and download experience'
copy_group scripts .github README.md docs .gitignore SETUP_AND_RUN.command PUBLISH_TO_GITHUB.command RELEASE_AFTER_MERGE.command PREVIEW_WEBSITE.command RUN_WINDOWS.ps1
if [[ -f .github/workflows/pages.yml ]]; then git rm -- .github/workflows/pages.yml; fi
commit_if_changed 'build: prepare platform installers and Cloudflare Pages deployment'
if git diff --quiet main HEAD; then echo 'No new changes to publish.'; exit 0; fi
git push -u origin "$branch"
pr=$(gh pr create --repo "$repo" --base main --head "$branch" --title 'Finscope RC5 — product launch' --body 'Official brand resources, local account experience, product website and platform release tooling. Review CI and smoke-test installers before publication. All commits retain actual timestamps.')
echo "Pull request: $pr"
echo 'Review and merge after CI passes. Then run RELEASE_AFTER_MERGE.command and connect Cloudflare Pages.'
open "$pr" || true
