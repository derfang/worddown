import 'dart:async';
import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import '../services/database_service.dart';
import '../services/wordup_api.dart';
import '../services/review_question_service.dart';
import '../models/word.dart';
import 'package:audioplayers/audioplayers.dart';
import 'word_view_screen.dart';
import '../widgets/cached_media_image.dart';

class ReviewScreen extends StatefulWidget {
  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final ProgressService _progressService = ProgressService();
  final ReviewQuestionService _reviewService = ReviewQuestionService();
  
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

  PreparedReviewQuestion? _activePreparedQuestion;
  
  @override
  void initState() {
    super.initState();
    _initReviewSession();
  }

  @override
  void dispose() {
    _reviewService.deleteExampleAudio(_currentIndex);
    _stopAllAudio();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initReviewSession() {
    _reviewService.prepareReviewSession(context: context);
    _dueWords = _reviewService.currentSessionQueue;
    _currentIndex = 0;

    final cachedFirst = _reviewService.getCachedQuestion(0);
    if (cachedFirst != null) {
      _applyQuestion(cachedFirst);
      _isLoading = false;
      // Proactively pre-make remaining upcoming questions
      for (int i = 1; i <= 4 && i < _dueWords.length; i++) {
        _reviewService.getOrPrepareQuestion(i, context: context);
      }
    } else {
      _isLoading = true;
      _loadNextWord();
    }
  }

  void _applyQuestion(PreparedReviewQuestion question) {
    _activePreparedQuestion = question;
    final variant = question.currentVariant;

    _currentDictWord = question.word;
    _currentWordData = question.wordData;
    _currentQuestionType = variant.type;
    _currentOptions = variant.options;
    _questionData = variant.questionData;
    _selectedOptionId = null;
    _wasCorrect = null;
    _showWordDetails = false;

    if (variant.type == 'meaning' || variant.type == 'listening' || variant.type == 'synonym' || variant.type == 'antonym' || variant.type == 'misspelling') {
      if (question.wordAudioPath != null && question.wordAudioPath!.isNotEmpty) {
        _playAudioPathDirectly(question.wordAudioPath!);
      } else {
        _playAudio(question.word.id.toString(), question.word.text);
      }
    }
  }

  Future<void> _loadNextWord() async {
    if (_currentIndex >= _dueWords.length) {
      setState(() {
        _isLoading = false;
        _currentDictWord = null;
      });
      return;
    }

    // Keep the next 4 questions constantly pre-made
    for (int offset = 1; offset <= 4; offset++) {
      _reviewService.getOrPrepareQuestion(_currentIndex + offset, context: context);
    }

    final prepared = await _reviewService.getOrPrepareQuestion(_currentIndex, context: context);

    if (!mounted || prepared == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _applyQuestion(prepared);
      _isLoading = false;
    });
  }

  void _shuffleQuestionType() {
    if (_activePreparedQuestion == null || _activePreparedQuestion!.variants.length <= 1) return;

    final nextIndex = (_activePreparedQuestion!.currentVariantIndex + 1) % _activePreparedQuestion!.variants.length;
    _activePreparedQuestion!.currentVariantIndex = nextIndex;
    final variant = _activePreparedQuestion!.currentVariant;

    setState(() {
      _currentQuestionType = variant.type;
      _currentOptions = variant.options;
      _questionData = variant.questionData;
      _selectedOptionId = null;
      _wasCorrect = null;
    });

    if (variant.type == 'meaning' || variant.type == 'listening' || variant.type == 'synonym' || variant.type == 'antonym' || variant.type == 'misspelling') {
      if (_activePreparedQuestion?.wordAudioPath != null && _activePreparedQuestion!.wordAudioPath!.isNotEmpty) {
        _playAudioPathDirectly(_activePreparedQuestion!.wordAudioPath!);
      } else {
        _playAudio(_activePreparedQuestion!.word.id.toString(), _activePreparedQuestion!.word.text);
      }
    }
  }

  int _audioSequenceId = 0;

  void _stopAllAudio() {
    _audioSequenceId++;
    _audioPlayer.stop();
  }

  void _playAudioPathDirectly(String path) {
    _stopAllAudio();
    try {
      if (path.startsWith('http') || path.startsWith('data:')) {
        _audioPlayer.play(UrlSource(path));
      } else {
        _audioPlayer.play(DeviceFileSource(path));
      }
    } catch (_) {}
  }

