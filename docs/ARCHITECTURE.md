# Architecture

- `lib/core`: candle validation and viewport, replay, deterministic simulation accounting, portfolio book and SQLite storage.
- `lib/design_system`: colors, motion tokens and reusable styles.
- `lib/widgets`: chart painters and interactive primitives.
- `lib/features`: adaptive workspace and persisted application model.
- `test`: unit and widget tests.
- `scripts`: native bootstrap, package generation and guarded Git publishing.

Persistence uses a versioned SQLite key/value workspace snapshot and replay action log. Imports are immutable within a session. The app does not require cloud services; all stored data remains local unless the user explicitly exports or publishes source files. Future-bar access is prevented in replay UI and execution timing; the separate market browser can reveal the full imported series, so this is not a locked anti-cheat environment.
