# FinScope release candidate 5

Project owner: Xuanze Chen.

## Local preview

Run `SETUP_AND_RUN.command` on macOS. It generates platform shells, installs the official icons, resolves dependencies, analyzes, tests, builds a local DMG, and opens the application. The site is independent: open `site/index.html`, or run `python3 -m http.server 8080 --directory site` for a local server. The interactive preview uses labelled sample data and is not a screenshot of the native app.

## Release sequence

1. Smoke-test macOS and the mobile layouts locally. No release assets are claimed built until the build succeeds.
2. Run `PUBLISH_TO_GITHUB.command`. It checks and tests the project, creates a new branch from current main, commits application, website and release tooling separately using genuine timestamps, pushes, then creates a PR. It does not force push or rewrite history. The earlier RC2 PR can be closed as superseded after reviewing the new PR.
3. Review the new PR and merge after passing CI. Run `RELEASE_AFTER_MERGE.command`. It starts the package build. Website deployment is handled independently by Cloudflare Pages.
4. The package workflow builds macOS, Windows, Android and checks iOS compilation. Only after all jobs succeed, it drafts a prerelease with three actual binary assets and SHA-256 checksums. Download and smoke-test each package before publishing. Do not publish if checks fail.
5. Publish the draft from GitHub Releases. The website queries public releases and exposes only present assets. It does not fabricate download progress or generate placeholder binaries. The website is deployed through Cloudflare Pages; see the configuration below.

## Signing and platform limitations

The CI workflow produces preview builds, not production-signed distribution. macOS notarization and Windows code signing require publisher credentials; Android needs a long-term production keystore before general distribution. Do not ask users to disable system security controls. iPhone/iPad require Apple signing and TestFlight/App Store distribution; an unsigned iOS compile check is not an installable IPA. No iOS download button is enabled. The first release should be identified as a preview and only released once verified.

The application uses local demo authentication, not OAuth or real SMS verification. Market data is historical/reference/sample only; no real trading or investment advice. Image credits remain in EDITORIAL_ASSETS.md. Author-supplied mark and app icon are used, with opaque Apple mobile derivatives and transparent macOS/Windows derivatives where supported.

## Cloudflare Pages deployment

Connect `xuanz3/Finscope` in Cloudflare Workers & Pages > Create application > Pages > Import an existing Git repository. Authorize access to the repository.

| Setting | Value |
|---|---|
| Project name | finscope (subject to availability) |
| Production branch | main |
| Framework preset | None |
| Root directory | repository root (leave blank) |
| Build command | `exit 0` |
| Build output directory | `site` |
| Environment variables | None required |

Cloudflare assigns the production hostname after deployment. Future changes merged into main deploy automatically. No GitHub Pages configuration or Cloudflare API credentials are required in the repository.

The download dialog reads the public GitHub Releases API and downloads the actual published assets using their `browser_download_url`. The expected asset names are `FinScope-macOS.dmg`, `FinScope-Windows-Setup.exe`, and `FinScope-Android.apk`. If no public release is available, download buttons remain disabled. A draft release must first be reviewed and published. No installers are committed to Git or hosted on Cloudflare Pages.