  String _getCurrentExample() {
    if (_activePreparedQuestion?.exampleText != null && _activePreparedQuestion!.exampleText!.isNotEmpty) {
      return _activePreparedQuestion!.exampleText!;
    }
    if (_currentWordData != null) {
      for (final s in _currentWordData!.senses) {
        if (s.ex.trim().isNotEmpty) {
          return s.ex.trim();
        }
      }
    }
    return '';
  }

  Future<void> _playAudio(String wordId, String text) async {
    _stopAllAudio();
    try {
      final path = await WordupApi.getAudioPath(wordId, wordText: text, isUk: false, useGoogleTts: false);
      if (path.isNotEmpty) {
        if (path.startsWith('http') || path.startsWith('data:')) {
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
        if (path.startsWith('http') || path.startsWith('data:')) {
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

    final activeQuestion = _activePreparedQuestion;

    // Use pre-fetched sentence audio if available, or fetch in parallel
    final Future<String?> sentenceAudioFuture = () async {
      if (activeQuestion?.exampleAudioPath != null && activeQuestion!.exampleAudioPath!.isNotEmpty) {
        return activeQuestion.exampleAudioPath;
      }
      try {
        String example = _getCurrentExample();
        if (example.isEmpty && _currentWordData == null) {
          final json = await WordupApi.fetchWordData(word.id.toString(), wordText: word.text);
          if (currentSeq != _audioSequenceId || !mounted) return null;
          final data = WordData.fromJson(word.id, json);
          for (final s in data.senses) {
            if (s.ex.trim().isNotEmpty) {
              example = s.ex.trim();
              break;
            }
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
      String wordAudioPath = activeQuestion?.wordAudioPath ?? '';
      if (wordAudioPath.isEmpty) {
        wordAudioPath = await WordupApi.getAudioPath(
          word.id.toString(),
          wordText: word.text,
          isUk: false,
          useGoogleTts: false,
        );
      }
      if (currentSeq != _audioSequenceId || !mounted) return;

      if (wordAudioPath.isNotEmpty) {
        if (wordAudioPath.startsWith('http') || wordAudioPath.startsWith('data:')) {
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
        if (exampleAudioPath.startsWith('http') || exampleAudioPath.startsWith('data:')) {
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
    
    // Ensure rich data with illustrations is available for the overlay
    if (_currentWordData == null || !_currentWordData!.senses.any((s) => s.imageUrl != null && s.imageUrl!.isNotEmpty)) {
      WordupApi.fetchWordData(
        _currentDictWord!.id.toString(),
        wordText: _currentDictWord!.text,
        isPrefetch: true,
      ).then((json) {
        if (mounted && json.isNotEmpty) {
          setState(() {
            _currentWordData = WordData.fromJson(_currentDictWord!.id, json);
          });
        }
      }).catchError((_) {});
    }

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
    _reviewService.deleteExampleAudio(_currentIndex);
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
    
    final pattern = RegExp(r'\b' + RegExp.escape(_currentDictWord!.text) + r'(s|es|ed|ing|d)?\b', caseSensitive: false);
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
                      onPressed: _shuffleQuestionType,
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
                    child: CachedMediaImage(
                      key: ValueKey('${_currentDictWord!.id}_$displayImageUrl'),
                      wordId: _currentDictWord!.id,
                      imageUrl: displayImageUrl,
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
                          color: Colors.black.withValues(alpha: 0.6),
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
            SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: _currentWordData != null && _currentWordData!.senses.length > 1
                    ? ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          Text('OTHER DEFINITIONS', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          SizedBox(height: 8),
                          for (int sIdx = 1; sIdx < _currentWordData!.senses.length; sIdx++) ...[
                            Container(
                              margin: EdgeInsets.only(bottom: 8),
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${sIdx + 1}. ${_currentWordData!.senses[sIdx].de}',
                                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                  if (_currentWordData!.senses[sIdx].ex.isNotEmpty) ...[
                                    SizedBox(height: 4),
                                    Text(
                                      '“${_currentWordData!.senses[sIdx].ex}”',
                                      style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_stories_rounded, size: 40, color: Colors.white24),
                            SizedBox(height: 8),
                            Text('No illustration in dictionary', style: TextStyle(color: Colors.white38, fontSize: 13)),
                          ],
                        ),
                      ),
              ),
            ),
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
}
