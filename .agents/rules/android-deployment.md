---
trigger: always_on
description: Guidelines for deploying and installing APKs onto connected Android devices without wiping user session or data.
---

## Android App Deployment & Installation

When installing or updating the WordDown app on a connected Android device:

- **DO NOT** use `flutter install`:
  `flutter install` uninstalls the application before installing the new APK, which wipes all SharedPreferences, local SQLite caches, and user authentication tokens (logging the user out).

- **DO** use in-place reinstall with `adb install -r`:
  After building the APK (`flutter build apk --release` or `--debug`), install it using:
  ```powershell
  adb -s <device_id> install -r build/app/outputs/flutter-apk/app-release.apk
  ```
  *(If `adb` is not directly on PATH, resolve it via Android SDK `platform-tools` or `flutter` device tooling).*
  The `-r` flag performs an in-place update, preserving existing user login sessions, local databases, and settings.
