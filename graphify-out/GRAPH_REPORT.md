# Graph Report - worddown  (2026-09-11)

## Corpus Check
- 123 files · ~141,636 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1072 nodes · 1317 edges · 67 communities (52 shown, 9 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `cc4de37d`
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
- test_audio.dart
- MaterialPageRoute
- interceptor/package.json
- manifest.json
- highlight_text.dart
- State
- fetch_jester.dart
- server.js
- word_list_screen.dart
- main.dart
- check_current.dart
- test_json.dart
- cached_media_image.dart
- encryption_service.dart
- sync_status_screen.dart
- package:http/http.dart
- apply_reset.dart
- firebase_service.dart
- package:flutter/material.dart
- analyze_json.dart
- settings_screen.dart
- analyze_local2.dart
- process_ranking.dart
- dart:convert
- dart:io
- fix_progress.dart
- login_screen.dart
- analyze_list2.dart
- analyze_local.dart
- test_html.dart
- firebase_options.dart
- app.js
- ReviewScreen
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

## Communities (67 total, 9 thin omitted)

### Community 0 - "Win32Window"
Cohesion: 0.05
Nodes (57): PluginRegistry, RECT, unique_ptr, RegisterPlugins(), DartProject, HWND, LPARAM, LRESULT (+49 more)

### Community 1 - "word_view_screen.dart"
Cohesion: 0.02
Nodes (90): AnimationController, ChewieController?, _audioPlayer, bottomNavigationBarOverride, build, _buildAppBarTitle, _buildAudioBtn, _buildBottomActions (+82 more)

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
Cohesion: 0.04
Nodes (49): _audioPlayer, _audioSequenceId, build, _buildAntonymQuestion, _buildCompareQuestion, _buildContent, _buildExampleQuestion, _buildListeningQuestion (+41 more)

### Community 6 - "sync_service.dart"
Cohesion: 0.10
Nodes (20): FirebaseFirestore, addLog, _firestore, forceSyncDown, forceSyncUp, _instance, isSyncing, lastError (+12 more)

### Community 7 - "word.dart"
Cohesion: 0.05
Nodes (43): authorName, authorRole, collocations, comparisons, compounds, de, description, doText (+35 more)

### Community 8 - "learning_session_screen.dart"
Cohesion: 0.05
Nodes (38): AudioPlayer, WordData, _audioPlayer, build, _buildContinueButton, _buildQuestionContent, _buildTestBody, createState (+30 more)

### Community 9 - "database_service.dart"
Cohesion: 0.09
Nodes (22): encryption_service.dart, _allWords, availableCurriculums, DatabaseService, DictWord, _frequencyRanks, fromJson, getCurriculum (+14 more)

### Community 10 - "settings_service.dart"
Cohesion: 0.05
Nodes (42): audioFocusMode, enableAntonymQuestion, enableCompareQuestion, enableEdgeTts, enableExampleQuestion, enableGoogleTts, enableMeaningQuestion, enableMisspellingQuestion (+34 more)

### Community 11 - "my_application.cc"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 12 - "wordup_api.dart"
Cohesion: 0.04
Nodes (44): Client, database_service.dart, edge_tts_service.dart, cacheSingleMedia, cacheWordMedia, clearWordCache, _getFileNameFromUrl, getLocalFile (+36 more)

### Community 13 - "home_screen.dart"
Cohesion: 0.07
Nodes (28): Color, FocusNode?, learning_session_screen.dart, _buildFilterChip, _buildSortChip, _buildStatCard, createState, _curriculumFilter (+20 more)

### Community 14 - "stealth_sync.py"
Cohesion: 0.09
Nodes (22): Connection, cors, express, node-fetch, dependencies, cors, express, node-fetch (+14 more)

### Community 15 - "webview_windows_stub.dart"
Cohesion: 0.12
Nodes (15): controller, dispose, executeScript, initialize, isInitialized, LoadingState, loadStringContent, loadUrl (+7 more)

### Community 16 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 17 - "test_audio.dart"
Cohesion: 0.25
Nodes (7): List, bytes, data, jsonString, main, response, url

### Community 18 - "MaterialPageRoute"
Cohesion: 0.29
Nodes (7): build, _buildProgressTabs, _buildWordDetailsOverlay, build, _openWord, _onWordTap, MaterialPageRoute

### Community 19 - "interceptor/package.json"
Cohesion: 0.18
Nodes (10): author, description, keywords, license, main, name, scripts, test (+2 more)

### Community 20 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 21 - "highlight_text.dart"
Cohesion: 0.06
Nodes (36): int?, build, buildSpans, candidates, _computeSpans, _computeTokens, createState, didUpdateWidget (+28 more)

### Community 22 - "State"
Cohesion: 0.21
Nodes (13): SplashLoadingScreen, _SplashLoadingScreenState, CompareWithSection, _CompareWithSectionState, SelectableImage, _SelectableImageState, SlidingCardsView, _SlidingCardsViewState (+5 more)

### Community 23 - "fetch_jester.dart"
Cohesion: 0.22
Nodes (8): content, file, list, main, response, url, word, wordId

### Community 24 - "server.js"
Cohesion: 0.22
Nodes (8): app, cors, db, dbPath, express, path, sqlite3, zlib

### Community 25 - "word_list_screen.dart"
Cohesion: 0.20
Nodes (9): WordDownApp, build, title, WordListScreen, words, ../services/database_service.dart, ../services/progress_service.dart, StatelessWidget (+1 more)

### Community 26 - "main.dart"
Cohesion: 0.20
Nodes (9): firebase_options.dart, build, createState, _initializeApp, initState, main, package:google_fonts/google_fonts.dart, screens/home_screen.dart (+1 more)

### Community 27 - "check_current.dart"
Cohesion: 0.25
Nodes (7): content, data, decoded, extraKnownCount, knownCount, learningCount, main

### Community 28 - "test_json.dart"
Cohesion: 0.25
Nodes (7): html, jsonMatch, jsonRegex, main, nextData, pageProps, senses

### Community 29 - "cached_media_image.dart"
Cohesion: 0.12
Nodes (17): BoxFit?, double?, File?, build, CachedMediaImage, _CachedMediaImageState, _checkLocalCache, createState (+9 more)

### Community 30 - "encryption_service.dart"
Cohesion: 0.14
Nodes (13): clearLocalStorage, decryptFile, decryptString, EncryptionService, initialize, isInitialized, loadFromLocalStorage, _masterIvBase64 (+5 more)

### Community 31 - "sync_status_screen.dart"
Cohesion: 0.14
Nodes (14): build, _buildStatColumn, createState, dispose, initState, _onSyncChange, _progress, _sync (+6 more)

### Community 32 - "package:http/http.dart"
Cohesion: 0.11
Nodes (16): package:archive/archive.dart, package:http/http.dart, main, response, url, wordId, j, main (+8 more)

### Community 33 - "apply_reset.dart"
Cohesion: 0.29
Nodes (6): ids, idStrings, innerText, knownWordsText, main, progressFile

### Community 34 - "firebase_service.dart"
Cohesion: 0.18
Nodes (10): _auth, FirebaseService, _firestore, getWordProgress, signInAnonymously, syncWordProgress, package:cloud_firestore/cloud_firestore.dart, package:firebase_auth/firebase_auth.dart (+2 more)

### Community 35 - "package:flutter/material.dart"
Cohesion: 0.25
Nodes (7): package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:word_down/main.dart, package:word_down/models/word.dart, package:word_down/widgets/highlight_text.dart, main, main

### Community 36 - "analyze_json.dart"
Cohesion: 0.17
Nodes (10): Map, data, jsonString, main, r, data, main, response (+2 more)

### Community 37 - "settings_screen.dart"
Cohesion: 0.17
Nodes (12): _buildToggle, createState, _languages, SettingsScreen, _SettingsScreenState, _settingsService, SettingsService, login_screen.dart (+4 more)

### Community 38 - "analyze_local2.dart"
Cohesion: 0.33
Nodes (5): c, d, known, learning, main

### Community 39 - "process_ranking.dart"
Cohesion: 0.33
Nodes (5): ids, idStrings, innerText, main, rankingText

### Community 40 - "dart:convert"
Cohesion: 0.20
Nodes (7): dart:convert, content, data, main, main, mire, progress

### Community 41 - "dart:io"
Cohesion: 0.15
Nodes (10): dart:io, content, data, main, main, maxCount, progress, words (+2 more)

### Community 42 - "fix_progress.dart"
Cohesion: 0.40
Nodes (4): c, d, f, main

### Community 43 - "login_screen.dart"
Cohesion: 0.13
Nodes (15): FirebaseAuth, _auth, build, createState, _emailController, _errorMessage, _formatCleanError, _isLoading (+7 more)

### Community 44 - "analyze_list2.dart"
Cohesion: 0.40
Nodes (4): content, data, main, uw

### Community 45 - "analyze_local.dart"
Cohesion: 0.40
Nodes (4): c, d, m, main

### Community 46 - "test_html.dart"
Cohesion: 0.50
Nodes (3): main, response, url

### Community 47 - "firebase_options.dart"
Cohesion: 0.25
Nodes (7): android, DefaultFirebaseOptions, web, windows, package:firebase_core/firebase_core.dart, package:flutter/foundation.dart, static const FirebaseOptions

### Community 49 - "app.js"
Cohesion: 0.83
Nodes (3): fetchAndRenderWord(), loadCurrentWord(), renderRealData()

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
- **671 isolated node(s):** `main`, `DefaultFirebaseOptions`, `web`, `android`, `windows` (+666 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 799 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WordData` connect `learning_session_screen.dart` to `word_view_screen.dart`, `review_screen.dart`, `word.dart`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **Why does `WebviewController` connect `webview_windows_stub.dart` to `word_view_screen.dart`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Why does `ProgressService` connect `sync_status_screen.dart` to `learning_session_screen.dart`, `progress_service.dart`, `review_screen.dart`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **What connects `main`, `DefaultFirebaseOptions`, `web` to the rest of the system?**
  _671 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.05311676909569798 - nodes in this community are weakly interconnected._
- **Should `word_view_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02197802197802198 - nodes in this community are weakly interconnected._
- **Should `GeneratedPluginRegistrant.swift` be split into smaller, more focused modules?**
  _Cohesion score 0.04846938775510204 - nodes in this community are weakly interconnected._