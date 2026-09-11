import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'progress_service.dart';
import 'settings_service.dart';
import 'database_service.dart';
import 'wordup_api.dart';
import 'media_cache_service.dart';
import '../models/word.dart';

class ReviewOption {
  final int id;
  final String text;
  final bool isCorrect;
  ReviewOption(this.id, this.text, this.isCorrect);
}

class QuestionTypeVariant {
  final String type;
  final List<ReviewOption> options;
  final dynamic questionData;

  QuestionTypeVariant({
    required this.type,
    required this.options,
    required this.questionData,
  });
}

class PreparedReviewQuestion {
  final DictWord word;
  final WordData? wordData;
  final List<QuestionTypeVariant> variants;
  int currentVariantIndex;
  final String? displayImageUrl;
  final String? wordAudioPath;
  final String? exampleAudioPath;
  final String? exampleText;

  PreparedReviewQuestion({
    required this.word,
    required this.wordData,
    required this.variants,
    this.currentVariantIndex = 0,
    required this.displayImageUrl,
    this.wordAudioPath,
    this.exampleAudioPath,
    this.exampleText,
  });

  QuestionTypeVariant get currentVariant => variants[currentVariantIndex];
}

class ReviewQuestionService {
  static final ReviewQuestionService _instance = ReviewQuestionService._internal();
  factory ReviewQuestionService() => _instance;
  ReviewQuestionService._internal();

  List<WordProgress> _currentSessionQueue = [];
  final Map<int, Future<PreparedReviewQuestion?>> _preparedQuestions = {};
  final Map<int, PreparedReviewQuestion> _completedQuestions = {};

  List<WordProgress> get currentSessionQueue => _currentSessionQueue;

  PreparedReviewQuestion? getCachedQuestion(int index) => _completedQuestions[index];

  /// Starts or maintains a deterministic review queue and pre-makes questions
  void prepareReviewSession({BuildContext? context}) {
    final progress = ProgressService();
    final due = progress.dueWords;
    if (due.isEmpty) {
      _currentSessionQueue.clear();
      _preparedQuestions.clear();
      _completedQuestions.clear();
      return;
    }

    // Check if the current queue is still valid (matches the due count/ids)
    final dueIds = due.map((e) => e.wordId).toSet();
    final currentIds = _currentSessionQueue.map((e) => e.wordId).toSet();

    if (_currentSessionQueue.isEmpty || dueIds.difference(currentIds).isNotEmpty || currentIds.difference(dueIds).isNotEmpty) {
      // Re-initialize queue with a single shuffle
      _currentSessionQueue = List<WordProgress>.from(due)..shuffle();
      _preparedQuestions.clear();
      _completedQuestions.clear();
    }

    // Pre-make the first 5 questions immediately in background
    for (int i = 0; i < 5 && i < _currentSessionQueue.length; i++) {
      getOrPrepareQuestion(i, context: context);
    }
  }

  Future<PreparedReviewQuestion?> getOrPrepareQuestion(int index, {BuildContext? context}) {
    if (index >= _currentSessionQueue.length) return Future.value(null);
    if (_completedQuestions.containsKey(index)) return Future.value(_completedQuestions[index]);
    return _preparedQuestions.putIfAbsent(index, () => _buildPreparedQuestion(index, context: context));
  }

  void deleteExampleAudio(int index) {
    final q = _completedQuestions[index];
    if (q != null && q.exampleAudioPath != null) {
      _deleteAudioFile(q.exampleAudioPath);
    }
  }

