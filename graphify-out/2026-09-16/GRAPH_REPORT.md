# Graph Report - worddown  (2026-09-15)

## Corpus Check
- 133 files · ~150,976 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1235 nodes · 1515 edges · 72 communities (57 shown, 9 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `cdf66867`
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
- generate_sounds.dart
- cache_manager_service.dart
- interceptor/package.json
- manifest.json
- highlight_text.dart
- android-deployment.md
- fetch_jester.dart
- server.js
- package:flutter/material.dart
- settings_screen.dart
- check_current.dart
- test_json.dart
- cached_media_image.dart
- encryption_service.dart
- media_cache_service.dart
- package:http/http.dart
- apply_reset.dart
- login_screen.dart
- firebase_options.dart
- analyze_json.dart
- WordUp Database & Media Sync Tracking
- analyze_local2.dart
- process_ranking.dart
- dart:convert
- image_sync.py
- dart:io
- analyze_dict.dart
- analyze_list2.dart
- analyze_local.dart
- test_upper.dart
- State
- review_question_service.dart
- app.js
- test_audio.dart
- MaterialPageRoute
- word_list_screen.dart
- 1. Artifact Placement in `releases/`
- Stealth WordUp Database & Media Sync Invariant
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
7. `run_scrape()` - 8 edges
8. `_MyApplication` - 7 edges
9. `OnCreate` - 7 edges
10. `WindowClassRegistrar` - 7 edges

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

## Communities (72 total, 9 thin omitted)

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
Cohesion: 0.10
Nodes (19): 1. Executive Summary, 2. High-Level System Architecture, 3.1. 11-Stage Spaced Repetition System (SRS), 3.2. Morphological Suffix & Stemming Engine (`HighlightText`), 3.3. Multi-Tier Content Acquisition & Caching Pipeline, 3.4. Dual-Engine Cross-Platform Media Pipeline, 3.5. Two-Way Asynchronous Cloud Synchronization, 3. Core Architectural Subsystems (+11 more)

### Community 4 - "progress_service.dart"
Cohesion: 0.03
Nodes (61): DateTime, addKnownWordFromCloud, addPreferredImageFromCloud, addQueuedWordFromCloud, addWordToLearn, allProgress, clearAllPendingSync, clearPendingSync (+53 more)

### Community 5 - "review_screen.dart"
Cohesion: 0.04
Nodes (49): _activePreparedQuestion, _applyQuestion, _audioPlayer, _audioSequenceId, build, _buildAntonymQuestion, _buildCompareQuestion, _buildContent (+41 more)

### Community 6 - "sync_service.dart"
Cohesion: 0.04
Nodes (45): FirebaseFirestore, build, _buildStatColumn, createState, dispose, initState, _onSyncChange, _progress (+37 more)

### Community 7 - "word.dart"
Cohesion: 0.04
Nodes (44): authorName, authorRole, _cleanWords, collocations, comparisons, compounds, de, description (+36 more)

### Community 8 - "learning_session_screen.dart"
Cohesion: 0.05
Nodes (39): AudioPlayer, _audioPlayer, build, _buildContinueButton, _buildQuestionContent, _buildTestBody, _buildWordWithAudioPrompt, createState (+31 more)

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
Cohesion: 0.06
Nodes (35): Client, database_service.dart, edge_tts_service.dart, clearLocalCache, clearMemoryCache, _client, data, decode (+27 more)

### Community 13 - "home_screen.dart"
Cohesion: 0.07
Nodes (29): Color, FocusNode?, learning_session_screen.dart, _buildFilterChip, _buildSortChip, _buildStatCard, createState, _curriculumFilter (+21 more)

### Community 14 - "stealth_sync.py"
Cohesion: 0.09
Nodes (22): Connection, cors, express, node-fetch, dependencies, cors, express, node-fetch (+14 more)

### Community 15 - "webview_windows_stub.dart"
Cohesion: 0.12
Nodes (15): controller, dispose, executeScript, initialize, isInitialized, LoadingState, loadStringContent, loadUrl (+7 more)

### Community 16 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 17 - "generate_sounds.dart"
Cohesion: 0.12
Nodes (15): dart:math, bitsPerSample, blockAlign, builder, byteRate, chunkSize, data, _int16ToBytes (+7 more)

### Community 18 - "cache_manager_service.dart"
Cohesion: 0.08
Nodes (23): int get, bytes, CacheCategoryStats, CacheManagerService, clearAllCache, clearMedia, clearPronunciations, clearWordDefinitions (+15 more)

### Community 19 - "interceptor/package.json"
Cohesion: 0.18
Nodes (10): author, description, keywords, license, main, name, scripts, test (+2 more)

### Community 20 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 21 - "highlight_text.dart"
Cohesion: 0.06
Nodes (36): int?, build, buildSpans, candidates, _computeSpans, _computeTokens, createState, didUpdateWidget (+28 more)

### Community 23 - "fetch_jester.dart"
Cohesion: 0.22
Nodes (8): content, file, list, main, response, url, word, wordId

### Community 24 - "server.js"
Cohesion: 0.22
Nodes (8): app, cors, db, dbPath, express, path, sqlite3, zlib

### Community 25 - "package:flutter/material.dart"
Cohesion: 0.07
Nodes (30): Directory, package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:path_provider_platform_interface/path_provider_platform_interface.dart, package:word_down/main.dart, package:word_down/models/word.dart, package:word_down/services/cache_manager_service.dart, package:word_down/services/media_cache_service.dart (+22 more)

### Community 26 - "settings_screen.dart"
Cohesion: 0.05
Nodes (39): firebase_options.dart, build, createState, _initializeApp, initState, main, SplashLoadingScreen, _SplashLoadingScreenState (+31 more)

### Community 27 - "check_current.dart"
Cohesion: 0.25
Nodes (7): content, data, decoded, extraKnownCount, knownCount, learningCount, main

### Community 28 - "test_json.dart"
Cohesion: 0.25
Nodes (7): html, jsonMatch, jsonRegex, main, nextData, pageProps, senses

### Community 29 - "cached_media_image.dart"
Cohesion: 0.11
Nodes (18): BoxFit?, double?, File?, build, CachedMediaImage, _CachedMediaImageState, _checkLocalCache, createState (+10 more)

### Community 30 - "encryption_service.dart"
Cohesion: 0.12
Nodes (15): dart:typed_data, clearLocalStorage, decryptBytes, decryptFile, decryptString, EncryptionService, initialize, isInitialized (+7 more)

### Community 31 - "media_cache_service.dart"
Cohesion: 0.11
Nodes (17): @visibleForTesting, _appDocsPath, cacheSingleMedia, cacheWordMedia, clearWordCache, ensureMediaCached, fetchAndDecryptFromHuggingFace, getAppDocsPath (+9 more)

### Community 32 - "package:http/http.dart"
Cohesion: 0.14
Nodes (13): package:archive/archive.dart, package:http/http.dart, main, response, url, wordId, j, main (+5 more)

### Community 33 - "apply_reset.dart"
Cohesion: 0.29
Nodes (6): ids, idStrings, innerText, knownWordsText, main, progressFile

### Community 34 - "login_screen.dart"
Cohesion: 0.13
Nodes (15): FirebaseAuth, _auth, build, createState, _emailController, _errorMessage, _formatCleanError, _isLoading (+7 more)

### Community 35 - "firebase_options.dart"
Cohesion: 0.25
Nodes (7): android, DefaultFirebaseOptions, web, windows, package:firebase_core/firebase_core.dart, package:flutter/foundation.dart, static const FirebaseOptions

### Community 36 - "analyze_json.dart"
Cohesion: 0.17
Nodes (10): Map, data, jsonString, main, r, data, main, response (+2 more)

### Community 37 - "WordUp Database & Media Sync Tracking"
Cohesion: 0.33
Nodes (5): 1. Overview & Architecture, 2. Current Progress Snapshot, 3. How to Check Progress Remotely, Pipeline Stages per Run, WordUp Database & Media Sync Tracking

### Community 38 - "analyze_local2.dart"
Cohesion: 0.33
Nodes (5): c, d, known, learning, main

### Community 39 - "process_ranking.dart"
Cohesion: 0.33
Nodes (5): ids, idStrings, innerText, main, rankingText

### Community 40 - "dart:convert"
Cohesion: 0.12
Nodes (12): dart:convert, main, maxCount, progress, words, main, mire, progress (+4 more)

### Community 41 - "image_sync.py"
Cohesion: 0.22
Nodes (14): compute_hf_path(), encrypt_bytes(), extract_image_urls(), fetch_url_bytes(), _load_key_iv(), main(), Returns a list of dicts describing every image associated with this word. Each…, Returns a dict with keys: ZannWordImage, ZannSenses, ZannQuotes. Returns empty… (+6 more)

### Community 42 - "dart:io"
Cohesion: 0.14
Nodes (10): main, dart:io, content, data, main, files, main, main (+2 more)

### Community 43 - "analyze_dict.dart"
Cohesion: 0.50
Nodes (3): content, data, main

### Community 44 - "analyze_list2.dart"
Cohesion: 0.40
Nodes (4): content, data, main, uw

### Community 45 - "analyze_local.dart"
Cohesion: 0.40
Nodes (4): c, d, m, main

### Community 46 - "test_upper.dart"
Cohesion: 0.50
Nodes (3): main, response, url

### Community 47 - "State"
Cohesion: 0.24
Nodes (11): CompareWithSection, _CompareWithSectionState, SelectableImage, _SelectableImageState, SlidingCardsView, _SlidingCardsViewState, WordViewScreen, _WordViewScreenState (+3 more)

### Community 48 - "review_question_service.dart"
Cohesion: 0.05
Nodes (36): WordData, _buildPreparedQuestion, _completedQuestions, _currentSessionQueue, currentVariant, currentVariantIndex, _deleteAudioFile, deleteExampleAudio (+28 more)

### Community 49 - "app.js"
Cohesion: 0.83
Nodes (3): fetchAndRenderWord(), loadCurrentWord(), renderRealData()

### Community 50 - "test_audio.dart"
Cohesion: 0.25
Nodes (7): List, bytes, data, jsonString, main, response, url

### Community 51 - "MaterialPageRoute"
Cohesion: 0.29
Nodes (7): build, _buildProgressTabs, _buildWordDetailsOverlay, build, _openWord, _onWordTap, MaterialPageRoute

### Community 52 - "word_list_screen.dart"
Cohesion: 0.29
Nodes (6): build, title, words, ../services/database_service.dart, ../services/progress_service.dart, word_view_screen.dart

### Community 53 - "1. Artifact Placement in `releases/`"
Cohesion: 0.33
Nodes (5): 1. Artifact Placement in `releases/`, 2. Build Cache & Disk Management, For Android Release Builds:, For Windows Release Builds:, Release Builds & Packaging Invariant

### Community 54 - "Stealth WordUp Database & Media Sync Invariant"
Cohesion: 0.50
Nodes (3): Stealth WordUp Database & Media Sync Invariant, Tracking & Checking Progress, Workflow Details

### Community 55 - "Word Down 📖"
Cohesion: 0.22
Nodes (8): Building for Release, ✨ Features, 🚀 Getting Started, Installation, 📄 License, Prerequisites, 🔒 Security Notes, Word Down 📖

### Community 57 - "index.js"
Cohesion: 0.50
Nodes (3): fs, path, puppeteer

### Community 79 - "edge_tts_service.dart"
Cohesion: 0.10
Nodes (20): dart:async, _chromiumFullVersion, _chromiumMajorVersion, EdgeTtsService, _escapeXml, _generateMuid, _generateSecMsGec, _generateUuidHex (+12 more)

## Knowledge Gaps
- **782 isolated node(s):** `main`, `DefaultFirebaseOptions`, `web`, `android`, `windows` (+777 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 927 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WebviewController` connect `webview_windows_stub.dart` to `word_view_screen.dart`?**
  _High betweenness centrality (0.031) - this node is a cross-community bridge._
- **Why does `WordData` connect `review_question_service.dart` to `learning_session_screen.dart`, `word_view_screen.dart`, `review_screen.dart`, `word.dart`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Why does `DictWord` connect `database_service.dart` to `learning_session_screen.dart`, `review_screen.dart`, `review_question_service.dart`, `home_screen.dart`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **What connects `main`, `DefaultFirebaseOptions`, `web` to the rest of the system?**
  _782 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.05311676909569798 - nodes in this community are weakly interconnected._
- **Should `word_view_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.021505376344086023 - nodes in this community are weakly interconnected._
- **Should `GeneratedPluginRegistrant.swift` be split into smaller, more focused modules?**
  _Cohesion score 0.04846938775510204 - nodes in this community are weakly interconnected._