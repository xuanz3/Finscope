# FinScope Experience RC4

- One level of primary navigation; context header and local account access.
- Original navigation glyphs, hover elevation, pressed feedback, crossfade/slide transitions, interpolated market values and chart arrival.
- Overview rotates available local symbols every eight seconds; selecting a symbol manually pauses rotation. Archive carousel rotates every seven seconds and supports manual navigation and pause. Reduced-motion preference disables automatic motion. No fabricated tick updates are made; observations remain labeled local/sample.
- Fifteen bundled editorial illustrations, optional curated photographic enhancement, and visual library.
- Local profile creation, avatar selection, simulated Google and phone options, simulated code flow, profile switching, sign-out, preferences, unlinking and deletion. Password verifier uses PBKDF2-HMAC-SHA256 with random salt and 120,000 iterations. No remote authentication, actual SMS, or secure multi-user isolation. Do not use real credentials. Market workspace remains shared on the device; local data are not encrypted.
- Data workspace now has dataset inventory, counts and functional import/download/backup/restore tiles.

## Validation
The source package was assembled and checked for ZIP integrity, shell syntax, and asset presence. Flutter SDK is not available in the build environment used to assemble the package. Flutter analysis, widget tests, actual app compilation, motion performance and device acceptance are NOT yet verified. Existing engine tests are retained, and local account tests are added. Review all checks and device layouts before merging a pull request.
