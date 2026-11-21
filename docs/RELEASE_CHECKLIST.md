# Release gates

- [ ] `flutter pub get` and `flutter analyze` pass without warnings.
- [ ] `flutter test --coverage` passes, including replay, cash conservation, order execution, charts and SQLite restoration.
- [ ] Android APK/AAB, Windows installer, macOS DMG and iOS unsigned build successfully produced by their native jobs.
- [ ] Physical-device smoke tests on Windows, macOS, Android phone/tablet, iPhone and iPad: import CSV, trade, restart, restore workspace, resize, accessibility, keyboard/touch.
- [ ] Profile mode on 60 Hz and 120 Hz hardware; verify frame timing and memory with DevTools, especially rapid replay and 100k bar imports. Targets: 16.67ms and 8.33ms respectively; no performance result is currently certified.
- [ ] Confirm market data license, dependency licenses, brand assets, privacy disclosure and signing.
- [ ] Review platform-specific file chooser and clipboard restore; large datasets may require file-based export enhancement.
- [ ] Sign / notarize macOS, configure Windows code signing, Android release keys and iOS provisioning / TestFlight where applicable.
- [ ] After acceptance, merge PRs, tag using current real date, attach verified packages to GitHub release.
