import 'dart:async';
import 'package:flutter/material.dart';
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

class ReviewScreen extends StatefulWidget {
  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final ProgressService _progressService = ProgressService();
  
  List<WordProgress> _dueWords = [];
  int _currentIndex = 0;
  DictWord? _currentDictWord;
  bool _isLoading = true;
  String _currentQuestionType = '';
  List<ReviewOption> _currentOptions = [];
  int? _selectedOptionId;
  bool? _wasCorrect;
  bool _showWordDetails = false;
  WordData? _currentWordData;
  dynamic _questionData; // stores extra context (e.g. quote text) for the current question
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  @override
  void initState() {
    super.initState();
    _loadDueWords();
  }

  @override
  void dispose() {
    _stopAllAudio();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _loadDueWords() {
    setState(() {
      _dueWords = _progressService.dueWords;
      _dueWords.shuffle(); // Shuffle for random review order
      _currentIndex = 0;
    });
    _prefetchUpcomingWords();
    _loadNextWord();
  }

  void _prefetchUpcomingWords() {
    // Proactively prefetch the next two words in line
    for (int offset = 1; offset <= 2; offset++) {
      final nextIdx = _currentIndex + offset;
      if (nextIdx < _dueWords.length) {
        final nextWordId = _dueWords[nextIdx].wordId;
        WordupApi.prefetchWord(nextWordId);
      }
    }
  }

  Future<void> _loadNextWord() async {
    _prefetchUpcomingWords();
    if (_currentIndex >= _dueWords.length) {
      setState(() {
        _isLoading = false;
        _currentDictWord = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final p = _dueWords[_currentIndex];
    final word = DatabaseService.getWordById(p.wordId);
    
    // Fetch WordData to decide question types
    WordData? wordData;
    try {
      final json = await WordupApi.fetchWordData(word!.id.toString(), wordText: word.text);
      wordData = WordData.fromJson(word.id, json);
    } catch (_) {}

    // Pick a random question type based on settings and available data in word
    await _generateQuestion(word!, wordData);
  }

  Future<void> _generateQuestion(DictWord word, WordData? data) async {
    final settings = SettingsService();
    List<String> availableTypes = [];
    
    if (settings.enableMeaningQuestion) availableTypes.add('meaning');
    if (settings.enableQuoteQuestion && data != null && data.quotes.isNotEmpty) availableTypes.add('quote');
    if (settings.enableSynonymQuestion && data != null && data.senses.any((s) => s.sy.isNotEmpty)) availableTypes.add('synonym');
    if (settings.enableAntonymQuestion && data != null && data.senses.any((s) => s.op.isNotEmpty)) availableTypes.add('antonym');
    if (settings.enableExampleQuestion && data != null && data.senses.any((s) => s.ex.isNotEmpty)) availableTypes.add('example');
    if (settings.enableMisspellingQuestion && data != null && data.misspellings.isNotEmpty) availableTypes.add('misspelling');
    if (settings.enableSpellingQuestion) availableTypes.add('listening');
    if (settings.enableCompareQuestion && data != null && data.comparisons.isNotEmpty) availableTypes.add('compare');
    
    if (availableTypes.isEmpty) availableTypes.add('meaning'); // Fallback
    
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
      _playAudio(word.id.toString(), word.text);
    } else if (type == 'quote' || type == 'example') {
      final isQuote = type == 'quote';
      
      if (isQuote) {
        final quote = (data!.quotes.toList()..shuffle()).first;
        questionData = quote;
      } else {
        final sense = data!.senses.firstWhere((s) => s.ex.isNotEmpty);
        questionData = sense.ex;
      }
      
      options.add(ReviewOption(word.id, word.text, true));
      for (var d in distractors) {
        options.add(ReviewOption(d.id, d.text, false));
      }
    } else if (type == 'synonym' || type == 'antonym') {
      final isSynonym = type == 'synonym';
      final sense = data!.senses.firstWhere((s) => isSynonym ? s.sy.isNotEmpty : s.op.isNotEmpty);
      final rawList = isSynonym ? sense.sy : sense.op;
      
      final targetWords = rawList.split(',').map((e) => e.trim()).toList()..shuffle();
      final correctText = targetWords.take(3).join(', ');
      
      questionData = correctText; // Just store it, we don't strictly use questionData for the UI in these types but good for consistency
      options.add(ReviewOption(word.id, correctText, true));

      // Fetch 10 random words to find distractors that have synonyms/antonyms
      final potentialDistractors = DatabaseService.getRandomWords(10, excludeId: word.id);
      
      List<String> distractorTexts = [];
      await Future.wait(potentialDistractors.map((d) async {
        if (distractorTexts.length >= 3) return; // We already have enough
        try {
          final json = await WordupApi.fetchWordData(d.id.toString(), wordText: d.text);
          final wd = WordData.fromJson(d.id, json);
          final dSense = wd.senses.firstWhere((s) => isSynonym ? s.sy.isNotEmpty : s.op.isNotEmpty, orElse: () => WordSense(id: '', de: '', ex: '', ty: ''));
          final dRawList = isSynonym ? dSense.sy : dSense.op;
          if (dRawList.isNotEmpty) {
            final dWords = dRawList.split(',').map((e) => e.trim()).toList()..shuffle();
            final text = dWords.take(3).join(', ');
            if (!distractorTexts.contains(text) && distractorTexts.length < 3) {
              distractorTexts.add(text);
            }
          }
        } catch (_) {}
      }));
      
      // If we couldn't find enough real distractors with synonyms/antonyms, fake them
      while (distractorTexts.length < 3) {
        final fakes = DatabaseService.getRandomWords(3).map((w) => w.text).toList();
        distractorTexts.add(fakes.join(', '));
      }
      
      for (var i = 0; i < 3; i++) {
        options.add(ReviewOption(distractors[i].id, distractorTexts[i], false));
      }
      _playAudio(word.id.toString(), word.text);
    } else if (type == 'compare') {
      final comp = (data!.comparisons.toList()..shuffle()).first;
      questionData = comp;
      options.add(ReviewOption(word.id, word.text, true));
      options.add(ReviewOption(-1, comp.word, false)); // The word being compared to
      final dist2 = DatabaseService.getRandomWords(2, excludeId: word.id);
      options.add(ReviewOption(dist2[0].id, dist2[0].text, false));
      options.add(ReviewOption(dist2[1].id, dist2[1].text, false));
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
        _selectedOptionId = null;
        _wasCorrect = null;
        _showWordDetails = false;
        _currentWordData = data;
        _questionData = questionData;
        _isLoading = false;
      });
    }
  }

  int _audioSequenceId = 0;

  void _stopAllAudio() {
    _audioSequenceId++;
    _audioPlayer.stop();
  }

  String _getCurrentExample() {
    if (_currentWordData != null && _currentWordData!.senses.isNotEmpty) {
      return _currentWordData!.senses.first.ex;
    }
    return '';
  }

  Future<void> _playAudio(String wordId, String text) async {
    _stopAllAudio();
    try {
      final path = await WordupApi.getAudioPath(wordId, wordText: text, isUk: false, useGoogleTts: false);
      if (path.isNotEmpty) {
        if (path.startsWith('http')) {
          await _audioPlayer.play(UrlSource(path));
        } else {
          await _audioPlayer.play(DeviceFileSource(path));
        }
      }
    } catch (_) {}
  }

  Future<void> _playExampleAudio(String exampleText) async {
    _stopAllAudio();
    try {
      final path = await WordupApi.getSentenceAudioPath(exampleText, isUk: false);
      if (path.isNotEmpty) {
        if (path.startsWith('http')) {
          await _audioPlayer.play(UrlSource(path));
        } else {
          await _audioPlayer.play(DeviceFileSource(path));
        }
      }
    } catch (_) {}
  }

  Future<void> _playReviewAutoSequence() async {
    final currentSeq = ++_audioSequenceId;
    final word = _currentDictWord;
    if (word == null) return;

    // Prefetch sentence audio in parallel while the word audio is loading & playing
    final sentenceAudioFuture = () async {
      try {
        String example = _getCurrentExample();
        if (example.isEmpty && _currentWordData == null) {
          final json = await WordupApi.fetchWordData(word.id.toString(), wordText: word.text);
          if (currentSeq != _audioSequenceId || !mounted) return null;
          final data = WordData.fromJson(word.id, json);
          if (data.senses.isNotEmpty) {
            example = data.senses.first.ex;
          }
        }
        if (example.trim().isNotEmpty) {
          final sentenceText = 'For example, $example';
          return await WordupApi.getSentenceAudioPath(sentenceText, isUk: false);
        }
      } catch (_) {}
      return null;
    }();

    // 1. Play the word pronunciation (US dict audio)
    try {
      final wordAudioPath = await WordupApi.getAudioPath(
        word.id.toString(),
        wordText: word.text,
        isUk: false,
        useGoogleTts: false,
      );
      if (currentSeq != _audioSequenceId || !mounted) return;

      if (wordAudioPath.isNotEmpty) {
        if (wordAudioPath.startsWith('http')) {
          await _audioPlayer.play(UrlSource(wordAudioPath));
        } else {
          await _audioPlayer.play(DeviceFileSource(wordAudioPath));
        }

        final completer = Completer<void>();
        late final StreamSubscription sub;
        sub = _audioPlayer.onPlayerComplete.listen((_) {
          if (!completer.isCompleted) completer.complete();
        });

        await Future.any([
          completer.future,
          Future.delayed(const Duration(seconds: 5)),
        ]);
        await sub.cancel();
      }
    } catch (_) {}

    if (currentSeq != _audioSequenceId || !mounted) return;

    // 2. Pause ~170ms between word and example
    await Future.delayed(const Duration(milliseconds: 170));
    if (currentSeq != _audioSequenceId || !mounted) return;

    // 3. Play "For example, [example sentence]" if available (using prefetched audio)
    try {
      final exampleAudioPath = await sentenceAudioFuture;
      if (currentSeq != _audioSequenceId || !mounted) return;

      if (exampleAudioPath != null && exampleAudioPath.isNotEmpty) {
        if (exampleAudioPath.startsWith('http')) {
          await _audioPlayer.play(UrlSource(exampleAudioPath));
        } else {
          await _audioPlayer.play(DeviceFileSource(exampleAudioPath));
        }
      }
    } catch (_) {}
  }

  void _submitAnswer(int selectedId, bool isCorrect) async {
    if (_currentDictWord == null || _selectedOptionId != null) return;
    
    setState(() {
      _selectedOptionId = selectedId;
      _wasCorrect = isCorrect;
    });

    final p = _progressService.getProgress(_currentDictWord!.id);
    final count = p?.rememberCount ?? 0;
    
    if (isCorrect && count >= 11) {
      _audioPlayer.play(AssetSource('sounds/finish.mp3'));
    } else if (isCorrect) {
      _audioPlayer.play(AssetSource('sounds/success.mp3'));
    } else {
      _audioPlayer.play(AssetSource('sounds/fail.mp3'));
    }

    await _progressService.recordReview(_currentDictWord!.id, isCorrect);
    
    // Fetch rich data in background for the overlay
    WordupApi.fetchWordData(_currentDictWord!.id.toString(), wordText: _currentDictWord!.text).then((json) {
      if (mounted) {
        setState(() {
          _currentWordData = WordData.fromJson(_currentDictWord!.id, json);
        });
      }
    }).catchError((_) {}); // Ignore fetch errors in review

    await Future.delayed(Duration(milliseconds: 1200));

    if (mounted) {
      setState(() {
        _showWordDetails = true;
      });
      _playReviewAutoSequence();
    }
  }

  void _proceedToNext() {
    _stopAllAudio();
    setState(() {
      _currentIndex++;
    });
    _loadNextWord();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Review Session', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              Color(0xFF1E1B4B), // Deep indigo
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading 
            ? Center(child: CircularProgressIndicator())
            : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_currentIndex >= _dueWords.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.celebration, size: 64, color: Colors.yellow),
            SizedBox(height: 16),
            Text('Review Complete!', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Return Home'),
            )
          ],
        )
      );
    }

    if (_currentDictWord == null) {
      return Center(child: Text('Error loading word'));
    }

    final currentProgress = _dueWords[_currentIndex];
    String stepText = 'Step ${currentProgress.rememberCount}';
    String nextStepText = '';
    
    bool isMastered = _progressService.knownWordIds.contains(_currentDictWord!.id);
    
    if (isMastered) {
      nextStepText = 'Mastered!';
    } else {
      final p = _progressService.getProgress(_currentDictWord!.id);
      final count = p?.rememberCount ?? currentProgress.rememberCount;
      
      // If count is 12, it is technically mastered (but handled by isMastered).
      // Here count is <= 11.
      final interval = _progressService.stepIntervals[count];
      final days = interval.inDays;
      
      if (days == 0) {
        nextStepText = 'Next: 1 day';
      } else if (days == 1) {
        nextStepText = 'Next: 1 day';
      } else if (days < 7) {
        nextStepText = 'Next: $days days';
      } else if (days == 7) {
        nextStepText = 'Next: 1 week';
      } else if (days == 14) {
        nextStepText = 'Next: 2 weeks';
      } else if (days == 30) {
        nextStepText = 'Next: 1 month';
      } else if (days == 60) {
        nextStepText = 'Next: 2 months';
      } else if (days == 90) {
        nextStepText = 'Next: 3 months';
      } else if (days == 180) {
        nextStepText = 'Next: 6 months';
      } else {
        nextStepText = 'Next: 12 months';
      }
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: _currentIndex / _dueWords.length,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
              SizedBox(height: 32),
              Expanded(
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: _showWordDetails 
                      ? _buildWordDetailsOverlay(nextStepText) 
                      : _buildQuestionArea(),
                ),
              ),
              // Footer with progress info
              if (!_showWordDetails) ...[
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      stepText,
                      style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      nextStepText,
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ],
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionArea() {
    switch (_currentQuestionType) {
      case 'meaning':
        return _buildMeaningQuestion();
      case 'quote':
        return _buildQuoteQuestion();
      case 'example':
        return _buildExampleQuestion();
      case 'misspelling':
        return _buildMisspellingQuestion();
      case 'synonym':
        return _buildSynonymQuestion();
      case 'listening':
        return _buildListeningQuestion();
      case 'compare':
        return _buildCompareQuestion();
      case 'antonym':
        return _buildAntonymQuestion();
      default:
        return Center(child: Text('Unknown question type', style: TextStyle(color: Colors.white)));
    }
  }

  Widget _buildWordWithAudioPrompt() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            _currentDictWord!.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: _currentDictWord!.text.length > 20 ? 32 : 48,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.volume_up_rounded, color: Colors.cyanAccent, size: 28),
          onPressed: () => _playAudio(_currentDictWord!.id.toString(), _currentDictWord!.text),
          tooltip: 'Listen to pronunciation',
        ),
      ],
    );
  }

  Widget _buildMeaningQuestion() {
    return _buildQuestionContainer(
      'What is the meaning of...',
      _currentDictWord!.text,
      false,
      customMainWidget: _buildWordWithAudioPrompt(),
    );
  }

  Widget _buildQuoteQuestion() {
    final quote = _questionData as WordQuote;
    final author = quote.authorName;
    
    final pattern = RegExp(RegExp.escape(_currentDictWord!.text), caseSensitive: false);
    final maskedQuote = quote.text.replaceAll(pattern, '_______');

    return _buildQuestionContainer(
      'Complete the quote by $author:',
      '\"$maskedQuote\"',
      true
    );
  }

  Widget _buildMisspellingQuestion() {
    return _buildQuestionContainer(
      'Listen and select the correct spelling',
      null,
      false,
      onTapPrompt: () => _playAudio(_currentDictWord!.id.toString(), _currentDictWord!.text),
      customMainWidget: Center(
        child: Container(
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.volume_up_rounded, size: 72, color: Colors.blueAccent),
        ),
      ),
    );
  }

  Widget _buildExampleQuestion() {
    final example = _questionData as String;
    
    final pattern = RegExp(RegExp.escape(_currentDictWord!.text), caseSensitive: false);
    final maskedExample = example.replaceAll(pattern, '_______');

    return _buildQuestionContainer(
      'Fill in the blank:',
      '\"$maskedExample\"',
      true
    );
  }

  Widget _buildSynonymQuestion() {
    return _buildQuestionContainer(
      'Which word is a synonym for...',
      _currentDictWord!.text,
      false,
      customMainWidget: _buildWordWithAudioPrompt(),
      customSubtitleWidget: Text.rich(
        TextSpan(
          text: 'Which word is a ',
          style: TextStyle(color: Colors.white70, fontSize: 18),
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'synonym',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            TextSpan(
              text: ' for...',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAntonymQuestion() {
    return _buildQuestionContainer(
      'Which word is an opposite (antonym) of...',
      _currentDictWord!.text,
      false,
      customMainWidget: _buildWordWithAudioPrompt(),
      customSubtitleWidget: Text.rich(
        TextSpan(
          text: 'Which word is an ',
          style: TextStyle(color: Colors.white70, fontSize: 18),
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'antonym (opposite)',
                  style: TextStyle(
                    color: Colors.redAccent.shade100,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            TextSpan(
              text: ' of...',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildListeningQuestion() {
    return _buildQuestionContainer(
      'Listen and select the meaning',
      null,
      false,
      onTapPrompt: () => _playAudio(_currentDictWord!.id.toString(), _currentDictWord!.text),
      customMainWidget: Center(
        child: Container(
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.volume_up_rounded, size: 72, color: Colors.blueAccent),
        ),
      ),
    );
  }

  Widget _buildCompareQuestion() {
    final comp = _questionData as WordComparison;
    
    final pattern = RegExp(RegExp.escape(_currentDictWord!.text), caseSensitive: false);
    final masked = comp.text.replaceAll(pattern, '_______');

    return _buildQuestionContainer(
      'Fill in the blank for this comparison:',
      masked,
      false
    );
  }

  Widget _buildQuestionContainer(String subtitle, String? mainText, bool isItalic, {VoidCallback? onTapPrompt, Widget? customMainWidget, Widget? customSubtitleWidget}) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 800), // Slightly wider for long quotes
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Spacer(),
                  Expanded(
                    flex: 8,
                    child: customSubtitleWidget ?? Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: IconButton(
                      icon: Icon(Icons.shuffle, color: Colors.white54, size: 20),
                      onPressed: () async {
                        setState(() => _isLoading = true);
                        await _generateQuestion(_currentDictWord!, _currentWordData);
                      },
                      tooltip: 'Change Question Type',
                    ),
                  ),
                ],
              ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: onTapPrompt,
              child: customMainWidget ?? Text(
                mainText ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onTapPrompt != null ? Colors.blueAccent : Colors.white, 
                  fontSize: (mainText?.length ?? 0) > 50 ? 20 : ((mainText?.length ?? 0) > 20 ? 32 : 48), 
                  fontWeight: FontWeight.bold,
                  fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
              SizedBox(height: 48),
              ..._buildOptionsList(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOptionsList() {
    return _currentOptions.map((option) {
      Color bgColor = Colors.white.withOpacity(0.1);
      if (_selectedOptionId != null) {
        if (option.isCorrect) {
          bgColor = Colors.green;
        } else if (option.id == _selectedOptionId) {
          bgColor = Colors.red;
        } else {
          bgColor = Colors.white.withOpacity(0.05);
        }
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
          ),
          onPressed: () {
            if (_selectedOptionId == null) {
              _submitAnswer(option.id, option.isCorrect);
            }
          },
          child: Text(option.text, textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
        ),
      );
    }).toList();
  }
  Widget _buildWordDetailsOverlay(String nextStepText) {
    String example = _getCurrentExample();
    String meaning = _currentDictWord!.meaning;
    
    if (_currentWordData != null) {
      if (_currentWordData!.senses.isNotEmpty) {
        meaning = _currentWordData!.senses.first.de;
      }
    }

    List<String> availableImages = [];
    if (_currentWordData != null) {
      if (_currentWordData!.imageUrl != null && _currentWordData!.imageUrl!.isNotEmpty) {
        availableImages.add(_currentWordData!.imageUrl!);
      }
      for (var sense in _currentWordData!.senses) {
        if (sense.imageUrl != null && sense.imageUrl!.isNotEmpty) availableImages.add(sense.imageUrl!);
        for (var tip in sense.tips) {
          if (tip.imageUrl != null && tip.imageUrl!.isNotEmpty) availableImages.add(tip.imageUrl!);
        }
      }
    }
    availableImages = availableImages.toSet().toList();

    String? preferredUrl = _progressService.getPreferredImage(_currentDictWord!.id);
    String? displayImageUrl;
    if (availableImages.isNotEmpty) {
      if (preferredUrl != null && availableImages.contains(preferredUrl)) {
        displayImageUrl = preferredUrl;
      } else {
        displayImageUrl = availableImages.first;
      }
    }

    bool isMastered = nextStepText == 'Mastered!';
    final rank = DatabaseService.getWordRank(_currentDictWord!.id);

    final wordText = _currentDictWord!.text;
    final pos = (_currentWordData != null && _currentWordData!.senses.isNotEmpty)
        ? _currentWordData!.senses.first.ty
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E), // Dark background for the card
        borderRadius: BorderRadius.circular(16),
        border: isMastered ? Border.all(color: Colors.amber, width: 2) : null,
        boxShadow: isMastered ? [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ] : null,
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Dedicated full-width Word / Idiom title row with adaptive sizing
          Text(
            wordText,
            style: TextStyle(
              fontSize: wordText.length > 20
                  ? 22
                  : (wordText.length > 13 ? 26 : 30),
              fontWeight: FontWeight.bold,
              color: isMastered ? Colors.amber : Colors.white,
              height: 1.2,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 10),
          // 2. Unified metadata and actions bar
          Row(
            children: [
              if (rank != null) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      color: Colors.purpleAccent.shade100,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(width: 8),
              ],
              if (pos != null && pos.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.tealAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    pos,
                    style: TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              Spacer(),
              IconButton(
                icon: Icon(Icons.volume_up_rounded, color: isMastered ? Colors.amber : Colors.cyanAccent),
                onPressed: () => _playAudio(_currentDictWord!.id.toString(), _currentDictWord!.text),
                tooltip: 'Listen to pronunciation',
              ),
              IconButton(
                icon: Icon(Icons.open_in_new, color: Colors.white70),
                onPressed: () {
                  _stopAllAudio();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WordViewScreen(
                        wordId: _currentDictWord!.id,
                        wordText: _currentDictWord!.text,
                      ),
                    ),
                  );
                },
                tooltip: 'View Full Word Details',
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            meaning,
            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
          ),
          if (example.isNotEmpty) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      example,
                      style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white70),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.volume_up_rounded, color: Colors.cyanAccent.shade100, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    onPressed: () => _playExampleAudio(example),
                    tooltip: 'Listen to example',
                  ),
                ],
              ),
            )
          ],
          if (displayImageUrl != null) ...[
            SizedBox(height: 16),
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      displayImageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                  if (availableImages.length > 1)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.refresh, color: Colors.white),
                          tooltip: 'Change Picture',
                          onPressed: () async {
                            int currentIdx = availableImages.indexOf(displayImageUrl!);
                            int nextIdx = (currentIdx + 1) % availableImages.length;
                            await _progressService.setPreferredImage(_currentDictWord!.id, availableImages[nextIdx]);
                            if (mounted) setState(() {});
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            Spacer(),
          ],
          SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: isMastered ? Colors.amber.shade600 : Color(0xFFC043FF), // Gold if mastered
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (isMastered) BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                else BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _proceedToNext,
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isMastered) ...[
                            Icon(Icons.emoji_events, color: Colors.black87),
                            SizedBox(width: 8),
                          ],
                          Text(
                            isMastered 
                                ? 'MASTERED!' 
                                : nextStepText == 'Next: Mastered!' 
                                    ? 'Move to Mastered!' 
                                    : 'Review in ${nextStepText.replaceAll('Next: ', '')}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isMastered ? Colors.black87 : Colors.white),
                          ),
                          if (isMastered) ...[
                            SizedBox(width: 8),
                            Icon(Icons.emoji_events, color: Colors.black87),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white24),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'known') {
                      await ProgressService().markAsKnown(_currentDictWord!.id);
                      _proceedToNext();
                    } else if (value == 'learn') {
                      await ProgressService().markAsToLearn(_currentDictWord!.id);
                      _proceedToNext();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'known', child: Text('Mark as Known')),
                    PopupMenuItem(value: 'learn', child: Text('Move to should learn')),
                  ],
                  icon: Icon(Icons.keyboard_arrow_down, color: isMastered ? Colors.black87 : Colors.white),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
