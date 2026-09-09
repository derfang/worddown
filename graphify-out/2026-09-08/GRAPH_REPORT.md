# Graph Report - worddown  (2026-09-08)

## Corpus Check
- 120 files · ~137,559 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1021 nodes · 1249 edges · 65 communities (49 shown, 10 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `527cef8b`
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
- package.json
- webview_windows_stub.dart
- wWinMain
- State
- sync_status_screen.dart
- interceptor/package.json
- manifest.json
- highlight_text.dart
- test_html.dart
- fetch_jester.dart
- server.js
- firebase_service.dart
- main.dart
- check_current.dart
- test_json.dart
- firebase_options.dart
- settings_screen.dart
- word_list_screen.dart
- package:http/http.dart
- apply_reset.dart
- test_audio.dart
- HomeScreen
- analyze_json.dart
- ReviewScreen
- dart:io
- process_ranking.dart
- login_screen.dart
- analyze_list2.dart
- analyze_local.dart
- analyze_progress.dart
- fix_progress.dart
- app.js
- MaterialPageRoute
- dart:convert
- Word Down 📖
- index.js
- MainActivity.kt
- rules/graphify.md
- workflows/graphify.md
- LaunchImage.imageset/README.md
- bool?
- String?
- _MeasureSize
- _MeasureSizeRenderObject
- edge_tts_service.dart

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 24 edges
2. `MessageHandler` - 12 edges
3. `FlutterWindow` - 10 edges
4. `Create` - 10 edges
5. `WndProc` - 10 edges
6. `MessageHandler` - 9 edges
7. `_MyApplication` - 7 edges
8. `OnCreate` - 7 edges
9. `WindowClassRegistrar` - 7 edges
10. `Destroy` - 7 edges

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

## Communities (65 total, 10 thin omitted)

### Community 0 - "Win32Window"
Cohesion: 0.05
Nodes (57): PluginRegistry, RECT, unique_ptr, RegisterPlugins(), DartProject, HWND, LPARAM, LRESULT (+49 more)

### Community 1 - "word_view_screen.dart"
Cohesion: 0.02
Nodes (92): AnimationController, BoxFit, ChewieController?, double?, File?, _audioPlayer, bottomNavigationBarOverride, build (+84 more)

### Community 2 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (35): Any, audioplayers_darwin, cloud_firestore, Cocoa, firebase_auth, firebase_core, Flutter, FlutterAppDelegate (+27 more)

### Community 3 - "3. Core Architectural Subsystems"
Cohesion: 0.10
Nodes (19): 1. Executive Summary, 2. High-Level System Architecture, 3.1. 11-Stage Spaced Repetition System (SRS), 3.2. Morphological Suffix & Stemming Engine (`HighlightText`), 3.3. Multi-Tier Content Acquisition & Caching Pipeline, 3.4. Dual-Engine Cross-Platform Media Pipeline, 3.5. Two-Way Asynchronous Cloud Synchronization, 3. Core Architectural Subsystems (+11 more)

### Community 4 - "progress_service.dart"
Cohesion: 0.04
Nodes (46): DateTime, addKnownWordFromCloud, addPreferredImageFromCloud, addQueuedWordFromCloud, addWordToLearn, allProgress, fromJson, _getAppDir (+38 more)

### Community 5 - "review_screen.dart"
Cohesion: 0.05
Nodes (42): _audioPlayer, build, _buildAntonymQuestion, _buildCompareQuestion, _buildContent, _buildExampleQuestion, _buildListeningQuestion, _buildMeaningQuestion (+34 more)

### Community 6 - "sync_service.dart"
Cohesion: 0.10
Nodes (20): FirebaseFirestore, addLog, _firestore, forceSyncDown, forceSyncUp, _instance, isSyncing, lastError (+12 more)

### Community 7 - "word.dart"
Cohesion: 0.04
Nodes (44): authorName, authorRole, collocations, comparisons, compounds, de, description, doText (+36 more)

### Community 8 - "learning_session_screen.dart"
Cohesion: 0.05
Nodes (38): AudioPlayer, _audioPlayer, build, _buildContinueButton, _buildQuestionContent, _buildTestBody, createState, _currentDictWord (+30 more)

### Community 9 - "database_service.dart"
Cohesion: 0.09
Nodes (22): encryption_service.dart, _allWords, availableCurriculums, DatabaseService, DictWord, _frequencyRanks, fromJson, getCurriculum (+14 more)

### Community 10 - "settings_service.dart"
Cohesion: 0.04
Nodes (43): clearLocalStorage, decryptFile, decryptString, EncryptionService, initialize, isInitialized, loadFromLocalStorage, _masterIvBase64 (+35 more)

### Community 11 - "my_application.cc"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 12 - "wordup_api.dart"
Cohesion: 0.05
Nodes (38): database_service.dart, edge_tts_service.dart, cacheWordMedia, clearWordCache, _getFileNameFromUrl, getLocalFile, _getWordCacheDir, MediaCacheService (+30 more)

### Community 13 - "home_screen.dart"
Cohesion: 0.07
Nodes (26): Color, FocusNode?, learning_session_screen.dart, _buildFilterChip, _buildSortChip, _buildStatCard, createState, _curriculumFilter (+18 more)

### Community 14 - "package.json"
Cohesion: 0.11
Nodes (15): cors, express, node-fetch, dependencies, cors, express, node-fetch, sqlite3 (+7 more)

### Community 15 - "webview_windows_stub.dart"
Cohesion: 0.12
Nodes (15): controller, dispose, executeScript, initialize, isInitialized, LoadingState, loadStringContent, loadUrl (+7 more)

### Community 16 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 17 - "State"
Cohesion: 0.18
Nodes (15): SplashLoadingScreen, _SplashLoadingScreenState, CachedMediaImage, _CachedMediaImageState, CompareWithSection, _CompareWithSectionState, SelectableImage, _SelectableImageState (+7 more)

### Community 18 - "sync_status_screen.dart"
Cohesion: 0.14
Nodes (14): build, _buildStatColumn, createState, dispose, initState, _onSyncChange, _progress, _sync (+6 more)

### Community 19 - "interceptor/package.json"
Cohesion: 0.18
Nodes (10): author, description, keywords, license, main, name, scripts, test (+2 more)

### Community 20 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 21 - "highlight_text.dart"
Cohesion: 0.06
Nodes (35): int?, build, buildSpans, candidates, _computeSpans, _computeTokens, createState, didUpdateWidget (+27 more)

### Community 22 - "test_html.dart"
Cohesion: 0.50
Nodes (3): main, response, url

### Community 23 - "fetch_jester.dart"
Cohesion: 0.22
Nodes (8): content, file, list, main, response, url, word, wordId

### Community 24 - "server.js"
Cohesion: 0.22
Nodes (8): app, cors, db, dbPath, express, path, sqlite3, zlib

### Community 25 - "firebase_service.dart"
Cohesion: 0.18
Nodes (10): _auth, FirebaseService, _firestore, getWordProgress, signInAnonymously, syncWordProgress, package:cloud_firestore/cloud_firestore.dart, package:firebase_auth/firebase_auth.dart (+2 more)

### Community 26 - "main.dart"
Cohesion: 0.15
Nodes (12): firebase_options.dart, build, createState, _initializeApp, initState, main, WordDownApp, WordListScreen (+4 more)

### Community 27 - "check_current.dart"
Cohesion: 0.25
Nodes (7): content, data, decoded, extraKnownCount, knownCount, learningCount, main

### Community 28 - "test_json.dart"
Cohesion: 0.25
Nodes (7): html, jsonMatch, jsonRegex, main, nextData, pageProps, senses

### Community 29 - "firebase_options.dart"
Cohesion: 0.25
Nodes (7): android, DefaultFirebaseOptions, web, windows, package:firebase_core/firebase_core.dart, package:flutter/foundation.dart, static const FirebaseOptions

### Community 30 - "settings_screen.dart"
Cohesion: 0.22
Nodes (9): _buildToggle, createState, SettingsScreen, _SettingsScreenState, _settingsService, SettingsService, login_screen.dart, ../services/encryption_service.dart (+1 more)

### Community 31 - "word_list_screen.dart"
Cohesion: 0.29
Nodes (6): build, title, words, ../services/database_service.dart, ../services/progress_service.dart, word_view_screen.dart

### Community 32 - "package:http/http.dart"
Cohesion: 0.11
Nodes (16): package:archive/archive.dart, package:http/http.dart, main, response, url, wordId, j, main (+8 more)

### Community 33 - "apply_reset.dart"
Cohesion: 0.29
Nodes (6): ids, idStrings, innerText, knownWordsText, main, progressFile

### Community 34 - "test_audio.dart"
Cohesion: 0.25
Nodes (7): List, bytes, data, jsonString, main, response, url

### Community 36 - "analyze_json.dart"
Cohesion: 0.17
Nodes (10): Map, data, jsonString, main, r, data, main, response (+2 more)

### Community 38 - "dart:io"
Cohesion: 0.14
Nodes (11): dart:io, content, data, main, c, d, known, learning (+3 more)

### Community 39 - "process_ranking.dart"
Cohesion: 0.33
Nodes (5): ids, idStrings, innerText, main, rankingText

### Community 43 - "login_screen.dart"
Cohesion: 0.09
Nodes (22): FirebaseAuth, _auth, build, createState, _emailController, _errorMessage, _formatCleanError, _isLoading (+14 more)

### Community 44 - "analyze_list2.dart"
Cohesion: 0.40
Nodes (4): content, data, main, uw

### Community 45 - "analyze_local.dart"
Cohesion: 0.40
Nodes (4): c, d, m, main

### Community 46 - "analyze_progress.dart"
Cohesion: 0.40
Nodes (4): main, maxCount, progress, words

### Community 48 - "fix_progress.dart"
Cohesion: 0.40
Nodes (4): c, d, f, main

### Community 49 - "app.js"
Cohesion: 0.83
Nodes (3): fetchAndRenderWord(), loadCurrentWord(), renderRealData()

### Community 51 - "MaterialPageRoute"
Cohesion: 0.29
Nodes (7): build, _buildProgressTabs, _buildWordDetailsOverlay, build, _openWord, _onWordTap, MaterialPageRoute

### Community 54 - "dart:convert"
Cohesion: 0.20
Nodes (7): dart:convert, content, data, main, main, mire, progress

### Community 55 - "Word Down 📖"
Cohesion: 0.22
Nodes (8): Building for Release, ✨ Features, 🚀 Getting Started, Installation, 📄 License, Prerequisites, 🔒 Security Notes, Word Down 📖

### Community 57 - "index.js"
Cohesion: 0.50
Nodes (3): fs, path, puppeteer

### Community 79 - "edge_tts_service.dart"
Cohesion: 0.05
Nodes (37): main, dart:async, dart:math, dart:typed_data, _chromiumFullVersion, _chromiumMajorVersion, EdgeTtsService, _escapeXml (+29 more)

## Knowledge Gaps
- **634 isolated node(s):** `main`, `DefaultFirebaseOptions`, `web`, `android`, `windows` (+629 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 763 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **10 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WebviewController` connect `webview_windows_stub.dart` to `word_view_screen.dart`?**
  _High betweenness centrality (0.032) - this node is a cross-community bridge._
- **Why does `WordData` connect `word.dart` to `learning_session_screen.dart`, `word_view_screen.dart`, `review_screen.dart`?**
  _High betweenness centrality (0.023) - this node is a cross-community bridge._
- **Why does `WordVideo` connect `word.dart` to `word_view_screen.dart`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **What connects `main`, `DefaultFirebaseOptions`, `web` to the rest of the system?**
  _634 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.05311676909569798 - nodes in this community are weakly interconnected._
- **Should `word_view_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.021505376344086023 - nodes in this community are weakly interconnected._
- **Should `GeneratedPluginRegistrant.swift` be split into smaller, more focused modules?**
  _Cohesion score 0.04846938775510204 - nodes in this community are weakly interconnected._