  void _deleteAudioFile(String? path) {
    if (kIsWeb || path == null || path.isEmpty || path.startsWith('http') || path.startsWith('data:')) return;
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.delete().catchError((_) => file);
      }
    } catch (_) {}
  }

  void resetSession() {
    for (final q in _completedQuestions.values) {
      _deleteAudioFile(q.exampleAudioPath);
    }
    _currentSessionQueue.clear();
    _preparedQuestions.clear();
    _completedQuestions.clear();
  }

  List<DictWord> getRelevantDistractors(int count, {required int excludeId}) {
    final progress = ProgressService();
    final Set<int> candidateIds = {};

    for (var lp in progress.learningWords) {
      if (lp.wordId != excludeId) candidateIds.add(lp.wordId);
    }
    for (var qId in progress.queuedWordsToLearn) {
      if (qId != excludeId) candidateIds.add(qId);
    }

    final List<DictWord> pool = [];
    for (var id in candidateIds) {
      final w = DatabaseService.getWordById(id);
      if (w != null) pool.add(w);
    }

    pool.shuffle();
    final List<DictWord> results = pool.take(count).toList();

    if (results.length < count) {
      final existingIds = results.map((w) => w.id).toSet()..add(excludeId);
      final randomTop = DatabaseService.getRandomWords(count - results.length + 5);
      for (var rw in randomTop) {
        if (!existingIds.contains(rw.id)) {
          results.add(rw);
          existingIds.add(rw.id);
          if (results.length >= count) break;
        }
      }
    }

    return results;
  }

  Future<PreparedReviewQuestion?> _buildPreparedQuestion(int index, {BuildContext? context}) async {
    if (index >= _currentSessionQueue.length) return null;
    final p = _currentSessionQueue[index];
    final word = DatabaseService.getWordById(p.wordId);
    if (word == null) return null;

    // 1. Fetch / resolve WordData JSON
    WordData? wordData;
    try {
      final json = await WordupApi.fetchWordData(word.id.toString(), wordText: word.text, isPrefetch: true);
      if (json.isNotEmpty) {
        wordData = WordData.fromJson(word.id, json);
      }
    } catch (_) {}

    // 2. Pre-cache word illustration into RAM + disk
    String? displayImageUrl;
    if (wordData != null) {
      List<String> availableImages = [];
      if (wordData.imageUrl != null && wordData.imageUrl!.isNotEmpty) {
        availableImages.add(wordData.imageUrl!);
      }
      for (var sense in wordData.senses) {
        if (sense.imageUrl != null && sense.imageUrl!.isNotEmpty) availableImages.add(sense.imageUrl!);
        for (var tip in sense.tips) {
          if (tip.imageUrl != null && tip.imageUrl!.isNotEmpty) availableImages.add(tip.imageUrl!);
        }
      }
      availableImages = availableImages.toSet().toList();

      if (availableImages.isNotEmpty) {
        final preferredUrl = ProgressService().getPreferredImage(word.id);
        displayImageUrl = (preferredUrl != null && availableImages.contains(preferredUrl))
            ? preferredUrl
            : availableImages.first;

        try {
          final cachedFile = await MediaCacheService.ensureMediaCached(word.id, displayImageUrl);
          ImageProvider provider;
          if (cachedFile != null && cachedFile.existsSync()) {
            provider = FileImage(cachedFile);
          } else {
            provider = NetworkImage(displayImageUrl);
          }
          final stream = provider.resolve(ImageConfiguration.empty);
          stream.addListener(ImageStreamListener((_, _) {}, onError: (_, _) {}));
          if (context != null && context.mounted) {
            await precacheImage(provider, context).catchError((_) {});
          }
        } catch (_) {}
      }
    }

    // 3. Pre-fetch and await pronunciation audio + sentence audio
    String? wordAudioPath;
    try {
      wordAudioPath = await WordupApi.getAudioPath(
        word.id.toString(),
        wordText: word.text,
        isUk: false,
        useGoogleTts: false,
      );
    } catch (_) {}

    String? exampleText;
    String? exampleAudioPath;
    if (wordData != null) {
      for (final sense in wordData.senses) {
        if (sense.ex.trim().isNotEmpty) {
          exampleText = sense.ex.trim();
          break;
        }
      }
      if (exampleText != null && exampleText.isNotEmpty) {
        final sentenceText = 'For example, $exampleText';
        try {
          exampleAudioPath = await WordupApi.getSentenceAudioPath(
            sentenceText,
            isUk: false,
          );
        } catch (_) {}
      }
    }

    // 4. Pre-make ALL available question type variants for instant shuffle
    final settings = SettingsService();
    List<String> types = [];
    if (settings.enableMeaningQuestion) types.add('meaning');
    if (settings.enableQuoteQuestion && wordData != null && wordData.quotes.isNotEmpty) types.add('quote');
    if (settings.enableSynonymQuestion && wordData != null && wordData.senses.any((s) => s.sy.isNotEmpty)) types.add('synonym');
    if (settings.enableAntonymQuestion && wordData != null && wordData.senses.any((s) => s.op.isNotEmpty)) types.add('antonym');
    if (settings.enableExampleQuestion && wordData != null && wordData.senses.any((s) => s.ex.isNotEmpty)) types.add('example');
    if (settings.enableMisspellingQuestion && wordData != null && wordData.misspellings.isNotEmpty) types.add('misspelling');
    if (settings.enableSpellingQuestion) types.add('listening');
    if (settings.enableCompareQuestion && wordData != null && wordData.comparisons.isNotEmpty) types.add('compare');

    if (types.isEmpty) types.add('meaning');
    types.shuffle();

    final List<QuestionTypeVariant> variants = [];
    for (var type in types) {
      final v = _generateVariant(type, word, wordData);
      if (v != null) variants.add(v);
    }
    if (variants.isEmpty) {
      final fallback = _generateVariant('meaning', word, wordData);
      if (fallback != null) variants.add(fallback);
    }

    final prepared = PreparedReviewQuestion(
      word: word,
      wordData: wordData,
      variants: variants,
      currentVariantIndex: 0,
      displayImageUrl: displayImageUrl,
      wordAudioPath: wordAudioPath,
      exampleAudioPath: exampleAudioPath,
      exampleText: exampleText,
    );
    _completedQuestions[index] = prepared;
    return prepared;
  }

  QuestionTypeVariant? _generateVariant(String type, DictWord word, WordData? data) {
    dynamic questionData;
    List<ReviewOption> options = [];
    final distractors = getRelevantDistractors(3, excludeId: word.id);

    if (type == 'meaning' || type == 'listening') {
      options.add(ReviewOption(word.id, word.meaning, true));
      for (var d in distractors) {
        options.add(ReviewOption(d.id, d.meaning, false));
      }
    } else if (type == 'quote' || type == 'example') {
      final isQuote = type == 'quote';
      if (isQuote) {
        if (data == null || data.quotes.isEmpty) return null;
        final quote = (data.quotes.toList()..shuffle()).first;
        questionData = quote;
      } else {
        if (data == null || !data.senses.any((s) => s.ex.isNotEmpty)) return null;
        final sense = data.senses.firstWhere((s) => s.ex.isNotEmpty);
        questionData = sense.ex;
      }
      options.add(ReviewOption(word.id, word.text, true));
      for (var d in distractors) {
        options.add(ReviewOption(d.id, d.text, false));
      }
    } else if (type == 'synonym' || type == 'antonym') {
      final isSynonym = type == 'synonym';
      if (data == null || !data.senses.any((s) => isSynonym ? s.sy.isNotEmpty : s.op.isNotEmpty)) return null;
      final sense = data.senses.firstWhere((s) => isSynonym ? s.sy.isNotEmpty : s.op.isNotEmpty);
      final rawList = isSynonym ? sense.sy : sense.op;
      final targetWords = rawList.split(',').map((e) => e.trim()).toList()..shuffle();
      final correctText = targetWords.take(3).join(', ');
      questionData = correctText;

      options.add(ReviewOption(word.id, correctText, true));
      for (var d in distractors) {
        options.add(ReviewOption(d.id, d.text, false));
      }
    } else if (type == 'compare') {
      if (data == null || data.comparisons.isEmpty) return null;
      final comp = (data.comparisons.toList()..shuffle()).first;
      questionData = comp;
      options.add(ReviewOption(word.id, word.text, true));
      options.add(ReviewOption(-1, comp.word, false));
      final dist2 = getRelevantDistractors(2, excludeId: word.id);
      options.add(ReviewOption(dist2[0].id, dist2[0].text, false));
      if (dist2.length > 1) {
        options.add(ReviewOption(dist2[1].id, dist2[1].text, false));
      }
    } else if (type == 'misspelling') {
      if (data == null || data.misspellings.isEmpty) return null;
      List<String> miss = data.misspellings.split(RegExp(r'[,|]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      miss.shuffle();
      List<String> selectedMiss = miss.take(3).toList();
      while (selectedMiss.length < 3) {
        String fake = _generateFakeMisspelling(word.text, selectedMiss.length);
        if (!selectedMiss.contains(fake) && fake != word.text) {
          selectedMiss.add(fake);
        }
      }
      options.add(ReviewOption(word.id, word.text, true));
      for (int i = 0; i < selectedMiss.length; i++) {
        options.add(ReviewOption(-1, selectedMiss[i], false));
      }
    }

    options.shuffle();
    return QuestionTypeVariant(type: type, options: options, questionData: questionData);
  }

  String _generateFakeMisspelling(String word, int seed) {
    if (word.length <= 3) return word + 'e';
    final chars = word.split('');
    final idx = 1 + ((DateTime.now().millisecondsSinceEpoch + seed) % (chars.length - 2));
    final tmp = chars[idx];
    chars[idx] = chars[idx + 1];
    chars[idx + 1] = tmp;
    return chars.join('');
  }
}
