---
trigger: always_on
description: Procedures for compiling, packaging, and storing release artifacts in the releases folder for Android and Windows.
---

## Release Builds & Packaging Invariant

Whenever building release artifacts for the WordDown app:

### 1. Artifact Placement in `releases/`
Always copy and package the compiled release binaries into their respective platform subdirectories in `releases/`. If only one platform is built, only update that platform's release folder.

#### For Android Release Builds:
After running `flutter build apk --release`:
1. Ensure `releases/Android/` exists.
2. Copy the APK:
   ```powershell
   Copy-Item "build\app\outputs\flutter-apk\app-release.apk" -Destination "releases\Android\app-release.apk" -Force
   ```
3. Create the compressed ZIP bundle:
   ```powershell
   Compress-Archive -Path "releases\Android\app-release.apk" -DestinationPath "releases\Android\WordDown_Android.zip" -Force
   ```

#### For Windows Release Builds:
1. **Local Firebase SDK Verification & Warning**:
   - Before compiling for Windows, verify that the local Firebase C++ SDK is available:
     - Check if the extracted directory `firebase_cpp_sdk_windows\include\firebase\version.h` exists.
     - If not, check if `firebase_cpp_sdk_windows_13.11.0.zip` exists in the project root and extract it (`tar -xf firebase_cpp_sdk_windows_13.11.0.zip`).
     - **If neither exists**: **STOP immediately and WARN the user** that the Windows build will fail with a CMake 404 download error, and request that they place `firebase_cpp_sdk_windows_13.11.0.zip` in the project root.
   - Always point CMake to the local extracted SDK:
     ```powershell
     $env:FIREBASE_CPP_SDK_DIR = "$PWD\firebase_cpp_sdk_windows"
     flutter build windows --release
     ```
2. Ensure `releases/Windows/` exists.
3. Package the complete release folder into `releases\Windows\WordDown_Windows.zip`:
   ```powershell
   $dest = "releases\Windows\WordDown_Windows.zip"
   if (Test-Path $dest) { Remove-Item $dest -Force }
   Compress-Archive -Path "build\windows\x64\runner\Release\*" -DestinationPath $dest
   ```

### 2. Build Cache & Disk Management
- Do **not** automatically run `flutter clean` after builds unless explicitly requested by the user. Preserving the `build/` cache allows for fast incremental compilations.
