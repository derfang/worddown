# Graph Report - worddown  (2026-09-04)

## Corpus Check
- 132 files · ~642,490 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 919 nodes · 1105 edges · 74 communities (59 shown, 8 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `8fb41502`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Win32Window
- word_view_screen.dart
- GeneratedPluginRegistrant.swift
- 🧠 WordDown
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
- dart:convert
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
- MaterialPageRoute
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
- package:flutter/material.dart
- analyze_list2.dart
- analyze_local.dart
- analyze_progress.dart
- fetch_jester_raw.dart
- fix_progress.dart
- app.js
- fetch_test.dart
- StatelessWidget
- scratch_yt.dart
- query.js
- analyze_dict.dart
- check_progress.dart
- fetch_word.dart
- index.js
- test_fetch.js
- test_regex.dart
- MainActivity.kt
- rules/graphify.md
- workflows/graphify.md
- LaunchImage.imageset/README.md
- test.dart
- bool?
- String?

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 24 edges
2. `🧠 WordDown` - 13 edges
3. `MessageHandler` - 12 edges
4. `FlutterWindow` - 10 edges
5. `Create` - 10 edges
6. `WndProc` - 10 edges
7. `MessageHandler` - 9 edges
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

## Communities (74 total, 8 thin omitted)

### Community 0 - "Win32Window"
Cohesion: 0.05
Nodes (57): PluginRegistry, RECT, unique_ptr, RegisterPlugins(), DartProject, HWND, LPARAM, LRESULT (+49 more)

### Community 1 - "word_view_screen.dart"
Cohesion: 0.04
Nodes (52): BoxFit, ChewieController?, double?, File?, _audioPlayer, bottomNavigationBarOverride, build, _buildBottomActions (+44 more)

### Community 2 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (35): Any, audioplayers_darwin, cloud_firestore, Cocoa, firebase_auth, firebase_core, Flutter, FlutterAppDelegate (+27 more)

### Community 3 - "🧠 WordDown"
Cohesion: 0.04
Nodes (45): 1. Executive Summary, 2. High-Level System Architecture, 3.1. 11-Stage Spaced Repetition System (SRS), 3.2. Morphological Suffix & Stemming Engine (`HighlightText`), 3.3. Multi-Tier Content Acquisition & Caching Pipeline, 3.4. Dual-Engine Cross-Platform Media Pipeline, 3.5. Two-Way Asynchronous Cloud Synchronization, 3. Core Architectural Subsystems (+37 more)

### Community 4 - "progress_service.dart"
Cohesion: 0.04
Nodes (45): DateTime, addKnownWordFromCloud, addPreferredImageFromCloud, addQueuedWordFromCloud, addWordToLearn, allProgress, fromJson, _getAppDir (+37 more)

### Community 5 - "review_screen.dart"
Cohesion: 0.05
Nodes (43): _audioPlayer, build, _buildAntonymQuestion, _buildCompareQuestion, _buildContent, _buildExampleQuestion, _buildListeningQuestion, _buildMeaningQuestion (+35 more)

### Community 6 - "sync_service.dart"
Cohesion: 0.05
Nodes (38): FirebaseAuth, FirebaseFirestore, _auth, build, createState, _emailController, _errorMessage, _isLoading (+30 more)

### Community 7 - "word.dart"
Cohesion: 0.05
Nodes (40): authorName, authorRole, collocations, comparisons, compounds, de, description, doText (+32 more)

### Community 8 - "learning_session_screen.dart"
Cohesion: 0.05
Nodes (38): AudioPlayer, int?, _audioPlayer, build, _buildContinueButton, _buildQuestionContent, _buildTestBody, createState (+30 more)

### Community 9 - "database_service.dart"
Cohesion: 0.05
Nodes (36): dart:math, dart:typed_data, _allWords, availableCurriculums, DatabaseService, DictWord, _frequencyRanks, fromJson (+28 more)

### Community 10 - "settings_service.dart"
Cohesion: 0.06
Nodes (30): _buildToggle, createState, SettingsScreen, _SettingsScreenState, _settingsService, enableAntonymQuestion, enableCompareQuestion, enableExampleQuestion (+22 more)

### Community 11 - "my_application.cc"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 12 - "wordup_api.dart"
Cohesion: 0.08
Nodes (23): android, DefaultFirebaseOptions, web, windows, cacheWordMedia, clearWordCache, _getFileNameFromUrl, getLocalFile (+15 more)

### Community 13 - "home_screen.dart"
Cohesion: 0.08
Nodes (24): Color, FocusNode?, learning_session_screen.dart, _buildFilterChip, _buildSortChip, _buildStatCard, createState, _curriculumFilter (+16 more)

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
Cohesion: 0.23
Nodes (12): HomeScreen, _HomeScreenState, LearningSessionScreen, _LearningSessionScreenState, CachedMediaImage, _CachedMediaImageState, SelectableImage, _SelectableImageState (+4 more)

### Community 18 - "dart:convert"
Cohesion: 0.18
Nodes (7): dart:convert, main, texts, package:crypto/crypto.dart, content, data, main

### Community 19 - "interceptor/package.json"
Cohesion: 0.18
Nodes (10): author, description, keywords, license, main, name, scripts, test (+2 more)

### Community 20 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 21 - "highlight_text.dart"
Cohesion: 0.22
Nodes (8): build, _isMatch, learningWords, normalStyle, selfWord, text, package:flutter/gestures.dart, TextStyle

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
Cohesion: 0.25
Nodes (7): firebase_options.dart, build, init, main, package:google_fonts/google_fonts.dart, screens/home_screen.dart, ../services/progress_service.dart

### Community 27 - "check_current.dart"
Cohesion: 0.25
Nodes (7): content, data, decoded, extraKnownCount, knownCount, learningCount, main

### Community 28 - "test_json.dart"
Cohesion: 0.25
Nodes (7): html, jsonMatch, jsonRegex, main, nextData, pageProps, senses

### Community 29 - "download_jester.dart"
Cohesion: 0.29
Nodes (6): bytes, jsonString, main, response, token, url

### Community 30 - "MaterialPageRoute"
Cohesion: 0.29
Nodes (7): build, _buildProgressTabs, _buildWordDetailsOverlay, build, _openWord, _onWordTap, MaterialPageRoute

### Community 31 - "word_list_screen.dart"
Cohesion: 0.29
Nodes (6): build, title, words, List, ../services/database_service.dart, word_view_screen.dart

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

### Community 43 - "package:flutter/material.dart"
Cohesion: 0.40
Nodes (4): package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:worddown_flutter/main.dart, main

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

### Community 51 - "StatelessWidget"
Cohesion: 0.50
Nodes (4): WordDownApp, WordListScreen, HighlightText, StatelessWidget

### Community 52 - "scratch_yt.dart"
Cohesion: 0.50
Nodes (3): package:youtube_explode_dart/youtube_explode_dart.dart, main, yt

### Community 53 - "query.js"
Cohesion: 0.50
Nodes (3): db, fs, sqlite3

### Community 54 - "analyze_dict.dart"
Cohesion: 0.50
Nodes (3): content, data, main

### Community 55 - "check_progress.dart"
Cohesion: 0.50
Nodes (3): main, mire, progress

### Community 56 - "fetch_word.dart"
Cohesion: 0.50
Nodes (3): j, main, r

### Community 57 - "index.js"
Cohesion: 0.50
Nodes (3): fs, path, puppeteer

### Community 59 - "test_regex.dart"
Cohesion: 0.50
Nodes (3): cleanedSubtitles, main, rawSubtitles

## Knowledge Gaps
- **561 isolated node(s):** `url`, `file`, `main`, `token`, `url` (+556 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 671 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `SettingsService` connect `settings_service.dart` to `review_screen.dart`?**
  _High betweenness centrality (0.034) - this node is a cross-community bridge._
- **Why does `WebviewController` connect `webview_windows_stub.dart` to `word_view_screen.dart`?**
  _High betweenness centrality (0.022) - this node is a cross-community bridge._
- **Why does `WordData` connect `word.dart` to `learning_session_screen.dart`, `word_view_screen.dart`, `review_screen.dart`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **What connects `url`, `file`, `main` to the rest of the system?**
  _561 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.05311676909569798 - nodes in this community are weakly interconnected._
- **Should `word_view_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03773584905660377 - nodes in this community are weakly interconnected._
- **Should `GeneratedPluginRegistrant.swift` be split into smaller, more focused modules?**
  _Cohesion score 0.04846938775510204 - nodes in this community are weakly interconnected._