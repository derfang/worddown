# WordDown Developer & Build Guide 🚀

This document covers everything a software engineer or AI agent needs to set up the development environment, compile WordDown locally, and build production release artifacts for **Windows** and **Android**.

---

## 1. Prerequisites

### Universal Tools
- **Flutter SDK**: `^3.12.2` or later ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Dart SDK**: Bundled with Flutter
- **Git**: For source version control
- **Firebase CLI & FlutterFire**:
  ```bash
  npm install -g firebase-tools
  dart pub global activate flutterfire_cli
  ```

### Platform-Specific Tools
- **For Windows Desktop**:
  - Windows 10/11 64-bit
  - **Visual Studio 2022** with the **"Desktop development with C++"** workload enabled
  - Local **Firebase C++ SDK** (see section below)
- **For Android Mobile**:
  - Android Studio with Android SDK Platform 34+
  - Android SDK Command-line Tools and Platform-tools (`adb`)
  - A connected physical Android device with USB Debugging enabled, or an Android Emulator

---

## 2. Quick Setup & Local Execution

### 1. Clone & Fetch Dependencies
```powershell
git clone https://github.com/derfang/worddown.git
cd worddown
flutter pub get
```

### 2. Configure Firebase (If Connecting Your Own Backend)
```powershell
firebase login
flutterfire configure
```
*(Ensure Cloud Firestore and Firebase Authentication [Anonymous and Email/Password providers] are enabled in your Firebase console).*

### 3. Run Locally in Debug Mode
- **Windows**:
  ```powershell
  flutter run -d windows
  ```
- **Android**:
  ```powershell
  flutter run -d <device_id>
  ```

---

## 3. Building Release Binaries & Packaging Invariants

> [!IMPORTANT]
> Always follow the repository packaging invariants when generating production builds. Compiled artifacts must be archived into their respective platform folders under `releases/`.

### 🪟 Windows Release Build

#### 1. Firebase C++ SDK Invariant Check
Before compiling for Windows, CMake requires the local Firebase C++ SDK:
- Verify that `firebase_cpp_sdk_windows\include\firebase\version.h` exists in the project root.
- If not extracted, check if `firebase_cpp_sdk_windows_13.11.0.zip` exists in the root and extract it:
  ```powershell
  tar -xf firebase_cpp_sdk_windows_13.11.0.zip
  ```
- Set the environment variable pointing CMake to the SDK:
  ```powershell
  $env:FIREBASE_CPP_SDK_DIR = "$PWD\firebase_cpp_sdk_windows"
  ```

#### 2. Compile Windows Release
```powershell
flutter build windows --release
```

#### 3. Package Windows Release
Package the complete runner output into `releases/Windows/WordDown_Windows.zip`:
```powershell
New-Item -ItemType Directory -Force -Path "releases\Windows"
$dest = "releases\Windows\WordDown_Windows.zip"
if (Test-Path $dest) { Remove-Item $dest -Force }
Compress-Archive -Path "build\windows\x64\runner\Release\*" -DestinationPath $dest
```

---

### 🤖 Android Release Build & Deployment

#### 1. Compile Android Release APK
```powershell
flutter build apk --release
```

#### 2. Package Android Release
Copy and package the compiled APK into `releases/Android/`:
```powershell
New-Item -ItemType Directory -Force -Path "releases\Android"
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" -Destination "releases\Android\app-release.apk" -Force
Compress-Archive -Path "releases\Android\app-release.apk" -DestinationPath "releases\Android\WordDown_Android.zip" -Force
```

#### 3. Installing on a Connected Android Device (CRITICAL RULE)

> [!CAUTION]
> **DO NOT USE `flutter install`**:
> `flutter install` performs an uninstallation of the existing app before installing the new APK. This **permanently wipes** user login sessions, local SharedPreferences, and SQLite/offline caches.
>
> **ALWAYS USE in-place reinstall with `adb install -r`**:
> ```powershell
> adb -s <device_id> install -r build/app/outputs/flutter-apk/app-release.apk
> ```
> The `-r` flag performs an in-place upgrade, preserving all existing user accounts, databases, and configuration settings.

---

## 4. Build Cache & Disk Management

- **Do NOT automatically run `flutter clean`**: Preserving the `build/` cache ensures fast incremental compilations. Only execute `flutter clean` if you suspect build cache corruption or after major Flutter SDK upgrades.

---

## 5. Running Automated Tests

Run the test suite with:
```powershell
flutter test
```
To analyze codebase health and verify lint rules:
```powershell
flutter analyze
```
