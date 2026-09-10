import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/wordup_api.dart';
import '../services/progress_service.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';
import '../services/media_cache_service.dart';
import '../services/translation_service.dart';
import '../models/word.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/highlight_text.dart';
import '../widgets/cached_media_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
// Use real webview_windows on Windows; fall back to a no-op stub on all other platforms
import 'package:webview_windows/webview_windows.dart'
    if (dart.library.js_interop) '../stubs/webview_windows_stub.dart'
    if (dart.library.js) '../stubs/webview_windows_stub.dart';

enum WordCardLayout { list, grid, slide }

class WordViewScreen extends StatefulWidget {
  final int wordId;
  final String? wordText;
  final Widget? bottomNavigationBarOverride;
  const WordViewScreen({Key? key, required this.wordId, this.wordText, this.bottomNavigationBarOverride}) : super(key: key);

  @override
  _WordViewScreenState createState() => _WordViewScreenState();
}

class _WordViewScreenState extends State<WordViewScreen> with SingleTickerProviderStateMixin {
  WordData? _wordData;
  WordProgress? _progress;
  bool _isKnown = false;
  bool _isQueued = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _shimmerController;
  
  WordVideo? _playingVideo;
  // Windows video controller
  WebviewController? _webviewController;
  // Android / non-Windows video controllers
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  String? _videoError;
  int _currentVideoPositionMs = 0;

  bool _isLoading = true;
  String _error = '';
  static WordCardLayout get _defaultCardLayout {
    final saved = SettingsService().wordCardLayout;
    if (saved != null) {
      for (final val in WordCardLayout.values) {
        if (val.name == saved) return val;
      }
    }
    return defaultTargetPlatform == TargetPlatform.android
        ? WordCardLayout.slide
        : WordCardLayout.grid;
  }

  static WordCardLayout _cardLayout = _defaultCardLayout;
  static bool _isShuffledContent = true;
  int _shuffleSeedOffset = 0;
  bool _lastIsUk = false;
  String? _currentlyPlayingTextId;
  bool _isSentenceLoading = false;
  Map<String, int> _learningWords = {};
  String? _translatedWord;

  void _setCardLayout(WordCardLayout layout) {
    setState(() => _cardLayout = layout);
    SettingsService().setWordCardLayout(layout.name);
  }

