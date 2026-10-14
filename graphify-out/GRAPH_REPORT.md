# Graph Report - worddown  (2026-10-14)

## Corpus Check
- 102 files · ~148,629 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1260 nodes · 1546 edges · 64 communities (50 shown, 10 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `42d4b0d8`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Win32Window
- word_view_screen.dart
- GeneratedPluginRegistrant.swift
- 3. Core Architectural Subsystems
- progress_service.dart
- review_screen.dart
- sync_service.dart
- word.dart
- learning_session_screen.dart
- database_service.dart
- settings_service.dart
- my_application.cc
- wordup_api.dart
- home_screen.dart
- image_sync.py
- webview_windows_stub.dart
- wWinMain
- main.dart
- settings_screen.dart
- edge_tts_drm_test.dart
- manifest.json
- highlight_text.dart
- android-deployment.md
- encryption_service.dart
- server.js
- cache_manager_test.dart
- 🤖 Android Release Build & Deployment
- media_cache_service.dart
- @visibleForTesting
- cached_media_image.dart
- cache_healing_test.dart
- sync_merge_test.dart
- translation_service.dart
- LearningSessionScreen
- login_screen.dart
- package:flutter_test/flutter_test.dart
- package:flutter/material.dart
- WordUp Database & Media Sync Tracking
- PathProviderPlatform
- State
- review_question_service.dart
- app.js
- MaterialPageRoute
- word_list_screen.dart
- 1. Artifact Placement in `releases/`
- Stealth WordUp Database & Media Sync Invariant
- WordDown 📖
- WordDown Developer & Build Guide 🚀
- MainActivity.kt
- rules/graphify.md
- workflows/graphify.md
- LaunchImage.imageset/README.md
- 3. Singleton Services Layer (`lib/services/`)
- bool?
- String?
- _MeasureSize
- _MeasureSizeRenderObject
- docs/README.md
- WordDown System Architecture & Technical Specification
- edge_tts_service.dart

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 24 edges
2. `MessageHandler` - 12 edges
3. `FlutterWindow` - 10 edges
4. `Create` - 10 edges
5. `WndProc` - 10 edges
6. `MessageHandler` - 9 edges
7. `WordDown 📖` - 9 edges
8. `run_scrape()` - 8 edges
9. `_MyApplication` - 7 edges
10. `OnCreate` - 7 edges

## Surprising Connections (you probably didn't know these)
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `Win32Window::Win32Window()` --calls--> `Destroy`  [INFERRED]
  windows/runner/win32_window.cpp → windows/runner/win32_window.h
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  linux/runner/my_application.cc → linux/flutter/generated_plugin_registrant.cc
- `main()` --calls--> `my_application_new()`  [INFERRED]
  linux/runner/main.cc → linux/runner/my_application.cc
- `OnCreate` --calls--> `RegisterPlugins()`  [INFERRED]
  windows/runner/flutter_window.h → windows/flutter/generated_plugin_registrant.cc

## Import Cycles
- None detected.

## Communities (64 total, 10 thin omitted)

### Community 0 - "Win32Window"
Cohesion: 0.05
Nodes (57): PluginRegistry, RECT, unique_ptr, RegisterPlugins(), DartProject, HWND, LPARAM, LRESULT (+49 more)

### Community 1 - "word_view_screen.dart"
Cohesion: 0.02
Nodes (92): AnimationController, ChewieController?, _audioPlayer, bottomNavigationBarOverride, build, _buildAppBarTitle, _buildAudioBtn, _buildBottomActions (+84 more)

### Community 2 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (35): Any, audioplayers_darwin, cloud_firestore, Cocoa, firebase_auth, firebase_core, Flutter, FlutterAppDelegate (+27 more)

### Community 3 - "3. Core Architectural Subsystems"
Cohesion: 0.14
Nodes (14): 3.1. 11-Stage Spaced Repetition System (SRS), 3.2. Morphological Suffix & Stemming Engine (`HighlightText`), 3.3. Multi-Tier Content Acquisition & Caching Pipeline, 3.4. Dual-Engine Cross-Platform Media Pipeline, 3.5. Two-Way Asynchronous Cloud Synchronization, 3. Core Architectural Subsystems, Active Recall Interleaving Engine:, Android Mobile Pipeline: (+6 more)

### Community 4 - "progress_service.dart"
Cohesion: 0.03
Nodes (66): DateTime, DateTime? get, addKnownWordFromCloud, addPreferredImageFromCloud, addQueuedWordFromCloud, addWordToLearn, allProgress, clearAllPendingSync (+58 more)

### Community 5 - "review_screen.dart"
Cohesion: 0.04
Nodes (50): AudioPlayer, _activePreparedQuestion, _applyQuestion, _audioPlayer, _audioSequenceId, build, _buildAntonymQuestion, _buildCompareQuestion (+42 more)

### Community 6 - "sync_service.dart"
Cohesion: 0.06
Nodes (35): bool get, dart:async, FirebaseFirestore, _auth, FirebaseService, _firestore, getWordProgress, signInAnonymously (+27 more)

### Community 7 - "word.dart"
Cohesion: 0.04
Nodes (45): authorName, authorRole, _cleanWords, collocations, comparisons, compounds, de, description (+37 more)

### Community 8 - "learning_session_screen.dart"
Cohesion: 0.04
Nodes (53): _activePreparedQuestion, _audioPlayer, _audioSequenceId, build, _buildAntonymQuestion, _buildCompareQuestion, _buildContinueButton, _buildExampleQuestion (+45 more)

### Community 9 - "database_service.dart"
Cohesion: 0.04
Nodes (44): dart:math, encryption_service.dart, android, DefaultFirebaseOptions, web, windows, build, _buildStatColumn (+36 more)

### Community 10 - "settings_service.dart"
Cohesion: 0.06
Nodes (34): audioFocusMode, enableAntonymQuestion, enableCompareQuestion, enableEdgeTts, enableExampleQuestion, enableGoogleTts, enableMeaningQuestion, enableMisspellingQuestion (+26 more)

### Community 11 - "my_application.cc"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 12 - "wordup_api.dart"
Cohesion: 0.05
Nodes (37): Client, database_service.dart, edge_tts_service.dart, clearLocalCache, clearMemoryCache, _client, data, decode (+29 more)

### Community 13 - "home_screen.dart"
Cohesion: 0.06
Nodes (32): Color, FocusNode?, learning_session_screen.dart, _buildFilterChip, _buildSortChip, _buildStatCard, createState, _curriculumFilter (+24 more)

### Community 14 - "image_sync.py"
Cohesion: 0.07
Nodes (36): Connection, cors, express, node-fetch, dependencies, cors, express, node-fetch (+28 more)

### Community 15 - "webview_windows_stub.dart"
Cohesion: 0.12
Nodes (15): controller, dispose, executeScript, initialize, isInitialized, LoadingState, loadStringContent, loadUrl (+7 more)

### Community 16 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 17 - "main.dart"
Cohesion: 0.10
Nodes (20): AppLifecycleListener, dart:ui, firebase_options.dart, build, createState, dispose, _errorMessage, _initializeApp (+12 more)

### Community 18 - "settings_screen.dart"
Cohesion: 0.04
Nodes (45): int get, _buildCacheManagementCard, _buildCategoryRow, _buildLegendItem, _buildToggle, _cacheStats, _clearMedia, _clearPronunciations (+37 more)

### Community 19 - "edge_tts_drm_test.dart"
Cohesion: 0.03
Nodes (66): a, acc, aligned, bdata, byteData, _chromiumFullVersion, constants, _cs64Adjustment0 (+58 more)

### Community 20 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 21 - "highlight_text.dart"
Cohesion: 0.06
Nodes (36): int?, build, buildSpans, candidates, _computeSpans, _computeTokens, createState, didUpdateWidget (+28 more)

### Community 23 - "encryption_service.dart"
Cohesion: 0.12
Nodes (15): clearLocalStorage, decryptBytes, decryptFile, decryptString, EncryptionService, initialize, isInitialized, loadFromLocalStorage (+7 more)

### Community 24 - "server.js"
Cohesion: 0.22
Nodes (8): app, cors, db, dbPath, express, path, sqlite3, zlib

### Community 25 - "cache_manager_test.dart"
Cohesion: 0.25
Nodes (7): Directory, package:path_provider_platform_interface/path_provider_platform_interface.dart, package:word_down/services/cache_manager_service.dart, getApplicationDocumentsPath, getTemporaryPath, main, tempDir

### Community 26 - "🤖 Android Release Build & Deployment"
Cohesion: 0.22
Nodes (9): 1. Compile Android Release APK, 1. Firebase C++ SDK Invariant Check, 2. Compile Windows Release, 2. Package Android Release, 3. Building Release Binaries & Packaging Invariants, 3. Installing on a Connected Android Device (CRITICAL RULE), 3. Package Windows Release, 🤖 Android Release Build & Deployment (+1 more)

### Community 27 - "media_cache_service.dart"
Cohesion: 0.12
Nodes (16): _appDocsPath, cacheSingleMedia, cacheWordMedia, clearWordCache, ensureMediaCached, fetchAndDecryptFromHuggingFace, getAppDocsPath, _getFileNameFromUrl (+8 more)

### Community 28 - "@visibleForTesting"
Cohesion: 0.67
Nodes (3): @visibleForTesting, resetAppDocsPathForTesting, resetForTesting

### Community 29 - "cached_media_image.dart"
Cohesion: 0.11
Nodes (18): BoxFit?, double?, File?, build, CachedMediaImage, _CachedMediaImageState, _checkLocalCache, createState (+10 more)

### Community 30 - "cache_healing_test.dart"
Cohesion: 0.18
Nodes (10): main, dart:convert, dart:io, dart:typed_data, package:word_down/services/media_cache_service.dart, package:word_down/services/wordup_api.dart, getApplicationDocumentsPath, getTemporaryPath (+2 more)

### Community 31 - "sync_merge_test.dart"
Cohesion: 0.29
Nodes (6): package:word_down/services/progress_service.dart, getApplicationDocumentsPath, getApplicationSupportPath, getTemporaryPath, main, tempDir

### Community 32 - "translation_service.dart"
Cohesion: 0.17
Nodes (11): _ensurePrefs, _instance, _memoryCache, _prefs, translate, TranslationService, Map, package:http/http.dart (+3 more)

### Community 34 - "login_screen.dart"
Cohesion: 0.12
Nodes (16): FirebaseAuth, _auth, build, createState, _emailController, _errorMessage, _formatCleanError, initState (+8 more)

### Community 35 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.40
Nodes (4): package:flutter_test/flutter_test.dart, package:word_down/models/word.dart, package:word_down/widgets/highlight_text.dart, main

### Community 36 - "package:flutter/material.dart"
Cohesion: 0.50
Nodes (3): package:flutter/material.dart, package:word_down/main.dart, main

### Community 37 - "WordUp Database & Media Sync Tracking"
Cohesion: 0.33
Nodes (5): 1. Overview & Architecture, 2. Current Progress Snapshot, 3. How to Check Progress Remotely, Pipeline Stages per Run, WordUp Database & Media Sync Tracking

### Community 38 - "PathProviderPlatform"
Cohesion: 0.50
Nodes (4): PathProviderPlatform, FakePathProviderPlatform, FakePathProviderPlatform, FakePathProviderPlatform

### Community 47 - "State"
Cohesion: 0.18
Nodes (15): HomeScreen, _HomeScreenState, ReviewScreen, _ReviewScreenState, CompareWithSection, _CompareWithSectionState, SelectableImage, _SelectableImageState (+7 more)

### Community 48 - "review_question_service.dart"
Cohesion: 0.05
Nodes (39): _buildPreparedQuestion, _completedQuestions, _completedQuestionsByWord, _currentSessionQueue, currentVariant, currentVariantIndex, _deleteAudioFile, deleteExampleAudio (+31 more)

### Community 49 - "app.js"
Cohesion: 0.83
Nodes (3): fetchAndRenderWord(), loadCurrentWord(), renderRealData()

### Community 51 - "MaterialPageRoute"
Cohesion: 0.25
Nodes (8): build, _buildProgressTabs, _buildWordDetailsOverlay, _buildWordDetailsOverlay, build, _openWord, _onWordTap, MaterialPageRoute

### Community 52 - "word_list_screen.dart"
Cohesion: 0.20
Nodes (9): build, title, WordListScreen, words, List, ../services/database_service.dart, ../services/progress_service.dart, StatelessWidget (+1 more)

### Community 53 - "1. Artifact Placement in `releases/`"
Cohesion: 0.33
Nodes (5): 1. Artifact Placement in `releases/`, 2. Build Cache & Disk Space Reclaim Procedure, For Android Release Builds:, For Windows Release Builds:, Release Builds & Packaging Invariant

### Community 54 - "Stealth WordUp Database & Media Sync Invariant"
Cohesion: 0.50
Nodes (3): Stealth WordUp Database & Media Sync Invariant, Tracking & Checking Progress, Workflow Details

### Community 55 - "WordDown 📖"
Cohesion: 0.18
Nodes (11): 📱 Android Installation, 📸 App Preview, ✨ Core Features, 📚 Curated Word Packs, 📥 Download & Installation, 👩‍💻 For Developers & AI Models, 🚀 How to Learn with WordDown, *Intelligent, Multi-Modal English Vocabulary Acquisition* (+3 more)

### Community 56 - "WordDown Developer & Build Guide 🚀"
Cohesion: 0.20
Nodes (10): 1. Clone & Fetch Dependencies, 1. Prerequisites, 2. Configure Firebase (If Connecting Your Own Backend), 2. Quick Setup & Local Execution, 3. Run Locally in Debug Mode, 4. Build Cache & Disk Management, 5. Running Automated Tests, Platform-Specific Tools (+2 more)

### Community 66 - "3. Singleton Services Layer (`lib/services/`)"
Cohesion: 0.12
Nodes (16): 1. Directory Structure, 2. Core Domain Models (`lib/models/word.dart`), 3. Singleton Services Layer (`lib/services/`), 4. UI Components & Screen Navigation, 5. Developer Recipes (How to Extend WordDown), `DatabaseService` (`database_service.dart`), `HighlightText` Widget (`lib/widgets/highlight_text.dart`), `MediaCacheService` (`media_cache_service.dart`) (+8 more)

### Community 76 - "docs/README.md"
Cohesion: 0.36
Nodes (3): 📚 Documentation Index, 🧭 Fast Context for AI Models & New Developers, WordDown Technical Documentation 🛠️

### Community 78 - "WordDown System Architecture & Technical Specification"
Cohesion: 0.40
Nodes (5): 1. Executive Summary, 2. High-Level System Architecture, 4. Engineering Trade-offs & Design Decisions, 5. Security & Data Integrity, WordDown System Architecture & Technical Specification

### Community 79 - "edge_tts_service.dart"
Cohesion: 0.05
Nodes (41): _chromiumFullVersion, _chromiumMajorVersion, _cs64Adjustment0, _cs64Adjustment1, _cs64Coefficients, _cs64Digest, _cs64Factor, EdgeTtsService (+33 more)

## Knowledge Gaps
- **817 isolated node(s):** `main`, `DefaultFirebaseOptions`, `web`, `android`, `windows` (+812 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 958 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **10 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WebviewController` connect `webview_windows_stub.dart` to `word_view_screen.dart`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Why does `WordData` connect `word.dart` to `learning_session_screen.dart`, `word_view_screen.dart`, `review_question_service.dart`, `review_screen.dart`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **What connects `main`, `DefaultFirebaseOptions`, `web` to the rest of the system?**
  _817 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.05311676909569798 - nodes in this community are weakly interconnected._
- **Should `word_view_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.021505376344086023 - nodes in this community are weakly interconnected._
- **Should `GeneratedPluginRegistrant.swift` be split into smaller, more focused modules?**
  _Cohesion score 0.04846938775510204 - nodes in this community are weakly interconnected._
- **Should `3. Core Architectural Subsystems` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._