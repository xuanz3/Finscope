# FinScope

**Market intelligence & historical trading simulation**  
Project owner: Xuanze Chen · Version 1.0.0-rc.2

FinScope is a local-first Flutter financial research workspace. It does not connect to a brokerage or execute real trades.

## Run on macOS

Extract this project into a new directory. With Flutter, Xcode and CocoaPods installed, double-click `SETUP_AND_RUN.command` (or execute `bash SETUP_AND_RUN.command` in Terminal). It generates platform runners, resolves dependencies, analyzes, runs the complete test suite, builds a release application, creates `dist/FinScope-macOS.dmg`, and launches the app. If a gate fails, it stops instead of distributing an unverified build. This archive does not contain precompiled binaries.

## Workspace

- Overview and markets: price tape, searchable symbol browser, watchlist, market breadth, screener, heatmap, responsive chart and instrument details.
- Charts: candlesticks, reference-rate line charts, SMA, EMA, Bollinger bands, zoom/pan, crosshair and two-point trend lines.
- Replay: next-observation execution, market/limit/stop orders for OHLC data, spreads, commissions, slippage, margin, protective stops, fill log, saved session.
- Portfolio: independent manually marked AUD transaction ledger, holdings and allocation.
- Research: return ranking, correlation matrix, historical event archive.
- Strategy Lab: configurable SMA long/flat backtest, equity curve and execution log, using the same simulation engine.
- Analytics, journal, data manager, SQLite storage and JSON backup/restore.

## Data integrity

The bundled sample series are synthetic and explicitly labeled. New workspaces use distinct deterministic sample series; previously saved sessions retain the original sample algorithm. In Data Manager, `Download ECB FX` retrieves official daily reference observations and derives currency crosses and AUD conversion rates. Source: [ECB Data Portal](https://data.ecb.europa.eu/help/api/data-examples). These are non-executable reference points, not daily OHLC quotes. Only market-order simulation is allowed for these datasets; a fill represents the following observation plus configured friction. For true OHLC, import authorized CSV files with the header `date,open,high,low,close,aud_per_quote`. No live feed, paywalled redistribution, or invented historical news is included.

## Distribution

GitHub Actions and scripts define macOS, Windows, Android and unsigned iOS build tasks. macOS DMG output is local and not notarized. iOS/iPadOS requires an Apple signing identity for installation on devices. Android release distribution requires production signing. Run platform QA on each target; frame-rate targets are 60/120 FPS, not measured claims.

## Verification status

This archive integrates the previous candidate and UI patches and adds new source and regression tests. Shell syntax, source delimiters and archive integrity were checked. Flutter SDK and platform toolchains are not available in the assembly environment, so Dart compilation, tests, ECB runtime download, visual review and device-specific package generation must run on the target machines/CI. This is a release candidate, not a certified production release. Live quotes, full news feeds, economic calendars, multi-window layouts, strategy optimization and advanced chart tools beyond those listed are not implemented.

## GitHub

`PUBLISH_TO_GITHUB.command` runs the quality gates before publishing a genuine feature branch to `xuanz3/Finscope`. It does not fabricate timestamps or automatically merge. Review the pull request and CI before merging. Keep user data and secrets outside the repository.
