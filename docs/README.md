# WordDown Technical Documentation 🛠️

Welcome to the **WordDown** developer and technical documentation hub. This directory provides comprehensive architectural guides, development specifications, and codebase maps tailored for **software engineers, open-source contributors, and AI pair-programming agents** (such as Antigravity, Claude, Cursor, Copilot, and Gemini).

---

## 📚 Documentation Index

| Document | Target Audience | What It Covers |
|:---|:---|:---|
| **[Architecture Specification](ARCHITECTURE.md)** | Architects, Engineers, AI | Layered service architecture, 11-stage Spaced Repetition (SRS) state machine, multi-tier caching pipeline, cross-platform video player abstractions, and cloud sync protocol. |
| **[Developer & Build Guide](DEVELOPER_GUIDE.md)** | Developers, DevOps | Setting up Flutter, building for Windows & Android, Firebase setup, local release packaging invariants, and installation commands (`adb install -r`). |
| **[Codebase Map & Recipes](CODEBASE_MAP.md)** | Feature Devs, AI Models | File-by-file directory inventory, data models, service singletons, screen navigation flows, morphological regex stemmer details, and copy-paste recipes for extending the app. |

---

## 🧭 Fast Context for AI Models & New Developers

When working on this repository, keep the following core invariants in mind:

1. **Architecture Style**: Layered Service Architecture. UI screens (`lib/screens/`) communicate with domain services (`lib/services/`), which manage state and interact with models (`lib/models/`) and data storage.
2. **Offline-First Resilience**: All word dictionary indices (50,000+ words in `assets/word_dictionary.json`) are loaded into memory at startup with $O(1)$ key lookups. Local user progress is stored locally in JSON files in the app documents directory and synchronizes asynchronously with Firebase Firestore.
3. **Cross-Platform Media Strategy**:
   - **Windows**: Uses `webview_windows` (Chromium WebView2) with stream extraction and DOM script injection.
   - **Android / Non-Windows**: Uses `video_player` + `chewie` (ExoPlayer) with native H.264 stream extraction via `youtube_explode_dart`.
   - **Platform Isolation**: Uses conditional Dart imports with `stubs/webview_windows_stub.dart` to prevent Windows C++ bindings from leaking into mobile builds.
4. **Spaced Repetition System (SRS)**: Managed by `ProgressService`. Follows an 11-step exponential interval ladder from 0 days to 365 days, culminating in mastery.
5. **Android Deployment Rule**: Never execute `flutter install` (it uninstalls the app and wipes local SQLite/SharedPreferences databases). Always use `adb install -r <apk>` for in-place updates.
6. **Release Packaging Rule**: Release artifacts must be packaged into `releases/Android/` and `releases/Windows/` as documented in [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md).
