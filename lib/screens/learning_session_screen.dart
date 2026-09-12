import 'package:flutter/material.dart';
import 'dart:math';
import '../services/progress_service.dart';
import '../services/settings_service.dart';
import '../services/database_service.dart';
import '../services/wordup_api.dart';
import '../models/word.dart';
import 'package:audioplayers/audioplayers.dart';
import 'word_view_screen.dart';

class ReviewOption {
  final int id;
  final String text;
  final bool isCorrect;
  ReviewOption(this.id, this.text, this.isCorrect);
}

enum SessionStep { view, test, finished }

class LearningSessionScreen extends StatefulWidget {
  @override
  _LearningSessionScreenState createState() => _LearningSessionScreenState();
}

class _LearningSessionScreenState extends State<LearningSessionScreen> {
  final ProgressService _progressService = ProgressService();
  
  List<int> _queue = [];
  List<int> _recentViews = [];
  List<int> _testQueue = [];
  Set<int> _graduated = {};
  
  SessionStep _currentStep = SessionStep.view;
  int? _currentWordId;
  
  // Test State
  bool _isLoadingTest = false;
  DictWord? _currentDictWord;
  String _currentQuestionType = '';
  List<ReviewOption> _currentOptions = [];
  int? _selectedOptionId;
  bool? _wasCorrect;
  WordData? _currentWordData;
  dynamic _questionData;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _queue = List<int>.from(_progressService.queuedWordsToLearn);
    if (_queue.length > 1) {
      final first = _queue.removeAt(0);
      _queue.shuffle();
      _queue.insert(0, first);
    }
    
