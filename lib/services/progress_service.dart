import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'sync_service.dart';
import 'media_cache_service.dart';

class WordProgress {
  final int wordId;
  int rememberCount; // 0 to 11 (11 = Mastered/Known)
  DateTime practiceDue;
  DateTime? lastReviewed;

  WordProgress({
    required this.wordId,
    required this.rememberCount,
    required this.practiceDue,
    this.lastReviewed,
  });

  factory WordProgress.fromJson(Map<String, dynamic> json) {
    DateTime? reviewed;
    if (json['LastReviewed'] != null) {
      try {
        reviewed = DateTime.parse(json['LastReviewed'].toString());
      } catch (_) {}
    }
    return WordProgress(
      wordId: json['WordId'] ?? 0,
      rememberCount: json['RememberCount'] ?? 0,
      practiceDue: json['PracticeDue'] != null 
          ? DateTime.parse(json['PracticeDue'].toString()) 
          : DateTime.now(),
      lastReviewed: reviewed,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'WordId': wordId,
      'RememberCount': rememberCount,
      'PracticeDue': practiceDue.toIso8601String(),
    };
    if (lastReviewed != null) {
      map['LastReviewed'] = lastReviewed!.toIso8601String();
    }
    return map;
  }
}

class SyncMergeResult {
  final int cloudEntriesProcessed;
  final int localUpdatedFromCloud;
  final int localKeptNewer;
  final int masteredCleaned;
  final bool hasLocalChangesToUpload;

  SyncMergeResult({
    required this.cloudEntriesProcessed,
    required this.localUpdatedFromCloud,
    required this.localKeptNewer,
    required this.masteredCleaned,
    required this.hasLocalChangesToUpload,
  });
}

class ProgressService {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  Map<int, WordProgress> _progressMap = {};
  Set<int> _knownWordIds = {};
  Set<int> _queuedWordsToLearn = {};
  Map<int, String> _preferredImages = {};
  Set<int> _pendingSyncWordIds = {};
  // The 11-step ladder
  final List<Duration> stepIntervals = [
    const Duration(days: 0), // Step 0 (To learn / new)
    const Duration(days: 1), // Step 1
    const Duration(days: 2), // Step 2
    const Duration(days: 3), // Step 3
    const Duration(days: 4), // Step 4 (NEW)
    const Duration(days: 7), // Step 5 (1 week)
    const Duration(days: 14),// Step 6 (2 weeks)
    const Duration(days: 30),// Step 7 (1 month)
    const Duration(days: 60),// Step 8 (2 months)
    const Duration(days: 90),// Step 9 (3 months)
    const Duration(days: 180),// Step 10 (6 months)
    const Duration(days: 365),// Step 11 (12 months)
    // Step 12 is 'Known'
  ];

