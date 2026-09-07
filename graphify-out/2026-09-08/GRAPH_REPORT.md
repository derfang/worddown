# Graph Report - worddown  (2026-09-08)

## Corpus Check
- 134 files · ~137,965 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1071 nodes · 1302 edges · 82 communities (65 shown, 11 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `1bb9ae82`
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
- analyze_list.dart
- interceptor/package.json
- manifest.json
- highlight_text.dart
- package:http/http.dart
- fetch_jester.dart
- server.js
- dart:io
- main.dart
- check_current.dart
- test_json.dart
- download_jester.dart
- generate_sounds.dart
- word_list_screen.dart
- package:archive/archive.dart
- apply_reset.dart
- test_audio.dart
- extract_urls.dart
- analyze_json.dart
- parse_zann.dart
- analyze_local2.dart
- process_ranking.dart
- test_zann.dart
- extract_keys.dart
- find_jester.dart
- login_screen.dart
- analyze_list2.dart
- analyze_local.dart
- analyze_progress.dart
- fetch_jester_raw.dart
- fix_progress.dart
- app.js
- fetch_test.dart
- MaterialPageRoute
- scratch_yt.dart
- query.js
- dart:convert
- Word Down 📖
- fetch_word.dart
- index.js
- test_fetch.js
- test_regex.dart
- MainActivity.kt
- rules/graphify.md
- workflows/graphify.md
- LaunchImage.imageset/README.md
- settings_screen.dart
- test.dart
- bool?
- String?
- _MeasureSize
- _MeasureSizeRenderObject
- check_progress.dart
- WordDownApp
- edge_tts_service.dart
- encryption_service.dart
- hash_test.dart
- encryptor.dart

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

## Communities (82 total, 11 thin omitted)

### Community 0 - "Win32Window"
Cohesion: 0.05
Nodes (57): PluginRegistry, RECT, unique_ptr, RegisterPlugins(), DartProject, HWND, LPARAM, LRESULT (+49 more)

### Community 1 - "word_view_screen.dart"
Cohesion: 0.02
Nodes (91): AnimationController, BoxFit, ChewieController?, double?, File?, _audioPlayer, bottomNavigationBarOverride, build (+83 more)

### Community 2 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (35): Any, audioplayers_darwin, cloud_firestore, Cocoa, firebase_auth, firebase_core, Flutter, FlutterAppDelegate (+27 more)

### Community 3 - "3. Core Architectural Subsystems"
Cohesion: 0.10
Nodes (19): 1. Executive Summary, 2. High-Level System Architecture, 3.1. 11-Stage Spaced Repetition System (SRS), 3.2. Morphological Suffix & Stemming Engine (`HighlightText`), 3.3. Multi-Tier Content Acquisition & Caching Pipeline, 3.4. Dual-Engine Cross-Platform Media Pipeline, 3.5. Two-Way Asynchronous Cloud Synchronization, 3. Core Architectural Subsystems (+11 more)

### Community 4 - "progress_service.dart"
Cohesion: 0.04
Nodes (47): DateTime, addKnownWordFromCloud, addPreferredImageFromCloud, addQueuedWordFromCloud, addWordToLearn, allProgress, fromJson, _getAppDir (+39 more)

### Community 5 - "review_screen.dart"
Cohesion: 0.05
Nodes (41): _audioPlayer, build, _buildAntonymQuestion, _buildCompareQuestion, _buildContent, _buildExampleQuestion, _buildListeningQuestion, _buildMeaningQuestion (+33 more)

### Community 6 - "sync_service.dart"
Cohesion: 0.05
Nodes (44): FirebaseFirestore, build, _buildStatColumn, createState, dispose, initState, _onSyncChange, _progress (+36 more)

### Community 7 - "word.dart"
Cohesion: 0.05
Nodes (43): authorName, authorRole, collocations, comparisons, compounds, de, description, doText (+35 more)

### Community 8 - "learning_session_screen.dart"
Cohesion: 0.05
Nodes (38): AudioPlayer, WordData, _audioPlayer, build, _buildContinueButton, _buildQuestionContent, _buildTestBody, createState (+30 more)

### Community 9 - "database_service.dart"
Cohesion: 0.06
Nodes (29): encryption_service.dart, android, DefaultFirebaseOptions, web, windows, _allWords, availableCurriculums, DatabaseService (+21 more)

### Community 10 - "settings_service.dart"
Cohesion: 0.06
Nodes (30): audioFocusMode, enableAntonymQuestion, enableCompareQuestion, enableEdgeTts, enableExampleQuestion, enableGoogleTts, enableMeaningQuestion, enableMisspellingQuestion (+22 more)

### Community 11 - "my_application.cc"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 12 - "wordup_api.dart"
Cohesion: 0.05
Nodes (36): database_service.dart, edge_tts_service.dart, cacheWordMedia, clearWordCache, _getFileNameFromUrl, getLocalFile, _getWordCacheDir, MediaCacheService (+28 more)

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
Cohesion: 0.16
Nodes (17): HomeScreen, _HomeScreenState, ReviewScreen, _ReviewScreenState, CachedMediaImage, _CachedMediaImageState, CompareWithSection, _CompareWithSectionState (+9 more)

### Community 18 - "analyze_list.dart"
Cohesion: 0.50
Nodes (3): content, data, main

### Community 19 - "interceptor/package.json"
Cohesion: 0.18
Nodes (10): author, description, keywords, license, main, name, scripts, test (+2 more)

### Community 20 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 21 - "highlight_text.dart"
Cohesion: 0.05
Nodes (42): int?, build, buildSpans, candidates, _computeSpans, _computeTokens, createState, didUpdateWidget (+34 more)

### Community 22 - "package:http/http.dart"
Cohesion: 0.22
Nodes (7): package:http/http.dart, main, response, url, main, response, url

### Community 23 - "fetch_jester.dart"
Cohesion: 0.22
Nodes (8): content, file, list, main, response, url, word, wordId

### Community 24 - "server.js"
Cohesion: 0.22
Nodes (8): app, cors, db, dbPath, express, path, sqlite3, zlib

### Community 25 - "dart:io"
Cohesion: 0.25
Nodes (6): dart:io, file, main, url, files, main

### Community 26 - "main.dart"
Cohesion: 0.17
Nodes (12): firebase_options.dart, build, createState, _initializeApp, initState, main, SplashLoadingScreen, _SplashLoadingScreenState (+4 more)

### Community 27 - "check_current.dart"
Cohesion: 0.25
Nodes (7): content, data, decoded, extraKnownCount, knownCount, learningCount, main

### Community 28 - "test_json.dart"
Cohesion: 0.25
Nodes (7): html, jsonMatch, jsonRegex, main, nextData, pageProps, senses

### Community 29 - "download_jester.dart"
Cohesion: 0.25
Nodes (7): bytes, jsonString, main, response, token, url, List

### Community 30 - "generate_sounds.dart"
Cohesion: 0.12
Nodes (15): dart:math, bitsPerSample, blockAlign, builder, byteRate, chunkSize, data, _int16ToBytes (+7 more)

### Community 31 - "word_list_screen.dart"
Cohesion: 0.29
Nodes (6): build, title, words, ../services/database_service.dart, ../services/progress_service.dart, word_view_screen.dart

### Community 32 - "package:archive/archive.dart"
Cohesion: 0.29
Nodes (5): package:archive/archive.dart, main, main, response, url

### Community 33 - "apply_reset.dart"
Cohesion: 0.29
Nodes (6): ids, idStrings, innerText, knownWordsText, main, progressFile

### Community 34 - "test_audio.dart"
Cohesion: 0.29
Nodes (6): bytes, data, jsonString, main, response, url

### Community 35 - "extract_urls.dart"
Cohesion: 0.33
Nodes (5): content, main, matches, regex, uniqueUrls

### Community 36 - "analyze_json.dart"
Cohesion: 0.33
Nodes (5): Map, data, jsonString, main, r

### Community 37 - "parse_zann.dart"
Cohesion: 0.33
Nodes (5): content, file, main, match, regex

### Community 38 - "analyze_local2.dart"
Cohesion: 0.33
Nodes (5): c, d, known, learning, main

### Community 39 - "process_ranking.dart"
Cohesion: 0.33
Nodes (5): ids, idStrings, innerText, main, rankingText

### Community 40 - "test_zann.dart"
Cohesion: 0.33
Nodes (5): data, main, response, url, wordText

### Community 41 - "extract_keys.dart"
Cohesion: 0.40
Nodes (4): content, main, match, regex

### Community 42 - "find_jester.dart"
Cohesion: 0.40
Nodes (4): content, list, main, word

### Community 43 - "login_screen.dart"
Cohesion: 0.13
Nodes (15): FirebaseAuth, _auth, build, createState, _emailController, _errorMessage, _formatCleanError, _isLoading (+7 more)

### Community 44 - "analyze_list2.dart"
Cohesion: 0.40
Nodes (4): content, data, main, uw

### Community 45 - "analyze_local.dart"
Cohesion: 0.40
Nodes (4): c, d, m, main

### Community 46 - "analyze_progress.dart"
Cohesion: 0.40
Nodes (4): main, maxCount, progress, words

### Community 47 - "fetch_jester_raw.dart"
Cohesion: 0.40
Nodes (4): main, response, url, wordId

### Community 48 - "fix_progress.dart"
Cohesion: 0.40
Nodes (4): c, d, f, main

### Community 49 - "app.js"
Cohesion: 0.83
Nodes (3): fetchAndRenderWord(), loadCurrentWord(), renderRealData()

### Community 50 - "fetch_test.dart"
Cohesion: 0.50
Nodes (3): main, response, url

### Community 51 - "MaterialPageRoute"
Cohesion: 0.29
Nodes (7): build, _buildProgressTabs, _buildWordDetailsOverlay, build, _openWord, _onWordTap, MaterialPageRoute

### Community 52 - "scratch_yt.dart"
Cohesion: 0.50
Nodes (3): package:youtube_explode_dart/youtube_explode_dart.dart, main, yt

### Community 53 - "query.js"
Cohesion: 0.50
Nodes (3): db, fs, sqlite3

### Community 54 - "dart:convert"
Cohesion: 0.29
Nodes (4): dart:convert, content, data, main

### Community 55 - "Word Down 📖"
Cohesion: 0.22
Nodes (8): Building for Release, ✨ Features, 🚀 Getting Started, Installation, 📄 License, Prerequisites, 🔒 Security Notes, Word Down 📖

### Community 56 - "fetch_word.dart"
Cohesion: 0.50
Nodes (3): j, main, r

### Community 57 - "index.js"
Cohesion: 0.50
Nodes (3): fs, path, puppeteer

### Community 59 - "test_regex.dart"
Cohesion: 0.50
Nodes (3): cleanedSubtitles, main, rawSubtitles

### Community 64 - "settings_screen.dart"
Cohesion: 0.25
Nodes (8): _buildToggle, createState, SettingsScreen, _SettingsScreenState, _settingsService, SettingsService, login_screen.dart, ../services/settings_service.dart

### Community 76 - "check_progress.dart"
Cohesion: 0.50
Nodes (3): main, mire, progress

### Community 77 - "WordDownApp"
Cohesion: 0.67
Nodes (3): WordDownApp, WordListScreen, StatelessWidget

### Community 79 - "edge_tts_service.dart"
Cohesion: 0.10
Nodes (19): dart:async, _chromiumFullVersion, _chromiumMajorVersion, EdgeTtsService, _escapeXml, _generateMuid, _generateSecMsGec, _generateUuidHex (+11 more)

### Community 80 - "encryption_service.dart"
Cohesion: 0.22
Nodes (8): decryptFile, decryptString, EncryptionService, initialize, _masterIvBase64, _masterKeyBase64, package:encrypt/encrypt.dart, static String?

### Community 81 - "hash_test.dart"
Cohesion: 0.50
Nodes (3): main, texts, package:crypto/crypto.dart

## Knowledge Gaps
- **670 isolated node(s):** `main`, `url`, `file`, `main`, `token` (+665 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 802 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **11 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WordData` connect `learning_session_screen.dart` to `word_view_screen.dart`, `review_screen.dart`, `word.dart`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **Why does `DictWord` connect `database_service.dart` to `learning_session_screen.dart`, `review_screen.dart`, `home_screen.dart`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **Why does `WebviewController` connect `webview_windows_stub.dart` to `word_view_screen.dart`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **What connects `main`, `url`, `file` to the rest of the system?**
  _670 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.05311676909569798 - nodes in this community are weakly interconnected._
- **Should `word_view_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.021739130434782608 - nodes in this community are weakly interconnected._
- **Should `GeneratedPluginRegistrant.swift` be split into smaller, more focused modules?**
  _Cohesion score 0.04846938775510204 - nodes in this community are weakly interconnected._