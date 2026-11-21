#!/usr/bin/env bash
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
repo=xuanz3/Finscope
tag=v1.0.0-rc.7
command -v gh >/dev/null || { echo 'Install GitHub CLI: brew install gh'; exit 1; }
gh auth status
# Verify merged launch code, not an obsolete PR.
gh api "repos/$repo/contents/site/index.html?ref=main" --jq .sha >/dev/null || { echo 'Merge the launch pull request first.'; exit 1; }
gh api "repos/$repo/contents/.github/workflows/packages.yml?ref=main" --jq .sha >/dev/null
if gh release view "$tag" --repo "$repo" >/dev/null 2>&1; then echo 'Release already exists. Review it on GitHub.'; else gh workflow run packages.yml --repo "$repo" --ref main -f tag="$tag"; fi
echo 'Review the package workflow, test artifacts, then publish the draft prerelease.'
echo 'Cloudflare Pages: GitHub repository xuanz3/Finscope, main branch, no framework, build command: exit 0, output directory: site.'
open "https://github.com/$repo/actions" || true