  /// Returns the directory where local data files should be stored.
  /// On Windows/desktop we use the application support directory (isolated and stable).
  /// On Android/iOS we use the app documents directory (the only writable location).
  Future<String> _getAppDir() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final dir = await getApplicationSupportDirectory();
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir.path;
    }
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<File> _resolveFile(String filename) async {
    final dir = await _getAppDir();
    final primaryFile = File('$dir/$filename');
    if (await primaryFile.exists()) {
      final len = await primaryFile.length();
      if (len > 10) {
        return primaryFile;
      }
    }
    // Desktop migration: check working directory if primary file doesn't exist yet
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        final legacyFile = File('${Directory.current.path}/$filename');
        if (await legacyFile.exists()) {
          final len = await legacyFile.length();
          if (len > 10) {
            final bytes = await legacyFile.readAsBytes();
            await primaryFile.writeAsBytes(bytes);
            return primaryFile;
          }
        }
      } catch (_) {}
    }
    if (Platform.isAndroid) {
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final extFile = File('${extDir.path}/$filename');
          if (await extFile.exists()) {
            final extLen = await extFile.length();
            if (extLen > 10) {
              // Copy over to app documents dir
              final bytes = await extFile.readAsBytes();
              await primaryFile.writeAsBytes(bytes);
              return primaryFile;
            }
          }
        }
      } catch (_) {}
    }
    return primaryFile;
  }

  Future<int> importFromExternalStorage() async {
    int imported = 0;
    if (Platform.isAndroid) {
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final dir = await _getAppDir();
          for (var name in [
            'local_progress.json',
            'local_known_words.json',
            'local_to_learn.json',
            'local_preferred_images.json',
            'local_pending_sync.json',
          ]) {
            final src = File('${extDir.path}/$name');
            if (await src.exists()) {
              final len = await src.length();
              if (len > 10) {
                final dst = File('$dir/$name');
                await dst.writeAsBytes(await src.readAsBytes());
                imported++;
              }
            }
          }
        }
      } catch (e) {
        print('Error importing from external: $e');
      }
    }
    if (imported > 0) {
      await _loadKnownWords();
      await _loadToLearnWords();
      await _loadPreferredImages();
      await _loadPendingSync();
      final pFile = await _getFile();
      if (await pFile.exists()) {
        final jsonString = await pFile.readAsString();
        if (jsonString.isNotEmpty) {
          final List<dynamic> data = json.decode(jsonString);
          _progressMap.clear();
          for (var item in data) {
            final p = WordProgress.fromJson(item);
            _progressMap[p.wordId] = p;
          }
        }
      }
      await SyncService().forceSyncUp();
    }
    return imported;
  }

  Future<File> _getSaveFile(String filename) async {
    final dir = await _getAppDir();
    return File('$dir/$filename');
  }

  Future<File> _getFile() => _resolveFile('local_progress.json');
  Future<File> _getKnownWordsFile() => _resolveFile('local_known_words.json');
  Future<File> _getToLearnFile() => _resolveFile('local_to_learn.json');
  Future<File> _getPreferredImagesFile() => _resolveFile('local_preferred_images.json');
  Future<File> _getPendingSyncFile() => _resolveFile('local_pending_sync.json');

  Future<void> _loadPendingSync() async {
    try {
      final file = await _getPendingSyncFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final List<dynamic> data = json.decode(content);
          _pendingSyncWordIds = data.map((e) => (e as num).toInt()).toSet();
        }
      }
    } catch (e) {
      print('Error loading pending sync words: $e');
    }
  }

  Future<void> savePendingSync() async {
    final file = await _getSaveFile('local_pending_sync.json');
    await file.writeAsString(json.encode(_pendingSyncWordIds.toList()));
  }

  Set<int> get pendingSyncWordIds => Set.unmodifiable(_pendingSyncWordIds);

  void markPendingSync(int wordId) {
    _pendingSyncWordIds.add(wordId);
  }

  void clearPendingSync(Iterable<int> wordIds) {
    _pendingSyncWordIds.removeAll(wordIds);
  }

  void clearAllPendingSync() {
    _pendingSyncWordIds.clear();
  }

  Future<void> _loadKnownWords() async {
    try {
      final file = await _getKnownWordsFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final List<dynamic> data = json.decode(content);
          _knownWordIds = data.map((e) => (e as num).toInt()).toSet();
        }
      }
    } catch (e) {
      print('Error loading known words: $e');
    }
  }

  Future<void> _saveKnownWords() async {
    final file = await _getSaveFile('local_known_words.json');
    await file.writeAsString(json.encode(_knownWordIds.toList()));
  }

  Future<void> _loadToLearnWords() async {
    try {
      final file = await _getToLearnFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final List<dynamic> data = json.decode(content);
          _queuedWordsToLearn = data.map((e) => (e as num).toInt()).toSet();
        }
      }
    } catch (e) {
      print('Error loading to-learn words: $e');
    }
  }

  Future<void> _saveToLearnWords() async {
    final file = await _getSaveFile('local_to_learn.json');
    await file.writeAsString(json.encode(_queuedWordsToLearn.toList()));
  }

  Future<void> _loadPreferredImages() async {
    try {
      final file = await _getPreferredImagesFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final Map<String, dynamic> data = json.decode(content);
          _preferredImages = data.map((key, value) => MapEntry(int.parse(key), value as String));
        }
      }
    } catch (e) {
      print('Error loading preferred images: $e');
    }
  }

  Future<void> _savePreferredImages() async {
    final file = await _getSaveFile('local_preferred_images.json');
    await file.writeAsString(json.encode(_preferredImages.map((key, value) => MapEntry(key.toString(), value))));
  }

  Future<void> init() async {
    await _loadKnownWords();
    await _loadToLearnWords();
    await _loadPreferredImages();
    await _loadPendingSync();
    final file = await _getFile();
    if (await file.exists()) {
      final jsonString = await file.readAsString();
      if (jsonString.isNotEmpty) {
        final List<dynamic> data = json.decode(jsonString);
        for (var item in data) {
          final p = WordProgress.fromJson(item);
          _progressMap[p.wordId] = p;
        }
      }
    } else {
      // First run: import the current_progress.json from local file without altering it
      try {
        final fallbackFile = File('current_progress.json');
        if (await fallbackFile.exists()) {
          final content = await fallbackFile.readAsString();
          var decodedString = json.decode(content);
          if (decodedString is String) {
            decodedString = json.decode(decodedString);
          }
          final List<dynamic> data = decodedString;
          
          for (var item in data) {
            final p = WordProgress.fromJson(item);
            _progressMap[p.wordId] = p;
          }
          await save();
        } else {
          print('No local_progress.json or current_progress.json found.');
        }
      } catch (e) {
        print('Error importing initial progress: $e');
      }
    }
    
    // Initialize sync service so it starts listening to Auth changes
    SyncService();
  }

  Future<void> save() async {
    final file = await _getSaveFile('local_progress.json');
    final data = _progressMap.values.map((p) => p.toJson()).toList();
    await file.writeAsString(json.encode(data));
  }

  /// Safe monotonic merge between cloud data and local memory.
  /// Enforces that progress never regresses (max(local, cloud)),
  /// mastered words are irreversible, and local changes to upload are detected.
  SyncMergeResult mergeFromCloud({
    Map<String, dynamic>? cloudProgressMap,
    List<dynamic>? cloudKnownWords,
    List<dynamic>? cloudQueuedWords,
    Map<String, dynamic>? cloudPreferredImages,
  }) {
    int updatedFromCloud = 0;
    int keptLocalNewer = 0;
    int masteredCleaned = 0;
    bool hasLocalChanges = _pendingSyncWordIds.isNotEmpty;

    // 1. Process known words (Mastered words)
    // Rule: Union of known words. Mastered is irreversible by older progress steps.
    if (cloudKnownWords != null) {
      for (var wordIdNum in cloudKnownWords) {
        final wordId = (wordIdNum as num).toInt();
        _knownWordIds.add(wordId);
      }
    }

    // Clean up: Any word that is known MUST NOT be in progressMap or queuedWords
    for (final knownId in _knownWordIds) {
      if (_progressMap.containsKey(knownId)) {
        _progressMap.remove(knownId);
        masteredCleaned++;
        hasLocalChanges = true;
      }
      if (_queuedWordsToLearn.contains(knownId)) {
        _queuedWordsToLearn.remove(knownId);
        hasLocalChanges = true;
      }
    }

    // 2. Process progressMap
    if (cloudProgressMap != null) {
      for (var entry in cloudProgressMap.entries) {
        final wordId = int.tryParse(entry.key.toString());
        if (wordId == null) continue;
        if (_knownWordIds.contains(wordId)) {
          // Cloud sent a progress entry for a word that is already mastered.
          // Clean it up from cloud on next upload.
          hasLocalChanges = true;
          continue;
        }

        final cloudProgress = WordProgress.fromJson(Map<String, dynamic>.from(entry.value as Map));
        final localProgress = _progressMap[wordId];

        if (localProgress == null) {
          // Local doesn't have it yet -> accept cloud
          _progressMap[wordId] = cloudProgress;
          _queuedWordsToLearn.remove(wordId);
          updatedFromCloud++;
        } else {
          // Monotonic Conflict Resolution:
          // Rule 1: Highest rememberCount wins (progress cannot regress)
          if (cloudProgress.rememberCount > localProgress.rememberCount) {
            _progressMap[wordId] = cloudProgress;
            updatedFromCloud++;
          } else if (localProgress.rememberCount > cloudProgress.rememberCount) {
            // Local is further ahead than cloud! Keep local!
            keptLocalNewer++;
            hasLocalChanges = true;
          } else {
            // Equal rememberCount: pick the one with later lastReviewed date, or later practiceDue
            final cloudTime = cloudProgress.lastReviewed ?? cloudProgress.practiceDue;
            final localTime = localProgress.lastReviewed ?? localProgress.practiceDue;
            if (cloudTime.isAfter(localTime)) {
              _progressMap[wordId] = cloudProgress;
              updatedFromCloud++;
            } else if (localTime.isAfter(cloudTime)) {
              keptLocalNewer++;
              hasLocalChanges = true;
            }
          }
        }
      }

      // Check if local has words in progressMap that cloud doesn't have
      for (var localWordId in _progressMap.keys) {
        if (!cloudProgressMap.containsKey(localWordId.toString())) {
          hasLocalChanges = true;
          break;
        }
      }
    }

    // 3. Process queued words
    if (cloudQueuedWords != null) {
      for (var qNum in cloudQueuedWords) {
        final qId = (qNum as num).toInt();
        if (!_knownWordIds.contains(qId) && !_progressMap.containsKey(qId)) {
          _queuedWordsToLearn.add(qId);
        }
      }
    }

    // 4. Preferred images
    if (cloudPreferredImages != null) {
      for (var entry in cloudPreferredImages.entries) {
        final wordId = int.tryParse(entry.key.toString());
        if (wordId != null && !_preferredImages.containsKey(wordId)) {
          _preferredImages[wordId] = entry.value.toString();
        }
      }
    }

    return SyncMergeResult(
      cloudEntriesProcessed: cloudProgressMap?.length ?? 0,
      localUpdatedFromCloud: updatedFromCloud,
      localKeptNewer: keptLocalNewer,
      masteredCleaned: masteredCleaned,
      hasLocalChangesToUpload: hasLocalChanges,
    );
  }

  void updateProgressFromCloud(int wordId, Map<String, dynamic> data) {
    _progressMap[wordId] = WordProgress.fromJson(data);
  }

  void addKnownWordFromCloud(int wordId) {
    _knownWordIds.add(wordId);
  }

  void addQueuedWordFromCloud(int wordId) {
    _queuedWordsToLearn.add(wordId);
  }

  void addPreferredImageFromCloud(int wordId, String imageUrl) {
    _preferredImages[wordId] = imageUrl;
  }

  Future<void> saveAllLocal() async {
    await save();
    await _saveKnownWords();
    await _saveToLearnWords();
    await _savePreferredImages();
    await savePendingSync();
  }

  WordProgress? getProgress(int wordId) {
    return _progressMap[wordId];
  }

  /// Adds a new word to the 'To Learn' queue
  Future<void> addWordToLearn(int wordId) async {
    if (!_progressMap.containsKey(wordId) && !_knownWordIds.contains(wordId)) {
      _queuedWordsToLearn.add(wordId);
      markPendingSync(wordId);
      await _saveToLearnWords();
      await savePendingSync();
      SyncService().pushQueuedWord(wordId, true);
    }
  }

  /// Called after answering a word correctly in the Learning Session
  Future<void> graduateWord(int wordId) async {
    _queuedWordsToLearn.remove(wordId);
    markPendingSync(wordId);
    await _saveToLearnWords();
    SyncService().pushQueuedWord(wordId, false);
    
    // Move to learning ladder at step 1 (1 day interval)
    if (!_progressMap.containsKey(wordId)) {
      _progressMap[wordId] = WordProgress(
        wordId: wordId,
        rememberCount: 1, // Skip step 0 since it just graduated from the learning session
        practiceDue: DateTime.now().add(stepIntervals[1]),
        lastReviewed: DateTime.now(),
      );
      await save();
      await savePendingSync();
      SyncService().pushProgress(wordId, _progressMap[wordId]!.toJson());
    }
  }

  bool isInLearningQueue(int wordId) {
    return _queuedWordsToLearn.contains(wordId);
  }

  List<int> get queuedWordsToLearn => _queuedWordsToLearn.toList();

  /// Marks a word as already known, bypassing the learning process
  Future<void> markAsKnown(int wordId) async {
    _progressMap.remove(wordId);
    _knownWordIds.add(wordId);
    _queuedWordsToLearn.remove(wordId);
    markPendingSync(wordId);
    await _saveKnownWords();
    await _saveToLearnWords();
    await save();
    await savePendingSync();
    MediaCacheService.clearWordCache(wordId);
    SyncService().pushKnownWord(wordId, true);
    SyncService().pushProgress(wordId, null);
    SyncService().pushQueuedWord(wordId, false);
  }

  /// Moves a word manually to the "To Learn" queue from anywhere
  Future<void> markAsToLearn(int wordId) async {
    _progressMap.remove(wordId);
    _knownWordIds.remove(wordId);
    _queuedWordsToLearn.add(wordId);
    markPendingSync(wordId);
    await _saveKnownWords();
    await _saveToLearnWords();
    await save();
    await savePendingSync();
    SyncService().pushKnownWord(wordId, false);
    SyncService().pushProgress(wordId, null);
    SyncService().pushQueuedWord(wordId, true);
  }

  /// Called when user reviews a word
  Future<void> recordReview(int wordId, bool isCorrect) async {
    var p = _progressMap[wordId];
    if (p == null) {
      // Should not happen, but fallback
      p = WordProgress(
        wordId: wordId,
        rememberCount: 0,
        practiceDue: DateTime.now(),
        lastReviewed: DateTime.now(),
      );
      _progressMap[wordId] = p;
    }

    p.lastReviewed = DateTime.now();

    if (isCorrect) {
      if (p.rememberCount >= 11) {
        // Word is mastered, move to known words
        _progressMap.remove(wordId);
        _knownWordIds.add(wordId);
        markPendingSync(wordId);
        await _saveKnownWords();
        await save();
        await savePendingSync();
        MediaCacheService.clearWordCache(wordId);
        SyncService().pushKnownWord(wordId, true);
        SyncService().pushProgress(wordId, null);
        return;
      } else {
        // Move up
        p.rememberCount++;
      }
    } else {
      // Move down one step, but min is 1
      if (p.rememberCount > 1) {
        p.rememberCount--;
      }
    }

    // Set new due date based on new step
    if (p.rememberCount <= 11) {
      final interval = stepIntervals[p.rememberCount];
      p.practiceDue = DateTime.now().add(interval);
    }

    markPendingSync(wordId);
    await save();
    await savePendingSync();
    SyncService().pushProgress(wordId, p.toJson());
  }

  List<WordProgress> get dueWords {
    final now = DateTime.now();
    return _progressMap.values.where((p) => 
      p.rememberCount <= 11 && p.practiceDue.isBefore(now)
    ).toList();
  }

  List<WordProgress> get learningWords {
    return _progressMap.values.where((p) => p.rememberCount > 0 && p.rememberCount <= 11).toList();
  }

  List<WordProgress> get allProgress => _progressMap.values.toList();

  Set<int> get knownWordIds => _knownWordIds;

  Map<int, String> get preferredImages => _preferredImages;

  String? getPreferredImage(int wordId) {
    return _preferredImages[wordId];
  }

  Future<void> setPreferredImage(int wordId, String imageUrl) async {
    _preferredImages[wordId] = imageUrl;
    await _savePreferredImages();
    SyncService().pushPreferredImage(wordId, imageUrl);
  }
}
