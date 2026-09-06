# Word Down ??

A blazing-fast, cross-platform, offline-first vocabulary and spaced-repetition learning application built with Flutter.

## ? Features

* **Offline-First Dictionary:** Instantly search through thousands of words with a fully offline, AES-encrypted SQLite database.
* **Studio-Quality Pronunciations:** Native integration with dictionary APIs for real human voice recordings (UK & US accents), backed by a custom Google TTS engine for dynamic sentences, quotes, and examples.
* **Spaced Repetition System (SRS):** Learn and master new vocabulary using a highly tuned spaced-repetition algorithm that tracks your progress over time.
* **Optimized Cloud Sync:** Seamlessly syncs your progress across Android and Windows devices using Firebase Firestore. Employs a custom "Single-Document Schema" to reduce database reads to exactly 1 operation per launch!
* **Secure Auth Gate:** Protected by Firebase Authentication. Only approved users can access the decryption keys to unlock the offline dictionary payload.
* **Cross-Platform:** Beautiful, responsive UI compiled natively for Windows (.exe) and Android (.apk).

## ?? Getting Started

### Prerequisites
* Flutter SDK (3.x)
* Firebase CLI
* (Windows) Visual Studio 2022 C++ Build Tools

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/YOUR_GITHUB_USERNAME/worddown.git
   cd worddown
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Building for Release

**Windows:**
```bash
flutter build windows --release
```
Your compiled executable will be located in `build\windows\x64\runner\Release\`.

**Android:**
```bash
flutter build apk --release
```
Your compiled APK will be located in `build\app\outputs\flutter-apk\app-release.apk`.

## ?? Security Notes
The raw dictionary database is AES-encrypted. To run this project locally, you must configure a Firebase project and store your `key` and `iv` in a Firestore document at `config/secrets`. The `android/upload-keystore.jks` and `key.properties` are explicitly gitignored for security.

## ?? License
This project is for personal use and learning.
