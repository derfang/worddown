import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'sync_service.dart';
import 'media_cache_service.dart';

class WordProgress {
  final int wordId;
  int rememberCount; // 0 to 11 (11 = Mastered/Known)
  DateTime practiceDue;

  WordProgress({
    required this.wordId,
    required this.rememberCount,
    required this.practiceDue,
  });

  factory WordProgress.fromJson(Map<String, dynamic> json) {
    return WordProgress(
      wordId: json['WordId'] ?? 0,
      rememberCount: json['RememberCount'] ?? 0,
      practiceDue: json['PracticeDue'] != null 
          ? DateTime.parse(json['PracticeDue']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'WordId': wordId,
      'RememberCount': rememberCount,
      'PracticeDue': practiceDue.toIso8601String(),
    };
  }
}

class ProgressService {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  Map<int, WordProgress> _progressMap = {};
  Set<int> _knownWordIds = {};
  Set<int> _queuedWordsToLearn = {};
  Map<int, String> _preferredImages = {};
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
  /// On Windows/desktop we stay in the working directory (same as before).
  /// On Android/iOS we use the app documents directory (the only writable location).
  Future<String> _getAppDir() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return Directory.current.path;
    }
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<File> _getFile() async {
    final dir = await _getAppDir();
    return File('$dir/local_progress.json');
  }

  Future<File> _getKnownWordsFile() async {
    final dir = await _getAppDir();
    return File('$dir/local_known_words.json');
  }

  Future<File> _getToLearnFile() async {
    final dir = await _getAppDir();
    return File('$dir/local_to_learn.json');
  }

  Future<File> _getPreferredImagesFile() async {
    final dir = await _getAppDir();
    return File('$dir/local_preferred_images.json');
  }

  Future<void> _loadKnownWords() async {
    try {
      final file = await _getKnownWordsFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final List<dynamic> data = json.decode(content);
          _knownWordIds = data.map((e) => e as int).toSet();
        }
      }
    } catch (e) {
      print('Error loading known words: $e');
    }
  }

  Future<void> _saveKnownWords() async {
    final file = await _getKnownWordsFile();
    await file.writeAsString(json.encode(_knownWordIds.toList()));
  }

  Future<void> _loadToLearnWords() async {
    try {
      final file = await _getToLearnFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final List<dynamic> data = json.decode(content);
          _queuedWordsToLearn = data.map((e) => e as int).toSet();
        }
      }
    } catch (e) {
      print('Error loading to-learn words: $e');
    }
  }

  Future<void> _saveToLearnWords() async {
    final file = await _getToLearnFile();
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
    final file = await _getPreferredImagesFile();
    await file.writeAsString(json.encode(_preferredImages.map((key, value) => MapEntry(key.toString(), value))));
  }

  Future<void> init() async {
    await _loadKnownWords();
    await _loadToLearnWords();
    await _loadPreferredImages();
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
    final file = await _getFile();
    final data = _progressMap.values.map((p) => p.toJson()).toList();
    await file.writeAsString(json.encode(data));
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
  }

  WordProgress? getProgress(int wordId) {
    return _progressMap[wordId];
  }

  /// Adds a new word to the 'To Learn' queue
  Future<void> addWordToLearn(int wordId) async {
    if (!_progressMap.containsKey(wordId) && !_knownWordIds.contains(wordId)) {
      _queuedWordsToLearn.add(wordId);
      await _saveToLearnWords();
      SyncService().pushQueuedWord(wordId, true);
    }
  }

  /// Called after answering a word correctly in the Learning Session
  Future<void> graduateWord(int wordId) async {
    _queuedWordsToLearn.remove(wordId);
    await _saveToLearnWords();
    SyncService().pushQueuedWord(wordId, false);
    
    // Move to learning ladder at step 1 (1 day interval)
    if (!_progressMap.containsKey(wordId)) {
      _progressMap[wordId] = WordProgress(
        wordId: wordId,
        rememberCount: 1, // Skip step 0 since it just graduated from the learning session
        practiceDue: DateTime.now().add(stepIntervals[1]),
      );
      await save();
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
    await _saveKnownWords();
    await _saveToLearnWords();
    await save();
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
    await _saveKnownWords();
    await _saveToLearnWords();
    await save();
    SyncService().pushKnownWord(wordId, false);
    SyncService().pushProgress(wordId, null);
    SyncService().pushQueuedWord(wordId, true);
  }

  /// Called when user reviews a word
  Future<void> recordReview(int wordId, bool isCorrect) async {
    var p = _progressMap[wordId];
    if (p == null) {
      // Should not happen, but fallback
      p = WordProgress(wordId: wordId, rememberCount: 0, practiceDue: DateTime.now());
      _progressMap[wordId] = p;
    }

    if (isCorrect) {
      if (p.rememberCount >= 11) {
        // Word is mastered, move to known words
        _progressMap.remove(wordId);
        _knownWordIds.add(wordId);
        await _saveKnownWords();
        await save();
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

    await save();
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