  @override
  void initState() {
    super.initState();
    final savedLayout = SettingsService().wordCardLayout;
    if (savedLayout != null) {
      for (final val in WordCardLayout.values) {
        if (val.name == savedLayout) {
          _cardLayout = val;
          break;
        }
      }
    }

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Initialize progress and status immediately from local state
    _progress = ProgressService().getProgress(widget.wordId);
    _isKnown = ProgressService().knownWordIds.contains(widget.wordId);
    _isQueued = ProgressService().isInLearningQueue(widget.wordId);

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        if (mounted) {
          setState(() {
            _currentlyPlayingTextId = null;
            _isSentenceLoading = false;
          });
        }
      }
    });
    _loadData();
    _fetchTranslation();
    _learningWords = _getLearningWords();
  }

  void _fetchTranslation() {
    final wordText = widget.wordText ?? DatabaseService.getWordById(widget.wordId)?.text;
    if (wordText == null || wordText.trim().isEmpty) return;
    TranslationService().translate(wordText).then((trans) {
      if (mounted && trans != null && trans.isNotEmpty) {
        setState(() {
          _translatedWord = trans;
        });
      }
    });
  }
  
  Map<String, int> _getLearningWords() {
    final progress = ProgressService();
    Map<String, int> words = {};
    for (var wp in progress.learningWords) {
      final w = DatabaseService.getWordById(wp.wordId);
      if (w != null) words[w.text.toLowerCase()] = w.id;
    }
    for (var id in progress.queuedWordsToLearn) {
      final w = DatabaseService.getWordById(id);
      if (w != null) words[w.text.toLowerCase()] = w.id;
    }
    return words;
  }

  void _onWordTap(int id, String text) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordViewScreen(wordId: id, wordText: text),
      ),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _webviewController?.dispose();
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _pendingZannData;

  Future<void> _loadData() async {
    try {
      final json = await WordupApi.fetchWordData(
        widget.wordId.toString(),
        wordText: widget.wordText,
        onExtraDataLoaded: (extraData) {
          if (mounted) {
            if (_wordData != null) {
              setState(() {
                _mergeZannData(extraData);
              });
            } else {
              _pendingZannData = extraData;
            }
          }
        },
      );
      
      final data = WordData.fromJson(widget.wordId, json);
      if (_pendingZannData != null) {
        _wordData = data;
        _mergeZannData(_pendingZannData!);
        _pendingZannData = null;
      }
      MediaCacheService.cacheWordMedia(widget.wordId, data);
      
      if (mounted) {
        setState(() {
          _wordData = data;
          _progress = ProgressService().getProgress(widget.wordId);
          _isKnown = ProgressService().knownWordIds.contains(widget.wordId);
          _isQueued = ProgressService().isInLearningQueue(widget.wordId);
          _isLoading = false;
        });
        
        // Autoplay the audio when the word loads
        _playAudio(isUk: false, useGoogleTts: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _mergeZannData(Map<String, dynamic> extraData) {
    if (_wordData == null) return;

    // 1. Merge Quotes
    if (extraData['ZannQuotes'] != null) {
      final List zannQuotes = extraData['ZannQuotes'] as List;
      for (var zq in zannQuotes) {
        final text = zq['Text']?.toString() ?? '';
        final imageSrc = zq['ImageSrc']?.toString() ?? '';
        if (imageSrc.isNotEmpty) {
          for (var q in _wordData!.quotes) {
            if (text.contains(q.text) || q.text.contains(text) || q.authorName == zq['Name']) {
              q.imageUrl = imageSrc;
              break;
            }
          }
        }
      }
    }

    // 2. Merge Senses & Tips Images
    final zannSenses = extraData['ZannSenses'] as List?;
    String? mainImageUrl = extraData['ZannWordImage']?.toString();
    
    if (zannSenses != null && zannSenses.isNotEmpty) {
      if (mainImageUrl == null || mainImageUrl.isEmpty) {
        mainImageUrl = zannSenses.first['ImageSrc']?.toString();
      }
      if (_wordData!.imageUrl == null || _wordData!.imageUrl!.isEmpty) {
        _wordData!.imageUrl = mainImageUrl;
      }

      for (var sense in _wordData!.senses) {
        final zSenseList = zannSenses.cast<Map<String, dynamic>>().where((s) => s['id'] == sense.id).toList();
        if (zSenseList.isNotEmpty) {
          final zSense = zSenseList.first;
          final img = zSense['ImageSrc']?.toString();
          if (img != null && img.isNotEmpty) {
            sense.imageUrl = img;
          }

          final zTips = zSense['Tips'] as List?;
          if (zTips != null) {
            for (int i = 0; i < sense.tips.length; i++) {
              if (i < zTips.length) {
                final tipImg = zTips[i]['imageUrl']?.toString();
                if (tipImg != null && tipImg.isNotEmpty) {
                  sense.tips[i].imageUrl = tipImg;
                }
              }
            }
          }
        }
      }

      // Cache newly retrieved images to disk in background
      MediaCacheService.cacheWordMedia(widget.wordId, _wordData!);
    }
  }


  Future<void> _playSentence(String text, String id) async {
    if (_currentlyPlayingTextId == id && !_isSentenceLoading) {
      await _audioPlayer.stop();
      setState(() {
        _currentlyPlayingTextId = null;
      });
      return;
    }
    await _audioPlayer.stop();
    setState(() {
      _currentlyPlayingTextId = id;
      _isSentenceLoading = true;
    });
    try {
      final path = await WordupApi.getSentenceAudioPath(text, isUk: _lastIsUk);
      if (path.startsWith('http')) {
        await _audioPlayer.play(UrlSource(path));
      } else {
        await _audioPlayer.play(DeviceFileSource(path));
      }
      if (mounted) {
        setState(() {
          _isSentenceLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentlyPlayingTextId = null;
          _isSentenceLoading = false;
        });
      }
    }
  }

  Widget _buildInlineAudioButton(String text, String id) {
    if (_currentlyPlayingTextId == id) {
      if (_isSentenceLoading) {
        return const Padding(
          padding: EdgeInsets.all(12.0),
          child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
        );
      } else {
        return IconButton(
          icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent),
          onPressed: () => _playSentence(text, id),
        );
      }
    }
    return IconButton(
      icon: Icon(Icons.volume_up_outlined, color: Theme.of(context).colorScheme.primary),
      onPressed: () => _playSentence(text, id),
    );
  }
  Future<void> _playVideo(WordVideo video) async {
    // Dispose existing controllers
    _webviewController?.dispose();
    _chewieController?.dispose();
    _videoPlayerController?.dispose();

    setState(() {
      _playingVideo = video;
      _currentVideoPositionMs = video.startTimeMs;
      _webviewController = null;
      _videoPlayerController = null;
      _chewieController = null;
      _videoError = null;
    });

    if (Theme.of(context).platform == TargetPlatform.windows) {
      // ── Windows path: use webview_windows ──────────────────────────────
      final controller = WebviewController();
      await controller.initialize();

      try {
        final yt = YoutubeExplode();
        final manifest = await yt.videos.streamsClient.getManifest(video.youtubeId);
        final streamInfo = manifest.muxed.withHighestBitrate();
        final rawUrl = streamInfo.url.toString();
        yt.close();

        final html = '''
          <!DOCTYPE html>
          <html>
            <body style="margin:0;padding:0;background-color:black;display:flex;justify-content:center;align-items:center;height:100vh;overflow:hidden;">
              <video width="100%" height="100%" controls autoplay style="outline:none;">
                <source src="$rawUrl" type="video/mp4">
              </video>
              <script>
                var video = document.querySelector('video');
                video.currentTime = ${video.startTimeMs / 1000};
                video.play();
                video.addEventListener('timeupdate', function() {
                  window.chrome.webview.postMessage(JSON.stringify({type: 'timeupdate', currentTime: video.currentTime * 1000}));
                });
              </script>
            </body>
          </html>
        ''';
        await controller.loadStringContent(html);
        controller.webMessage.listen((msg) {
          try {
            final data = jsonDecode(msg);
            if (data['type'] == 'timeupdate' && mounted && _playingVideo == video) {
              final pos = (data['currentTime'] as num).toInt();
              if ((pos - _currentVideoPositionMs).abs() > 200) {
                setState(() {
                  _currentVideoPositionMs = pos;
                });
              }
            }
          } catch (_) {}
        });
      } catch (e) {
        print('YoutubeExplode Error (Windows): $e');
        controller.loadingState.listen((state) async {
          if (state == LoadingState.navigationCompleted) {
            await controller.executeScript('''
              try {
                document.cookie = "CONSENT=YES+cb.20230101-08-p0.en+FX+0; path=/; domain=.youtube.com";
                setInterval(function() {
                  document.body.style.setProperty('overflow', 'hidden', 'important');
                  document.body.style.setProperty('background-color', 'black', 'important');
                  var player = document.querySelector('#ytd-player') || document.querySelector('#player-container') || document.querySelector('#player');
                  if (player) {
                    player.style.setProperty('position', 'fixed', 'important');
                    player.style.setProperty('top', '0', 'important');
                    player.style.setProperty('left', '0', 'important');
                    player.style.setProperty('width', '100vw', 'important');
                    player.style.setProperty('height', '100vh', 'important');
                    player.style.setProperty('z-index', '999999', 'important');
                    player.style.setProperty('background-color', 'black', 'important');
                  }
                  var video = document.querySelector('video');
                  if (video) { video.style.setProperty('object-fit', 'contain', 'important'); }
                }, 100);
              } catch(err) {}
            ''');
          }
        });
        await controller.loadUrl('https://www.youtube.com/watch?v=${video.youtubeId}&t=${video.startTimeMs ~/ 1000}s');
      }

      if (mounted) setState(() => _webviewController = controller);
    } else {
      // ── Android / other platforms: use video_player + chewie ───────────
      try {
        final yt = YoutubeExplode();
        final manifest = await yt.videos.streamsClient.getManifest(video.youtubeId);
        final streamInfo = manifest.muxed.withHighestBitrate();
        final rawUrl = streamInfo.url.toString();
        yt.close();

        final vpController = VideoPlayerController.networkUrl(
          Uri.parse(rawUrl),
          httpHeaders: {'User-Agent': 'Mozilla/5.0'},
        );
        await vpController.initialize();
        await vpController.seekTo(Duration(milliseconds: video.startTimeMs));

        vpController.addListener(() {
          if (mounted && _playingVideo == video) {
            final pos = vpController.value.position.inMilliseconds;
            if ((pos - _currentVideoPositionMs).abs() > 200) {
              setState(() {
                _currentVideoPositionMs = pos;
              });
            }
          }
        });

        final chewieController = ChewieController(
          videoPlayerController: vpController,
          autoPlay: true,
          looping: false,
          aspectRatio: 16 / 9,
          allowFullScreen: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: const Color(0xFF6366F1),
            handleColor: const Color(0xFF6366F1),
            backgroundColor: Colors.grey,
            bufferedColor: Colors.grey.shade400,
          ),
        );

        if (mounted) {
          setState(() {
            _videoPlayerController = vpController;
            _chewieController = chewieController;
          });
        }
      } catch (e) {
        print('Error loading video on Android: $e');
        if (mounted) {
          setState(() {
            _playingVideo = null;
            _videoError = 'Could not load video. Please try again.';
          });
        }
      }
    }
  }

  void _closeVideo() {
    _webviewController?.dispose();
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    setState(() {
      _playingVideo = null;
      _currentVideoPositionMs = 0;
      _webviewController = null;
      _videoPlayerController = null;
      _chewieController = null;
      _videoError = null;
    });
  }

  Widget _buildVideoSubtitles(WordVideo video, ThemeData theme) {
    final bool isPlaying = _playingVideo == video;
    final int relativeMs = isPlaying ? (_currentVideoPositionMs - video.startTimeMs) : -1;

    // If segments exist, build paragraph with active sentence pill and vocabulary highlights
    if (video.segments.isNotEmpty) {
      int activeIndex = -1;
      if (isPlaying && relativeMs >= 0) {
        for (int i = 0; i < video.segments.length; i++) {
          final seg = video.segments[i];
          if (relativeMs >= seg.startMs && relativeMs <= seg.endMs) {
            activeIndex = i;
            break;
          }
        }
      }

      final List<InlineSpan> paragraphSpans = [];

      for (int i = 0; i < video.segments.length; i++) {
        final seg = video.segments[i];
        final bool isActive = (i == activeIndex);

        final baseStyle = TextStyle(
          color: isActive ? Colors.white : Colors.white.withOpacity(0.85),
          fontSize: 16,
          height: 1.6,
          letterSpacing: 0.2,
          backgroundColor: isActive ? const Color(0x406366F1) : Colors.transparent,
        );

        final segSpans = HighlightText.buildSpans(
          text: seg.text,
          selfWord: widget.wordText?.toLowerCase() ?? '',
          learningWords: _learningWords,
          normalStyle: baseStyle,
          onWordTap: _onWordTap,
        );

        if (i > 0) {
          paragraphSpans.add(const TextSpan(text: ' '));
        }

        paragraphSpans.addAll(segSpans);
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(children: paragraphSpans),
        ),
      );
    }

    // Fallback if no timing segments were parsed: highlight vocabulary on full subtitle string
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: HighlightText(
        text: video.subtitles,
        selfWord: widget.wordText?.toLowerCase() ?? '',
        learningWords: _learningWords,
        onWordTap: _onWordTap,
        textAlign: TextAlign.center,
        normalStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          height: 1.5,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildAudioBtn(String flag, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Icon(icon, size: 18, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Future<void> _playAudio({required bool isUk, required bool useGoogleTts}) async {
    setState(() { _lastIsUk = isUk; if (_currentlyPlayingTextId != null) { _audioPlayer.stop(); _currentlyPlayingTextId = null; } });
    try {
      final path = await WordupApi.getAudioPath(
        widget.wordId.toString(), 
        wordText: widget.wordText, 
        isUk: isUk, 
        useGoogleTts: useGoogleTts,
      );
      if (path.startsWith('http')) {
        await _audioPlayer.play(UrlSource(path));
      } else {
        await _audioPlayer.play(DeviceFileSource(path));
      }
    } catch (e) {
      if (!useGoogleTts) {
        print('Dictionary API failed, falling back to Google TTS...');
        await _playAudio(isUk: isUk, useGoogleTts: true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to play audio: ${e.toString()}')));
      }
    }
  }

  Widget _buildAppBarTitle() {
    final wordText = (widget.wordText ?? DatabaseService.getWordById(widget.wordId)?.text ?? 'WORD').toUpperCase();
    final rank = DatabaseService.getWordRank(widget.wordId);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            wordText,
            style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 20, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (rank != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.purpleAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purpleAccent.withOpacity(0.5)),
            ),
            child: Text(
              '#$rank',
              style: TextStyle(
                color: Colors.purpleAccent.shade100,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorScaffold(ThemeData theme) {
    final wordName = (widget.wordText ?? DatabaseService.getWordById(widget.wordId)?.text ?? 'Word').toUpperCase();
    final isNetworkError = _error.toLowerCase().contains('socket') ||
        _error.toLowerCase().contains('timeout') ||
        _error.toLowerCase().contains('handshake') ||
        _error.toLowerCase().contains('clientexception') ||
        _error.toLowerCase().contains('failed host lookup') ||
        _error.toLowerCase().contains('connection');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
        ),
        title: _buildAppBarTitle(),
      ),
      bottomNavigationBar: widget.bottomNavigationBarOverride ?? _buildBottomActions(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              const Color(0xFF1E1B4B),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: const Icon(
                        Icons.cloud_off_rounded,
                        size: 54,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isNetworkError ? 'Connection Issue' : 'Failed to Load Word',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isNetworkError
                          ? 'Unable to connect to the word CDN server. Please check your internet connection or VPN and tap retry.'
                          : 'An unexpected issue occurred while fetching content for "$wordName".',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        _error,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Colors.white38,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text('Go Back'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _error = '';
                            });
                            _loadData();
                            _fetchTranslation();
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_error.isNotEmpty && _wordData == null) {
      return _buildErrorScaffold(theme);
    }
    
    final data = _wordData;

    List<String> availableImages = [];
    String? displayImageUrl;
    if (data != null) {
      if (data.imageUrl != null && data.imageUrl!.isNotEmpty) {
        availableImages.add(data.imageUrl!);
      }
      for (var sense in data.senses) {
        if (sense.imageUrl != null && sense.imageUrl!.isNotEmpty) availableImages.add(sense.imageUrl!);
        for (var tip in sense.tips) {
          if (tip.imageUrl != null && tip.imageUrl!.isNotEmpty) availableImages.add(tip.imageUrl!);
        }
      }
      availableImages = availableImages.toSet().toList();

      String? preferredUrl = ProgressService().getPreferredImage(widget.wordId);
      if (availableImages.isNotEmpty) {
        if (preferredUrl != null && availableImages.contains(preferredUrl)) {
          displayImageUrl = preferredUrl;
        } else {
          displayImageUrl = availableImages.first;
        }
      }
    }
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      bottomNavigationBar: widget.bottomNavigationBarOverride ?? _buildBottomActions(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              Color(0xFF1E1B4B),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 800),
              child: CustomScrollView(
                physics: BouncingScrollPhysics(),
                slivers: [
                  if (theme.platform == TargetPlatform.android || theme.platform == TargetPlatform.iOS) ...[
                    SliverAppBar(
                      pinned: false,
                      floating: true,
                      backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.95),
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      title: _buildAppBarTitle(),
                    ),
                    SliverAppBar(
                      pinned: true,
                      floating: false,
                      primary: false,
                      automaticallyImplyLeading: false,
                      backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.95),
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      toolbarHeight: 60,
                      titleSpacing: 0,
                      title: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildAudioBtn('🇬🇧', Icons.volume_up, () => _playAudio(isUk: true, useGoogleTts: false)),
                            _buildAudioBtn('🇺🇸', Icons.volume_up, () => _playAudio(isUk: false, useGoogleTts: false)),
                            _buildAudioBtn('🇬🇧', Icons.record_voice_over, () => _playAudio(isUk: true, useGoogleTts: true)),
                            _buildAudioBtn('🇺🇸', Icons.record_voice_over, () => _playAudio(isUk: false, useGoogleTts: true)),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    SliverAppBar(
                      pinned: false,
                      floating: true,
                      backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.95),
                      elevation: 0,
                      title: _buildAppBarTitle(),
                      actions: [
                        TextButton(onPressed: () => _playAudio(isUk: true, useGoogleTts: false), child: const Text('UK Dict')),
                        TextButton(onPressed: () => _playAudio(isUk: false, useGoogleTts: false), child: const Text('US Dict')),
                        TextButton(onPressed: () => _playAudio(isUk: true, useGoogleTts: true), child: const Text('UK TTS')),
                        TextButton(onPressed: () => _playAudio(isUk: false, useGoogleTts: true), child: const Text('US TTS')),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ],
                  if (_isLoading || data == null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                      sliver: SliverToBoxAdapter(
                        child: _buildSkeletonBody(theme),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                if (displayImageUrl != null) ...[
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 400),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedMediaImage(
                        wordId: widget.wordId,
                        imageUrl: displayImageUrl,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: double.infinity,
                          color: Colors.grey.withOpacity(0.1),
                          child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                ],
                if (_translatedWord != null && _translatedWord!.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.translate, color: Colors.tealAccent, size: 16),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _translatedWord!,
                              style: const TextStyle(
                                color: Colors.tealAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (data.usage.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber, size: 20),
                            SizedBox(width: 8),
                            Text('Usage Note', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 8),
                        HighlightText(
                          text: data.usage,
                          selfWord: widget.wordText?.toLowerCase() ?? '',
                          learningWords: _learningWords,
                          onWordTap: _onWordTap,
                          normalStyle: TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Definitions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.view_list),
                          tooltip: 'List view',
                          visualDensity: VisualDensity.compact,
                          color: _cardLayout == WordCardLayout.list ? theme.colorScheme.primary : Colors.white54,
                          onPressed: () => _setCardLayout(WordCardLayout.list),
                        ),
                        IconButton(
                          icon: Icon(Icons.grid_view),
                          tooltip: 'Grid view',
                          visualDensity: VisualDensity.compact,
                          color: _cardLayout == WordCardLayout.grid ? theme.colorScheme.primary : Colors.white54,
                          onPressed: () => _setCardLayout(WordCardLayout.grid),
                        ),
                        IconButton(
                          icon: Icon(Icons.view_carousel),
                          tooltip: 'Slide view',
                          visualDensity: VisualDensity.compact,
                          color: _cardLayout == WordCardLayout.slide ? theme.colorScheme.primary : Colors.white54,
                          onPressed: () => _setCardLayout(WordCardLayout.slide),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (_cardLayout == WordCardLayout.grid)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (int i = 0; i < data.senses.length; i += 2)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildSenseCard(data.senses[i], theme),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (int i = 1; i < data.senses.length; i += 2)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildSenseCard(data.senses[i], theme),
                              ),
                          ],
                        ),
                      ),
                    ],
                  )
                else if (_cardLayout == WordCardLayout.slide)
                  SlidingCardsView(
                    itemCount: data.senses.length,
                    itemBuilder: (context, index) => _buildSenseCard(data.senses[index], theme),
                  )
                else
                  ...data.senses.map((sense) => Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                    child: _buildSenseCard(sense, theme),
                  )),
                
                if (data.senses.any((s) => s.tips.isNotEmpty)) ...[
                  SizedBox(height: 32),
                  Text('Pro Tips', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 16),
                  if (_cardLayout == WordCardLayout.grid)
                    ...() {
                      final tips = data.senses.expand((sense) => sense.tips).toList();
                      return [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (int i = 0; i < tips.length; i += 2)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: _buildTipCard(tips[i]),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (int i = 1; i < tips.length; i += 2)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: _buildTipCard(tips[i]),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ];
                    }()
                  else if (_cardLayout == WordCardLayout.slide)
                    ...() {
                      final tips = data.senses.expand((sense) => sense.tips).toList();
                      return [
                        SlidingCardsView(
                          itemCount: tips.length,
                          itemBuilder: (context, index) => _buildTipCard(tips[index]),
                        ),
                      ];
                    }()
                  else
                    ...data.senses.expand((sense) => sense.tips).map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildTipCard(tip),
                    )),
                ],

                if (data.collocations.isNotEmpty) ...[
                  SizedBox(height: 32),
                  Text('Often used with', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: data.collocations.map((c) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(c, style: TextStyle(color: Colors.white70)),
                    )).toList(),
                  ),
                ],

                if (data.phrases.isNotEmpty) ...[
                  SizedBox(height: 32),
                  Text('Phrases & Idioms', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 16),
                  ...data.phrases.map((phrase) => Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HighlightText(
                          text: phrase.doText,
                          selfWord: widget.wordText?.toLowerCase() ?? '',
                          learningWords: _learningWords,
                          onWordTap: _onWordTap,
                          normalStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                        if (phrase.de.isNotEmpty) ...[
                          SizedBox(height: 6),
                          HighlightText(
                            text: phrase.de,
                            selfWord: widget.wordText?.toLowerCase() ?? '',
                            learningWords: _learningWords,
                          onWordTap: _onWordTap,
                            normalStyle: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                        if (phrase.ex.isNotEmpty) ...[
                          SizedBox(height: 8),
                          HighlightText(
                            text: '"${phrase.ex}"',
                            selfWord: widget.wordText?.toLowerCase() ?? '',
                            learningWords: _learningWords,
                          onWordTap: _onWordTap,
                            normalStyle: TextStyle(fontStyle: FontStyle.italic, color: Colors.white54, fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                  )).toList(),
                ],

                if (data.compounds.isNotEmpty) ...[
                  SizedBox(height: 32),
                  Text('Compound Words', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 16),
                  ...data.compounds.map((comp) => Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HighlightText(
                          text: comp.doText,
                          selfWord: widget.wordText?.toLowerCase() ?? '',
                          learningWords: _learningWords,
                          onWordTap: _onWordTap,
                          normalStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                        if (comp.de.isNotEmpty) ...[
                          SizedBox(height: 6),
                          HighlightText(
                            text: comp.de,
                            selfWord: widget.wordText?.toLowerCase() ?? '',
                            learningWords: _learningWords,
                          onWordTap: _onWordTap,
                            normalStyle: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                        if (comp.ex.isNotEmpty) ...[
                          SizedBox(height: 8),
                          HighlightText(
                            text: '"${comp.ex}"',
                            selfWord: widget.wordText?.toLowerCase() ?? '',
                            learningWords: _learningWords,
                          onWordTap: _onWordTap,
                            normalStyle: TextStyle(fontStyle: FontStyle.italic, color: Colors.white54, fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                  )).toList(),
                ],

                if (data.comparisons.isNotEmpty)
                  CompareWithSection(
                    comparisons: data.comparisons,
                    selfWord: widget.wordText?.toLowerCase() ?? '',
                    learningWords: _learningWords,
                    onWordTap: _onWordTap,
                  ),

                // Extended Content (Wisdom, Facts, Quotes, Videos)
                ...() {
                  final bool hasExtendedContent = data.wisdom.isNotEmpty ||
                      data.facts.isNotEmpty ||
                      data.quotes.isNotEmpty ||
                      data.videos.isNotEmpty;
                  if (!hasExtendedContent) return <Widget>[];

                  if (_isShuffledContent) {
                    final quotes = List.from(data.quotes)..shuffle(math.Random(widget.wordId + _shuffleSeedOffset));
                    final wisdoms = List.from(data.wisdom)..shuffle(math.Random(widget.wordId + 1 + _shuffleSeedOffset));
                    final videos = List.from(data.videos)..shuffle(math.Random(widget.wordId + 2 + _shuffleSeedOffset));
                    final facts = List.from(data.facts)..shuffle(math.Random(widget.wordId + 3 + _shuffleSeedOffset));

                    final List<Widget> items = [];
                    int qIdx = 0, wIdx = 0, vIdx = 0, fIdx = 0;
                    while (qIdx < quotes.length ||
                        wIdx < wisdoms.length ||
                        vIdx < videos.length ||
                        fIdx < facts.length) {
                      if (qIdx < quotes.length) {
                        items.add(_buildQuoteCard(quotes[qIdx++], theme));
                      }
                      if (wIdx < wisdoms.length) {
                        items.add(_buildWisdomCard(wisdoms[wIdx++], theme));
                      }
                      if (vIdx < videos.length) {
                        items.add(_buildVideoCard(videos[vIdx++], theme));
                      }
                      if (fIdx < facts.length) {
                        items.add(_buildFactCard(facts[fIdx++], theme, showBadge: true));
                      }
                    }

                    return <Widget>[
                      const SizedBox(height: 32),
                      _buildExtendedContentHeader(theme, 'Explore'),
                      const SizedBox(height: 16),
                      ...items,
                    ];
                  } else {
                    // Grouped Mode
                    bool headerShown = false;
                    final List<Widget> grouped = [];

                    if (data.wisdom.isNotEmpty) {
                      grouped.add(const SizedBox(height: 32));
                      grouped.add(_buildExtendedContentHeader(theme, 'Wisdom'));
                      grouped.add(const SizedBox(height: 16));
                      for (var w in data.wisdom) {
                        grouped.add(_buildWisdomCard(w, theme));
                      }
                      headerShown = true;
                    }

                    if (data.facts.isNotEmpty) {
                      grouped.add(const SizedBox(height: 32));
                      if (!headerShown) {
                        grouped.add(_buildExtendedContentHeader(theme, 'Did you know?'));
                        headerShown = true;
                      } else {
                        grouped.add(Text('Did you know?', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)));
                      }
                      grouped.add(const SizedBox(height: 16));
                      for (var f in data.facts) {
                        grouped.add(_buildFactCard(f, theme, showBadge: false));
                      }
                    }

                    if (data.quotes.isNotEmpty) {
                      grouped.add(const SizedBox(height: 32));
                      if (!headerShown) {
                        grouped.add(_buildExtendedContentHeader(theme, 'Famous Quotes'));
                        headerShown = true;
                      } else {
                        grouped.add(Text('Famous Quotes', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)));
                      }
                      grouped.add(const SizedBox(height: 16));
                      for (var q in data.quotes) {
                        grouped.add(_buildQuoteCard(q, theme));
                      }
                    }

                    if (data.videos.isNotEmpty) {
                      grouped.add(const SizedBox(height: 32));
                      if (!headerShown) {
                        grouped.add(_buildExtendedContentHeader(theme, 'Video Clips'));
                        headerShown = true;
                      } else {
                        grouped.add(Text('Video Clips', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)));
                      }
                      grouped.add(const SizedBox(height: 16));
                      for (var v in data.videos) {
                        grouped.add(_buildVideoCard(v, theme));
                      }
                    }

                    return grouped;
                  }
                }(),

                // Misspellings
                if (data.misspellings.isNotEmpty) ...[
                  SizedBox(height: 48),
                  Center(
                    child: Text(
                      'Common misspellings: ${data.misspellings.replaceAll('|', ', ')}',
                      style: TextStyle(color: Colors.white38, fontSize: 13, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 16),
                ]
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonBody(ThemeData theme) {
    final dictWord = DatabaseService.getWordById(widget.wordId);
    final localMeaning = dictWord?.meaning ?? '';

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final opacity = 0.15 + (_shimmerController.value * 0.20);
        final shimmerColor = Colors.white.withOpacity(opacity);
        final cardBg = Colors.white.withOpacity(0.04);
        final borderColor = Colors.white.withOpacity(0.08);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            if (_translatedWord != null && _translatedWord!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.translate, color: Colors.tealAccent, size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _translatedWord!,
                        style: const TextStyle(
                          color: Colors.tealAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 100,
                        height: 24,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (localMeaning.isNotEmpty)
                    Text(
                      localMeaning,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    )
                  else ...[
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 220,
                      height: 16,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 40,
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 18,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 200,
                    height: 14,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExtendedContentHeader(ThemeData theme, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.view_agenda_outlined),
              tooltip: 'Grouped',
              visualDensity: VisualDensity.compact,
              color: !_isShuffledContent ? theme.colorScheme.primary : Colors.white54,
              onPressed: () => setState(() => _isShuffledContent = false),
            ),
            IconButton(
              icon: const Icon(Icons.shuffle_rounded),
              tooltip: _isShuffledContent ? 'Re-shuffle' : 'Shuffled',
              visualDensity: VisualDensity.compact,
              color: _isShuffledContent ? theme.colorScheme.primary : Colors.white54,
              onPressed: () {
                setState(() {
                  if (_isShuffledContent) {
                    _shuffleSeedOffset++;
                  } else {
                    _isShuffledContent = true;
                  }
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWisdomCard(String w, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: const Border(left: BorderSide(color: Colors.blueAccent, width: 4)),
        color: Colors.blueAccent.withOpacity(0.1),
      ),
      child: Row(
        children: [
          Expanded(
            child: HighlightText(
              text: '"$w"',
              selfWord: widget.wordText?.toLowerCase() ?? '',
              learningWords: _learningWords,
              onWordTap: _onWordTap,
              normalStyle: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white, fontSize: 15, height: 1.4),
            ),
          ),
          _buildInlineAudioButton(w, 'wisdom_${w.hashCode}'),
        ],
      ),
    );
  }

  Widget _buildFactCard(String f, ThemeData theme, {bool showBadge = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.green.withOpacity(0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBadge) ...[
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Did you know?',
                  style: TextStyle(
                    color: Colors.greenAccent.shade100,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!showBadge) ...[
                const Icon(Icons.lightbulb_outline, color: Colors.greenAccent, size: 20),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: HighlightText(
                        text: f,
                        selfWord: widget.wordText?.toLowerCase() ?? '',
                        learningWords: _learningWords,
                        onWordTap: _onWordTap,
                        normalStyle: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                      ),
                    ),
                    _buildInlineAudioButton(f, 'fact_${f.hashCode}'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(WordQuote quote, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.surface, Colors.black.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote_rounded, color: theme.colorScheme.primary, size: 32),
              const Spacer(),
              _buildInlineAudioButton(quote.text, 'quote_${quote.text.hashCode}'),
            ],
          ),
          const SizedBox(height: 8),
          HighlightText(
            text: '"${quote.text}"',
            selfWord: widget.wordText?.toLowerCase() ?? '',
            learningWords: _learningWords,
            onWordTap: _onWordTap,
            normalStyle: const TextStyle(fontStyle: FontStyle.italic, fontSize: 17, color: Colors.white, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              quote.imageUrl != null 
                ? ClipOval(child: CachedMediaImage(
                    wordId: widget.wordId,
                    imageUrl: quote.imageUrl!, 
                    width: 40, 
                    height: 40, 
                    fit: BoxFit.cover,
                  ))
                : CircleAvatar(
                    backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
                    radius: 20,
                    child: Text(
                      quote.authorName.isNotEmpty ? quote.authorName[0] : '?',
                      style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
                    ),
                  ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quote.authorName,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                    ),
                    if (quote.authorRole.isNotEmpty)
                      Text(
                        quote.authorRole,
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(WordVideo video, ThemeData theme) {
    final bool isPlaying = _playingVideo == video;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isPlaying) ...[
            Container(
              color: Colors.black.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Playing Video',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: () => launchUrl(Uri.parse('https://www.youtube.com/watch?v=${video.youtubeId}&t=${video.startTimeMs ~/ 1000}s')),
                        icon: const Icon(Icons.open_in_browser, color: Colors.blueAccent, size: 20),
                        label: const Text('Open in Browser', style: TextStyle(color: Colors.blueAccent)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _closeVideo,
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        label: const Text('Close', style: TextStyle(color: Colors.white)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: theme.platform == TargetPlatform.windows
                    ? (_webviewController != null && _webviewController!.value.isInitialized
                        ? Webview(_webviewController!)
                        : Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)))
                    : (_videoError != null
                        ? Center(child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(_videoError!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                          ))
                        : _chewieController != null
                            ? Chewie(controller: _chewieController!)
                            : Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))),
              ),
            ),
          ] else ...[
            // Thumbnail view
            GestureDetector(
              onTap: () => _playVideo(video),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedMediaImage(
                      wordId: widget.wordId,
                      imageUrl: 'https://img.youtube.com/vi/${video.youtubeId}/hqdefault.jpg',
                      fit: BoxFit.cover,
                    ),
                    Container(
                      color: Colors.black.withOpacity(0.4),
                      child: Center(
                        child: Icon(Icons.play_circle_fill, size: 64, color: Colors.white.withOpacity(0.9)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          // Synchronized & Highlighted Subtitles below the frame
          if (video.subtitles.isNotEmpty)
            _buildVideoSubtitles(video, theme),
        ],
      ),
    );
  }

  Widget _buildSenseCard(WordSense sense, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            if (sense.imageUrl != null && sense.imageUrl!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                constraints: BoxConstraints(maxHeight: 300),
                child: SelectableImage(
                  imageUrl: sense.imageUrl!,
                  wordId: widget.wordId,
                  onPreferredSelected: () => setState(() {}),
                ),
              ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sense.ty,
                  style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: HighlightText(
                  text: sense.de,
                  selfWord: widget.wordText?.toLowerCase() ?? '',
                  learningWords: _learningWords,
                  onWordTap: _onWordTap,
                  normalStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white, height: 1.4),
                ),
              ),
              _buildInlineAudioButton(sense.de, 'sense_${sense.de.hashCode}'),
            ],
          ),
          if (sense.ex.isNotEmpty) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 3)),
                color: Colors.black.withOpacity(0.2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: HighlightText(
                text: '"${sense.ex}"',
                selfWord: widget.wordText?.toLowerCase() ?? '',
                learningWords: _learningWords,
                onWordTap: _onWordTap,
                normalStyle: TextStyle(fontStyle: FontStyle.italic, color: Colors.white70, fontSize: 15, height: 1.4),
              ),
                  ),
                  _buildInlineAudioButton(sense.ex, 'ex_${sense.ex.hashCode}'),
                ],
              ),
            ),
          ],
          if (sense.sy.isNotEmpty || sense.op.isNotEmpty) ...[
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (sense.sy.isNotEmpty)
                  ...sense.sy.split(',').map((s) => Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                    ),
                    child: Text(s.trim(), style: TextStyle(color: Colors.cyanAccent, fontSize: 13)),
                  )),
                if (sense.op.isNotEmpty)
                  ...sense.op.split(',').map((o) => Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Text(o.trim(), style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                  )),
              ],
            )
          ],
        ],
      ),
    );
  }

  Widget _buildTipCard(WordTip tip) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.purpleAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tip.imageUrl != null && tip.imageUrl!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
              constraints: BoxConstraints(maxHeight: 300),
              child: SelectableImage(
                imageUrl: tip.imageUrl!,
                wordId: widget.wordId,
                onPreferredSelected: () => setState(() {}),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tip.title.isNotEmpty)
                  Text(tip.title, style: TextStyle(color: Colors.purpleAccent.shade200, fontWeight: FontWeight.bold, fontSize: 16)),
                if (tip.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: HighlightText(
                      text: tip.description,
                      selfWord: widget.wordText?.toLowerCase() ?? '',
                      learningWords: _learningWords,
                      onWordTap: _onWordTap,
                      normalStyle: TextStyle(color: Colors.white, height: 1.4, fontSize: 15),
                    ),
                  ),
                if (tip.example.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 12),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      border: Border(left: BorderSide(color: Colors.purpleAccent.shade200, width: 3)),
                    ),
                    child: HighlightText(
                      text: '"${tip.example}"',
                      selfWord: widget.wordText?.toLowerCase() ?? '',
                      learningWords: _learningWords,
                      onWordTap: _onWordTap,
                      normalStyle: TextStyle(fontStyle: FontStyle.italic, color: Colors.white70, fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatReviewTime(int times) {
    if (times >= ProgressService().stepIntervals.length) return "Mastered";
    final days = ProgressService().stepIntervals[times].inDays;
    
    if (days == 0) return '0 days';
    if (days >= 30) {
      int months = days ~/ 30;
      return '$months month${months > 1 ? 's' : ''}';
    } else if (days >= 7) {
      int weeks = days ~/ 7;
      return '$weeks week${weeks > 1 ? 's' : ''}';
    } else {
      return '$days day${days > 1 ? 's' : ''}';
    }
  }

  Widget? _buildBottomActions() {
    if (_isKnown) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 800),
              child: Container(
                margin: EdgeInsets.fromLTRB(24, 0, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.cyan),
                              SizedBox(width: 8),
                              Text('Already Known', style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, height: 30, color: Colors.white12),
                    PopupMenuButton<String>(
                      offset: Offset(0, -60),
                      onSelected: (value) async {
                        if (value == 'learn') {
                          await ProgressService().markAsToLearn(widget.wordId);
                          setState(() {
                            _isKnown = false;
                            _isQueued = true;
                            _progress = null;
                          });
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'learn', child: Text('Move to should learn')),
                      ],
                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.cyan),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    if (_isQueued) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 800),
              child: Container(
                margin: EdgeInsets.fromLTRB(24, 0, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.queue_play_next, color: Theme.of(context).colorScheme.primary),
                              SizedBox(width: 8),
                              Text('In Learning Queue', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, height: 30, color: Colors.white12),
                    PopupMenuButton<String>(
                      offset: Offset(0, -60),
                      onSelected: (value) async {
                        if (value == 'known') {
                          await ProgressService().markAsKnown(widget.wordId);
                          setState(() {
                            _isKnown = true;
                            _isQueued = false;
                            _progress = null;
                          });
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'known', child: Text('Mark as Known')),
                      ],
                      icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    if (_progress != null) {
      // In learning process
      final times = _progress!.rememberCount;
      final totalSteps = 11; // Based on stepIntervals max step 11
      
      final reviewText = 'Review in ${_formatReviewTime(times)}';
      
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 800),
              child: Container(
                margin: EdgeInsets.fromLTRB(24, 0, 24, 24),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    // Progress visual
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.cyan, size: 20),
                              SizedBox(width: 6),
                              Text('$times times', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: List.generate(totalSteps, (index) {
                              return Expanded(
                                child: Container(
                                  height: 6,
                                  margin: EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: index < times ? Colors.cyan : Colors.white24,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 20),
                    // Review button
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.pop(context); // Act like back button
                            },
                            borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Text(reviewText, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          Container(width: 1, height: 20, color: Colors.white24),
                          PopupMenuButton<String>(
                            offset: Offset(0, -100),
                            onSelected: (value) async {
                              if (value == 'known') {
                                await ProgressService().markAsKnown(widget.wordId);
                                setState(() {
                                  _isKnown = true;
                                  _isQueued = false;
                                  _progress = null;
                                });
                              } else if (value == 'learn') {
                                await ProgressService().markAsToLearn(widget.wordId);
                                setState(() {
                                  _isKnown = false;
                                  _isQueued = true;
                                  _progress = null;
                                });
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(value: 'known', child: Text('Mark as Known')),
                              PopupMenuItem(value: 'learn', child: Text('Move to should learn')),
                            ],
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                              child: Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Not known, not learning yet
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 800),
            child: Container(
              margin: EdgeInsets.fromLTRB(24, 0, 24, 24),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await ProgressService().addWordToLearn(widget.wordId);
                        if (mounted) {
                          setState(() {
                            _isQueued = true;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text('Should Learn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await ProgressService().markAsKnown(widget.wordId);
                        setState(() {
                          _isKnown = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan.withOpacity(0.15),
                        foregroundColor: Colors.cyanAccent,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text('Already Knew', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SelectableImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final int wordId;
  final VoidCallback onPreferredSelected;

  const SelectableImage({
    Key? key,
    required this.imageUrl,
    this.fit = BoxFit.contain,
    required this.wordId,
    required this.onPreferredSelected,
  }) : super(key: key);

  @override
  _SelectableImageState createState() => _SelectableImageState();
}

class _SelectableImageState extends State<SelectableImage> {
  bool _showOverlay = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showOverlay = !_showOverlay;
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.network(
            widget.imageUrl,
            width: double.infinity,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) => Container(
              width: double.infinity,
              color: Colors.grey.withOpacity(0.1),
              child: Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
          if (_showOverlay)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.star),
                    label: Text('Set as Preferred'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () async {
                      await ProgressService().setPreferredImage(widget.wordId, widget.imageUrl);
                      setState(() {
                        _showOverlay = false;
                      });
                      widget.onPreferredSelected();
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CompareWithSection extends StatefulWidget {
  final List<WordComparison> comparisons;
  final String selfWord;
  final Map<String, int> learningWords;
  final void Function(int id, String text)? onWordTap;

  const CompareWithSection({
    Key? key,
    required this.comparisons,
    required this.selfWord,
    required this.learningWords,
    required this.onWordTap,
  }) : super(key: key);

  @override
  _CompareWithSectionState createState() => _CompareWithSectionState();
}

class _CompareWithSectionState extends State<CompareWithSection> {
  WordComparison? _selectedComparison;

  @override
  void initState() {
    super.initState();
    if (widget.comparisons.isNotEmpty) {
      _selectedComparison = widget.comparisons.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 32),
        Center(
          child: Text('Compare with', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: Colors.purpleAccent.shade100)),
        ),
        SizedBox(height: 16),
        Center(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: widget.comparisons.map((comp) {
              final isSelected = _selectedComparison == comp;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedComparison = comp;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.cyan : Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    comp.word,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (_selectedComparison != null) ...[
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
            ),
            child: HighlightText(
              text: _selectedComparison!.text,
              selfWord: widget.selfWord,
              learningWords: widget.learningWords,
              onWordTap: widget.onWordTap,
              normalStyle: TextStyle(color: Colors.white, fontSize: 16, height: 1.6),
            ),
          ),
        ],
      ],
    );
  }
}

class SlidingCardsView extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double viewportFraction;

  const SlidingCardsView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.viewportFraction = 1.0,
  });

  @override
  State<SlidingCardsView> createState() => _SlidingCardsViewState();
}

class _SlidingCardsViewState extends State<SlidingCardsView> {
  late PageController _pageController;
  int _currentPage = 0;
  final Map<int, double> _heights = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: widget.itemCount <= 1 ? 1.0 : widget.viewportFraction,
    );
  }

  @override
  void didUpdateWidget(SlidingCardsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount || oldWidget.viewportFraction != widget.viewportFraction) {
      _heights.clear();
      _currentPage = 0;
      _pageController.dispose();
      _pageController = PageController(
        viewportFraction: widget.itemCount <= 1 ? 1.0 : widget.viewportFraction,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) return const SizedBox.shrink();
    if (widget.itemCount == 1) {
      return widget.itemBuilder(context, 0);
    }

    double maxHeight = _heights.values.fold(0.0, (prev, h) => h > prev ? h : prev);
    if (maxHeight == 0) maxHeight = 280;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth * widget.viewportFraction;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                // Offstage measurement pass
                Offstage(
                  offstage: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(widget.itemCount, (index) {
                      return _MeasureSize(
                        onChange: (size) {
                          if (mounted && (_heights[index] ?? 0) != size.height) {
                            setState(() {
                              _heights[index] = size.height;
                            });
                          }
                        },
                        child: SizedBox(
                          width: cardWidth,
                          child: widget.itemBuilder(context, index),
                        ),
                      );
                    }),
                  ),
                ),
                // PageView
                SizedBox(
                  height: maxHeight,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                        PointerDeviceKind.stylus,
                      },
                    ),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: widget.itemCount,
                      onPageChanged: (page) => setState(() => _currentPage = page),
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: cardWidth,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: double.infinity,
                              child: widget.itemBuilder(context, index),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_currentPage > 0)
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20, color: Colors.white70),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Previous',
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  )
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 8),
                ...List.generate(widget.itemCount, (i) {
                  final isSelected = i == _currentPage;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      width: isSelected ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white24,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                if (_currentPage < widget.itemCount - 1)
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20, color: Colors.white70),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Next',
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  )
                else
                  const SizedBox(width: 20),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  final ValueChanged<Size> onChange;
  Size? _oldSize;

  _MeasureSizeRenderObject(this.onChange);

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size ?? Size.zero;
    if (_oldSize != newSize) {
      _oldSize = newSize;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChange(newSize);
      });
    }
  }
}

class _MeasureSize extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onChange;

  const _MeasureSize({
    required this.onChange,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderObject(onChange);
  }

  @override
  void updateRenderObject(BuildContext context, covariant _MeasureSizeRenderObject renderObject) {
    // Keep renderObject updated
  }
}
