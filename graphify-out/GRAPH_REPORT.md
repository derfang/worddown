# Graph Report - worddown  (2026-10-11)

## Corpus Check
- 101 files · ~144,321 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1169 nodes · 1447 edges · 60 communities (46 shown, 10 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `d7a5fbf5`
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
- stealth_sync.py
- webview_windows_stub.dart
- wWinMain
- main.dart
- settings_screen.dart
- image_sync.py
- manifest.json
- highlight_text.dart
- android-deployment.md
- encryption_service.dart
- server.js
- package:flutter/material.dart
- 3. Singleton Services Layer (`lib/services/`)
- media_cache_service.dart
- @visibleForTesting
- cached_media_image.dart
- dart:convert
- translation_service.dart
- LearningSessionScreen
- login_screen.dart
- WordUp Database & Media Sync Tracking
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
- WordDown Codebase Map & Technical Reference 🗺️
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

## Communities (60 total, 10 thin omitted)

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
Nodes (34): bool get, FirebaseFirestore, _auth, FirebaseService, _firestore, getWordProgress, signInAnonymously, syncWordProgress (+26 more)

### Community 7 - "word.dart"
Cohesion: 0.04
Nodes (45): authorName, authorRole, _cleanWords, collocations, comparisons, compounds, de, description (+37 more)

### Community 8 - "learning_session_screen.dart"
Cohesion: 0.04
Nodes (52): _activePreparedQuestion, _audioPlayer, _audioSequenceId, build, _buildAntonymQuestion, _buildCompareQuestion, _buildContinueButton, _buildExampleQuestion (+44 more)

### Community 9 - "database_service.dart"
Cohesion: 0.05
Nodes (43): encryption_service.dart, android, DefaultFirebaseOptions, web, windows, build, _buildStatColumn, createState (+35 more)

### Community 10 - "settings_service.dart"
Cohesion: 0.06
Nodes (34): audioFocusMode, enableAntonymQuestion, enableCompareQuestion, enableEdgeTts, enableExampleQuestion, enableGoogleTts, enableMeaningQuestion, enableMisspellingQuestion (+26 more)

### Community 11 - "my_application.cc"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 12 - "wordup_api.dart"
Cohesion: 0.05
Nodes (36): Client, database_service.dart, edge_tts_service.dart, clearLocalCache, clearMemoryCache, _client, data, decode (+28 more)

### Community 13 - "home_screen.dart"
Cohesion: 0.06
Nodes (32): Color, FocusNode?, learning_session_screen.dart, _buildFilterChip, _buildSortChip, _buildStatCard, createState, _curriculumFilter (+24 more)

### Community 14 - "stealth_sync.py"
Cohesion: 0.10
Nodes (22): Connection, cors, express, node-fetch, dependencies, cors, express, node-fetch (+14 more)

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

### Community 19 - "image_sync.py"
Cohesion: 0.22
Nodes (14): compute_hf_path(), encrypt_bytes(), extract_image_urls(), fetch_url_bytes(), _load_key_iv(), main(), Returns True only when the JSON payload is structurally sound. All checks are…, Returns a list of dicts describing every image associated with this word. Each… (+6 more)

### Community 20 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 21 - "highlight_text.dart"
Cohesion: 0.06
Nodes (36): int?, build, buildSpans, candidates, _computeSpans, _computeTokens, createState, didUpdateWidget (+28 more)

### Community 23 - "encryption_service.dart"
Cohesion: 0.13
Nodes (14): clearLocalStorage, decryptBytes, decryptFile, decryptString, EncryptionService, initialize, isInitialized, loadFromLocalStorage (+6 more)

### Community 24 - "server.js"
Cohesion: 0.22
Nodes (8): app, cors, db, dbPath, express, path, sqlite3, zlib

### Community 25 - "package:flutter/material.dart"
Cohesion: 0.07
Nodes (30): Directory, package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:path_provider_platform_interface/path_provider_platform_interface.dart, package:word_down/main.dart, package:word_down/models/word.dart, package:word_down/services/cache_manager_service.dart, package:word_down/services/media_cache_service.dart (+22 more)

### Community 26 - "3. Singleton Services Layer (`lib/services/`)"
Cohesion: 0.29
Nodes (7): 3. Singleton Services Layer (`lib/services/`), `DatabaseService` (`database_service.dart`), `MediaCacheService` (`media_cache_service.dart`), `ProgressService` (`progress_service.dart`), `SettingsService` (`settings_service.dart`), `SyncService` (`sync_service.dart`), `WordupApi` (`wordup_api.dart`)

### Community 27 - "media_cache_service.dart"
Cohesion: 0.12
Nodes (16): _appDocsPath, cacheSingleMedia, cacheWordMedia, clearWordCache, ensureMediaCached, fetchAndDecryptFromHuggingFace, getAppDocsPath, _getFileNameFromUrl (+8 more)

### Community 28 - "@visibleForTesting"
Cohesion: 0.67
Nodes (3): @visibleForTesting, resetAppDocsPathForTesting, resetForTesting

### Community 29 - "cached_media_image.dart"
Cohesion: 0.11
Nodes (18): BoxFit?, double?, File?, build, CachedMediaImage, _CachedMediaImageState, _checkLocalCache, createState (+10 more)

### Community 30 - "dart:convert"
Cohesion: 0.40
Nodes (4): main, dart:convert, dart:io, dart:typed_data

### Community 32 - "translation_service.dart"
Cohesion: 0.15
Nodes (12): _ensurePrefs, _instance, _memoryCache, _prefs, translate, TranslationService, Map, package:http/http.dart (+4 more)

### Community 34 - "login_screen.dart"
Cohesion: 0.12
Nodes (16): FirebaseAuth, _auth, build, createState, _emailController, _errorMessage, _formatCleanError, initState (+8 more)

### Community 37 - "WordUp Database & Media Sync Tracking"
Cohesion: 0.33
Nodes (5): 1. Overview & Architecture, 2. Current Progress Snapshot, 3. How to Check Progress Remotely, Pipeline Stages per Run, WordUp Database & Media Sync Tracking

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
Cohesion: 0.11
Nodes (19): 1. Clone & Fetch Dependencies, 1. Compile Android Release APK, 1. Firebase C++ SDK Invariant Check, 1. Prerequisites, 2. Compile Windows Release, 2. Configure Firebase (If Connecting Your Own Backend), 2. Package Android Release, 2. Quick Setup & Local Execution (+11 more)

### Community 66 - "WordDown Codebase Map & Technical Reference 🗺️"
Cohesion: 0.22
Nodes (9): 1. Directory Structure, 2. Core Domain Models (`lib/models/word.dart`), 4. UI Components & Screen Navigation, 5. Developer Recipes (How to Extend WordDown), `HighlightText` Widget (`lib/widgets/highlight_text.dart`), Recipe 1: Adding a New Curriculum List, Recipe 2: Adding a New Question Type to `ReviewScreen`, Recipe 3: Adjusting Spaced Repetition (SRS) Intervals (+1 more)

### Community 76 - "docs/README.md"
Cohesion: 0.36
Nodes (3): 📚 Documentation Index, 🧭 Fast Context for AI Models & New Developers, WordDown Technical Documentation 🛠️

### Community 78 - "WordDown System Architecture & Technical Specification"
Cohesion: 0.40
Nodes (5): 1. Executive Summary, 2. High-Level System Architecture, 4. Engineering Trade-offs & Design Decisions, 5. Security & Data Integrity, WordDown System Architecture & Technical Specification

### Community 79 - "edge_tts_service.dart"
Cohesion: 0.09
Nodes (21): dart:async, dart:math, _chromiumFullVersion, _chromiumMajorVersion, EdgeTtsService, _escapeXml, _generateMuid, _generateSecMsGec (+13 more)

## Knowledge Gaps
- **727 isolated node(s):** `main`, `DefaultFirebaseOptions`, `web`, `android`, `windows` (+722 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 869 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **10 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WebviewController` connect `webview_windows_stub.dart` to `word_view_screen.dart`?**
  _High betweenness centrality (0.024) - this node is a cross-community bridge._
- **Why does `WordData` connect `word.dart` to `learning_session_screen.dart`, `word_view_screen.dart`, `review_question_service.dart`, `review_screen.dart`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **What connects `main`, `DefaultFirebaseOptions`, `web` to the rest of the system?**
  _727 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.05311676909569798 - nodes in this community are weakly interconnected._
- **Should `word_view_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.021505376344086023 - nodes in this community are weakly interconnected._
- **Should `GeneratedPluginRegistrant.swift` be split into smaller, more focused modules?**
  _Cohesion score 0.04846938775510204 - nodes in this community are weakly interconnected._
- **Should `3. Core Architectural Subsystems` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._