    if (_queue.isEmpty) {
      _currentStep = SessionStep.finished;
    } else {
      _prefetchUpcomingWords();
      _nextAction();
    }
  }

  void _prefetchUpcomingWords() {
    final upcomingIds = <int>[];
    
    // 1. Next in test queue if any
    for (final id in _testQueue) {
      if (!upcomingIds.contains(id)) {
        upcomingIds.add(id);
      }
      if (upcomingIds.length >= 2) break;
    }

    // 2. Next in new words learning queue if needed
    if (upcomingIds.length < 2) {
      for (final id in _queue) {
        if (!upcomingIds.contains(id)) {
          upcomingIds.add(id);
        }
        if (upcomingIds.length >= 2) break;
      }
    }

    for (final id in upcomingIds) {
      WordupApi.prefetchWord(id, includeMedia: true, includeAudio: true);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _nextAction() {
    _prefetchUpcomingWords();
    if (_testQueue.isNotEmpty) {
      // Next is a test
      setState(() {
        _currentStep = SessionStep.test;
        _currentWordId = _testQueue.removeAt(0);
        _isLoadingTest = true;
        _selectedOptionId = null;
        _wasCorrect = null;
      });
      _generateQuestionFor(_currentWordId!);
    } else {
      // Finished batch of tests, time to view a new word
      
      // If queue is empty, recycle any words in _recentViews that never graduated
      if (_queue.isEmpty) {
        for (var id in _recentViews) {
          if (!_graduated.contains(id)) {
            _queue.add(id);
          }
        }
        _recentViews.clear();
      }
      
      if (_queue.isNotEmpty) {
        final newWord = _queue.removeAt(0);
        
        _recentViews.add(newWord);
        if (_recentViews.length > 4) {
          final oldest = _recentViews.removeAt(0);
          if (!_graduated.contains(oldest)) {
            _queue.add(oldest); // Put back to the end of the queue to learn again
          }
        }
        
        // Schedule tests: All words in the 4-word window, no matter if they graduated or not!
        _testQueue.clear();
        _testQueue.addAll(_recentViews);
        _testQueue.shuffle(); // Shuffle tests so order is unpredictable
        
        setState(() {
          _currentStep = SessionStep.view;
          _currentWordId = newWord;
        });
      } else {
        // Completely done! All words graduated!
        setState(() {
          _currentStep = SessionStep.finished;
        });
      }
    }
  }

  String _generateFakeMisspelling(String correctWord, int attempt) {
    if (correctWord.length < 3) return correctWord + (attempt == 0 ? 's' : 'ed');
    final vowels = ['a', 'e', 'i', 'o', 'u'];
    String modified = correctWord;
    
    for (int i = modified.length - 1; i >= 0; i--) {
      if (vowels.contains(modified[i].toLowerCase())) {
        String rep = vowels[(vowels.indexOf(modified[i].toLowerCase()) + attempt + 1) % vowels.length];
        modified = modified.substring(0, i) + rep + modified.substring(i + 1);
        break;
      }
    }
    
    if (modified == correctWord) {
      if (modified.contains('c')) return modified.replaceFirst('c', 'k');
      if (modified.contains('s')) return modified.replaceFirst('s', 'c');
      return modified + (attempt == 0 ? 'e' : 'ly');
    }
    return modified;
  }

  Future<void> _generateQuestionFor(int wordId) async {
    final word = DatabaseService.getWordById(wordId);
    if (word == null) {
      _nextAction();
      return;
    }

    WordData? data;
    try {
      final json = await WordupApi.fetchWordData(word.id.toString(), wordText: word.text);
      data = WordData.fromJson(word.id, json);
    } catch (_) {}

    final settings = SettingsService();
    List<String> availableTypes = [];
    
    if (settings.enableMeaningQuestion) availableTypes.add('meaning');
    if (settings.enableQuoteQuestion && data != null && data.quotes.isNotEmpty) availableTypes.add('quote');
    if (settings.enableSynonymQuestion && data != null && data.senses.any((s) => s.sy.isNotEmpty)) availableTypes.add('synonym');
    if (settings.enableAntonymQuestion && data != null && data.senses.any((s) => s.op.isNotEmpty)) availableTypes.add('antonym');
    if (settings.enableExampleQuestion && data != null && data.senses.any((s) => s.ex.isNotEmpty)) availableTypes.add('example');
    if (settings.enableMisspellingQuestion && data != null && data.misspellings.isNotEmpty) availableTypes.add('misspelling');
    if (settings.enableSpellingQuestion) availableTypes.add('listening');
    final comparePattern = RegExp(r'\b' + RegExp.escape(word.text) + r'(s|es|ed|ing|d)?\b', caseSensitive: false);
    if (settings.enableCompareQuestion && data != null && data.comparisons.any((c) => comparePattern.hasMatch(c.text))) {
      availableTypes.add('compare');
    }
    
    if (availableTypes.isEmpty) availableTypes.add('meaning');
    
    availableTypes.shuffle();
    final type = availableTypes.first;
    
    dynamic questionData;
    List<ReviewOption> options = [];
    final distractors = DatabaseService.getRandomWords(3, excludeId: word.id);
    
    if (type == 'meaning' || type == 'listening') {
      options.add(ReviewOption(word.id, word.meaning, true));
      for (var d in distractors) {
        options.add(ReviewOption(d.id, d.meaning, false));
      }
      if (type == 'listening') {
        _playAudio(word.id.toString(), word.text);
      }
    } else if (type == 'quote' || type == 'example') {
      final isQuote = type == 'quote';
      String text;
      
      if (isQuote) {
        final quote = (data!.quotes.toList()..shuffle()).first;
        questionData = quote;
        text = quote.text;
      } else {
        final sense = data!.senses.firstWhere((s) => s.ex.isNotEmpty);
        questionData = sense.ex;
        text = sense.ex;
      }
      
      options.add(ReviewOption(word.id, word.text, true));
      for (var d in distractors) {
        options.add(ReviewOption(d.id, d.text, false));
      }
    } else if (type == 'synonym' || type == 'antonym') {
      final isSynonym = type == 'synonym';
      final sense = data!.senses.firstWhere((s) => isSynonym ? s.sy.isNotEmpty : s.op.isNotEmpty);
      final rawList = isSynonym ? sense.sy : sense.op;
      
      final targetWords = rawList
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && e.toLowerCase() != 'none' && e.toLowerCase() != 'null' && e.toLowerCase() != 'n/a')
          .toList()
        ..shuffle();
      if (targetWords.isEmpty) return;
      final correctText = targetWords.take(3).join(', ');
      
      questionData = correctText;
      options.add(ReviewOption(word.id, correctText, true));

      final potentialDistractors = DatabaseService.getRandomWords(10, excludeId: word.id);
      
      List<String> distractorTexts = [];
      await Future.wait(potentialDistractors.map((d) async {
        if (distractorTexts.length >= 3) return;
        try {
          final json = await WordupApi.fetchWordData(d.id.toString(), wordText: d.text);
          final wd = WordData.fromJson(d.id, json);
          final dSense = wd.senses.firstWhere((s) => isSynonym ? s.sy.isNotEmpty : s.op.isNotEmpty, orElse: () => WordSense(id: '', de: '', ex: '', ty: ''));
          final dRawList = isSynonym ? dSense.sy : dSense.op;
          if (dRawList.isNotEmpty) {
            final dWords = dRawList
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty && e.toLowerCase() != 'none' && e.toLowerCase() != 'null' && e.toLowerCase() != 'n/a')
                .toList()
              ..shuffle();
            if (dWords.isNotEmpty) {
              final text = dWords.take(3).join(', ');
              if (!distractorTexts.contains(text) && text != correctText && distractorTexts.length < 3) {
                distractorTexts.add(text);
              }
            }
          }
        } catch (_) {}
      }));
      
      while (distractorTexts.length < 3) {
        final fakes = DatabaseService.getRandomWords(6, excludeId: word.id)
            .map((w) => w.text.trim())
            .where((w) => w.isNotEmpty && w.toLowerCase() != 'none' && w.toLowerCase() != word.text.toLowerCase())
            .take(3)
            .toList();
        if (fakes.length == 3) {
          final text = fakes.join(', ');
          if (!distractorTexts.contains(text) && text != correctText) {
            distractorTexts.add(text);
          }
        }
      }
      
      for (var i = 0; i < 3; i++) {
        options.add(ReviewOption(distractors[i].id, distractorTexts[i], false));
      }
    } else if (type == 'compare') {
      final pattern = RegExp(r'\b' + RegExp.escape(word.text) + r'(s|es|ed|ing|d)?\b', caseSensitive: false);
      final validComps = data!.comparisons.where((c) => pattern.hasMatch(c.text)).toList();
      final comp = (validComps..shuffle()).first;
      questionData = comp;

      final Set<String> excludeWords = data.comparisons.map((c) => c.word.trim().toLowerCase()).toSet();
      excludeWords.add(word.text.trim().toLowerCase());

      options.add(ReviewOption(word.id, word.text, true));

      final Set<int> candidateIds = {};
      for (var lp in _progressService.learningWords) {
        if (lp.wordId != word.id) candidateIds.add(lp.wordId);
      }
      for (var qId in _progressService.queuedWordsToLearn) {
        if (qId != word.id) candidateIds.add(qId);
      }

      final List<DictWord> pool = [];
      for (var id in candidateIds) {
        final w = DatabaseService.getWordById(id);
        if (w != null && !excludeWords.contains(w.text.trim().toLowerCase())) {
          pool.add(w);
        }
      }
      pool.shuffle();
      final dist = pool.take(3).toList();
      if (dist.length < 3) {
        final randomWords = DatabaseService.getRandomWords(15, excludeId: word.id);
        for (var rw in randomWords) {
          if (!excludeWords.contains(rw.text.trim().toLowerCase()) && !dist.any((d) => d.id == rw.id)) {
            dist.add(rw);
            if (dist.length >= 3) break;
          }
        }
      }
      for (var d in dist) {
        options.add(ReviewOption(d.id, d.text, false));
      }
    } else if (type == 'misspelling') {
      List<String> miss = data!.misspellings.split(RegExp(r'[,|]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      miss.shuffle();
      
      List<String> selectedMiss = miss.take(3).toList();
      while (selectedMiss.length < 3) {
        String fake = _generateFakeMisspelling(word.text, selectedMiss.length);
        if (!selectedMiss.contains(fake) && fake != word.text) {
          selectedMiss.add(fake);
        }
      }
      
      options.add(ReviewOption(word.id, word.text, true));
      for (int i = 0; i < 3; i++) {
        options.add(ReviewOption(-1, selectedMiss[i], false));
      }
      _playAudio(word.id.toString(), word.text);
    }
    
    options.shuffle();

    if (mounted) {
      setState(() {
        _currentDictWord = word;
        _currentQuestionType = type;
        _currentOptions = options;
        _currentWordData = data;
        _questionData = questionData;
        _isLoadingTest = false;
      });
    }
  }

  Future<void> _playAudio(String wordId, String text) async {
    try {
      final path = await WordupApi.getAudioPath(wordId, wordText: text, isUk: false, useGoogleTts: false);
      if (path.startsWith('http')) {
        await _audioPlayer.play(UrlSource(path));
      } else {
        await _audioPlayer.play(DeviceFileSource(path));
      }
    } catch (_) {}
  }

  void _submitAnswer(int selectedId, bool isCorrect) async {
    if (_currentDictWord == null || _selectedOptionId != null) return;
    
    setState(() {
      _selectedOptionId = selectedId;
      _wasCorrect = isCorrect;
    });

    if (isCorrect) {
      _audioPlayer.play(AssetSource('sounds/success.mp3'));
      
      // Graduate the word from the session!
      if (!_graduated.contains(_currentDictWord!.id)) {
        _graduated.add(_currentDictWord!.id);
        await _progressService.graduateWord(_currentDictWord!.id);
      }
      // Note: We do NOT remove it from _recentViews so it stays in the testing window!
      
    } else {
      _audioPlayer.play(AssetSource('sounds/fail.mp3'));
      // Stays in _activeWords
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep == SessionStep.finished) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        backgroundColor: Color(0xFF1E1B4B),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.celebration, color: Colors.amber, size: 80),
              SizedBox(height: 24),
              Text('Session Complete!', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text('All queued words processed.', style: TextStyle(color: Colors.white70, fontSize: 18)),
              SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text('Return Home', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentStep == SessionStep.view) {
      // Use the standard WordViewScreen but override the bottom bar
      return WordViewScreen(
        key: ValueKey('view_${_currentWordId}'), // Ensure it rebuilds for new words
        wordId: _currentWordId!,
        bottomNavigationBarOverride: _buildContinueButton(),
      );
    }

    // Otherwise, we are in Test mode
    return Scaffold(
      appBar: AppBar(
        title: Text('Test', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Color(0xFF1E1B4B),
      body: _isLoadingTest 
          ? Center(child: CircularProgressIndicator(color: Colors.cyan))
          : _buildTestBody(),
    );
  }

  Widget _buildContinueButton() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 800),
            child: Container(
              margin: EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ElevatedButton(
                onPressed: () {
                  _nextAction();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Got It - Start Testing', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestBody() {
    if (_currentDictWord == null) return Container();
    
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Question Area
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildQuestionContent(),
                ),
                
                // Options Area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ..._currentOptions.map((opt) {
                      bool isSelected = _selectedOptionId == opt.id;
                      bool isCorrectOption = opt.isCorrect;
                      
                      Color bgColor = Colors.white.withOpacity(0.05);
                      Color borderColor = Colors.white.withOpacity(0.1);
                      
                      if (_selectedOptionId != null) {
                        if (isCorrectOption) {
                          bgColor = Colors.green.withOpacity(0.2);
                          borderColor = Colors.green;
                        } else if (isSelected && !isCorrectOption) {
                          bgColor = Colors.red.withOpacity(0.2);
                          borderColor = Colors.red;
                        }
                      }
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        width: double.infinity,
                        child: InkWell(
                          onTap: () => _submitAnswer(opt.id, opt.isCorrect),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor, width: 2),
                            ),
                            child: Text(
                              opt.text,
                              style: TextStyle(color: Colors.white, fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    
                    if (_selectedOptionId != null)
                      Container(
                        margin: EdgeInsets.only(top: 24),
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _nextAction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan,
                            padding: EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text('Next', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionContent() {
    final type = _currentQuestionType;
    final word = _currentDictWord!;
    
    if (type == 'meaning') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('What is the meaning of', style: TextStyle(color: Colors.white70, fontSize: 18)),
          SizedBox(height: 16),
          Text(word.text.toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ],
      );
    } else if (type == 'quote' && _questionData != null) {
      final quote = _questionData as WordQuote;
      final text = quote.text.replaceAll(RegExp(word.text, caseSensitive: false), '______');
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Complete the quote', style: TextStyle(color: Colors.white70, fontSize: 18)),
          SizedBox(height: 24),
          Icon(Icons.format_quote, color: Colors.cyan.withOpacity(0.5), size: 48),
          SizedBox(height: 16),
          Text(text, style: TextStyle(color: Colors.white, fontSize: 24, height: 1.4), textAlign: TextAlign.center),
          SizedBox(height: 16),
          Text('- ${quote.authorName}', style: TextStyle(color: Colors.white54, fontSize: 16, fontStyle: FontStyle.italic)),
        ],
      );
    } else if (type == 'example' && _questionData != null) {
      final text = (_questionData as String).replaceAll(RegExp(word.text, caseSensitive: false), '______');
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Complete the sentence', style: TextStyle(color: Colors.white70, fontSize: 18)),
          SizedBox(height: 24),
          Text(text, style: TextStyle(color: Colors.white, fontSize: 24, height: 1.4), textAlign: TextAlign.center),
        ],
      );
    } else if (type == 'synonym') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Which of these are synonyms for', style: TextStyle(color: Colors.white70, fontSize: 18)),
          SizedBox(height: 16),
          Text(word.text.toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ],
      );
    } else if (type == 'antonym') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Which of these are antonyms for', style: TextStyle(color: Colors.white70, fontSize: 18)),
          SizedBox(height: 16),
          Text(word.text.toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ],
      );
    } else if (type == 'listening') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Listen and choose the meaning', style: TextStyle(color: Colors.white70, fontSize: 18)),
          SizedBox(height: 32),
          InkWell(
            onTap: () => _playAudio(word.id.toString(), word.text),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.cyan.withOpacity(0.1),
                border: Border.all(color: Colors.cyan, width: 2),
              ),
              child: Icon(Icons.volume_up, color: Colors.cyan, size: 64),
            ),
          ),
          SizedBox(height: 16),
          if (_selectedOptionId != null)
            Text(word.text.toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      );
    } else if (type == 'compare' && _questionData != null) {
      final comp = _questionData as WordComparison;
      final pattern = RegExp(r'\b' + RegExp.escape(word.text) + r'(s|es|ed|ing|d)?\b', caseSensitive: false);
      final masked = comp.text.replaceAll(pattern, '_______');
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Fill in the blank for this comparison:', style: TextStyle(color: Colors.white70, fontSize: 18)),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(masked, style: TextStyle(color: Colors.white, fontSize: 20, height: 1.4), textAlign: TextAlign.center),
          ),
        ],
      );
    } else if (type == 'misspelling') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Choose the correct spelling', style: TextStyle(color: Colors.white70, fontSize: 18)),
          SizedBox(height: 32),
          InkWell(
            onTap: () => _playAudio(word.id.toString(), word.text),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.cyan.withOpacity(0.1),
                border: Border.all(color: Colors.cyan, width: 2),
              ),
              child: Icon(Icons.volume_up, color: Colors.cyan, size: 48),
            ),
          ),
        ],
      );
    }
    
    return Text('Unknown question type: $type', style: TextStyle(color: Colors.red));
  }
}
