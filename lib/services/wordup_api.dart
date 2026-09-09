import 'dart:convert';
import 'encryption_service.dart';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'progress_service.dart';
import 'database_service.dart';
import 'edge_tts_service.dart';
import 'settings_service.dart';
import 'media_cache_service.dart';
import '../models/word.dart';
Map<String, dynamic> _decodeJsonMap(String content) {
  return json.decode(content) as Map<String, dynamic>;
}

Map<String, dynamic> _parseZannHtml(String html) {
  final Map<String, dynamic> data = {};
  final jsonRegex = RegExp(r'<script id="__NEXT_DATA__" type="application/json"[^>]*>([\s\S]*?)</script>');
  final jsonMatch = jsonRegex.firstMatch(html);
  
  if (jsonMatch != null) {
    final jsonStr = jsonMatch.group(1)!;
    final nextData = json.decode(jsonStr);
    final pageProps = nextData['props']?['pageProps'];
    
    if (pageProps != null) {
      if (pageProps['quotes'] != null) {
        data['ZannQuotes'] = pageProps['quotes'];
      }
      if (pageProps['senses'] != null) {
        data['ZannSenses'] = pageProps['senses'];
      }
    }
  }
  return data;
}

Map<String, dynamic> _decodeGzipBytes(List<int> bytes) {
  String jsonString;
  if (bytes.length >= 2 && bytes[0] == 0x1F && bytes[1] == 0x8B) {
    final decompressed = GZipDecoder().decodeBytes(bytes);
    jsonString = utf8.decode(decompressed);
  } else {
    jsonString = utf8.decode(bytes);
  }
  return json.decode(jsonString) as Map<String, dynamic>;
}

class WordupApi {
  static final String _token = EncryptionService.decryptString('+af/iXwKxqZD7kKqV20wJYIV908a3oM1/VoQfveGmXXWRs2AZlEx3Np4BzXarCpL');
  static final Map<String, Map<String, dynamic>> _webMemoryCache = {};
  
  static Future<File> _getLocalFile(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/wordup_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return File('${cacheDir.path}/$filename');
  }

  static Future<Map<String, dynamic>> fetchWordData(
    String wordId, {
    String? wordText,
    bool isPrefetch = false,
    void Function(Map<String, dynamic> extraData)? onExtraDataLoaded,
  }) async {
    Map<String, dynamic>? data;
    bool needsCdnFetch = false;
    File? localFile;

    // 1. Load local cache
    if (kIsWeb) {
      if (_webMemoryCache.containsKey(wordId)) {
        data = _webMemoryCache[wordId]!;
      } else {
        needsCdnFetch = true;
      }
    } else {
      localFile = await _getLocalFile('$wordId.json');
      if (await localFile.exists()) {
        final contents = await localFile.readAsString();
        data = await compute(_decodeJsonMap, contents);
      } else {
        needsCdnFetch = true;
      }
    }

    // 2. Fetch from network CDN if not cached
    if (needsCdnFetch) {
      data = await _downloadAndExtractFromCdn(wordId);
      if (!kIsWeb && localFile != null) {
        await localFile.writeAsString(json.encode(data));
      }
      if (kIsWeb) _webMemoryCache[wordId] = data;
    }

    // 3. Asynchronously fetch Zann extra quotes in the background without blocking the UI
    if (wordText != null && data != null) {
      final currentData = data;
      if (!currentData.containsKey('ZannSenses') || !currentData.containsKey('ZannQuotes')) {
        _fetchZannDataOnly(wordText).then((zannData) async {
          if (zannData.isNotEmpty) {
            if (zannData.containsKey('ZannQuotes')) currentData['ZannQuotes'] = zannData['ZannQuotes'];
            if (zannData.containsKey('ZannSenses')) currentData['ZannSenses'] = zannData['ZannSenses'];
            if (!kIsWeb && localFile != null) {
              await localFile.writeAsString(json.encode(currentData));
            }
            if (onExtraDataLoaded != null) {
              onExtraDataLoaded(zannData);
            }
          }
        }).catchError((_) {});
      }
    }
    
    if (!isPrefetch) {
      _triggerBackgroundPrefetch();
    }
    return data ?? {};
  }

  static Future<void> _triggerBackgroundPrefetch() async {
    try {
      final progress = ProgressService();
      
      final candidateIds = <int>{
        ...progress.queuedWordsToLearn,
        ...progress.learningWords.map((p) => p.wordId),
      };
      
      int prefetchedCount = 0;
      for (final id in candidateIds) {
        if (prefetchedCount >= 2) break;
        
        bool isCached = false;
        if (kIsWeb) {
          isCached = _webMemoryCache.containsKey(id.toString());
        } else {
          final file = await _getLocalFile('$id.json');
          isCached = await file.exists();
        }
        
        if (!isCached) {
          final word = DatabaseService.getWordById(id);
          _downloadAndCacheWord(id.toString(), wordText: word?.text);
          prefetchedCount++;
        }
      }
    } catch (e) {
      print('Background prefetch failed: $e');
    }
  }

  static Future<void> _downloadAndCacheWord(String wordId, {String? wordText}) async {
    try {
      await fetchWordData(wordId, wordText: wordText, isPrefetch: true);
    } catch (e) {
      // Silent failure
    }
  }

  /// Proactively prefetches and caches WordData JSON, media illustrations, and pronunciation audio.
  /// Designed for review and learning sessions to ensure instant next-word loading.
  static Future<void> prefetchWord(
    int wordId, {
    bool includeMedia = true,
    bool includeAudio = true,
  }) async {
    try {
      final word = DatabaseService.getWordById(wordId);
      final wordText = word?.text;
      
      // 1. Fetch JSON definitions
      final json = await fetchWordData(wordId.toString(), wordText: wordText, isPrefetch: true);
      
      // 2. Cache media (images & video thumbnails)
      if (includeMedia && json.isNotEmpty) {
        try {
          final wordData = WordData.fromJson(wordId, json);
          // Fire and forget media caching
          MediaCacheService.cacheWordMedia(wordId, wordData).catchError((_) {});
        } catch (_) {}
      }

      // 3. Cache dictionary pronunciation audio
      if (includeAudio && wordText != null && wordText.isNotEmpty) {
        try {
          // Preload US dictionary pronunciation
          getAudioPath(wordId.toString(), wordText: wordText, isUk: false, useGoogleTts: false).catchError((_) => '');
        } catch (_) {}
      }
    } catch (_) {
      // Background prefetch should fail silently without throwing
    }
  }

  static Future<Map<String, dynamic>> _fetchZannDataOnly(String wordText) async {
    try {
      final zannRoot = wordText.toLowerCase().replaceAll(' ', '-');
      final url = Uri.parse('${EncryptionService.decryptString('4SARJC22cy8Xc8tGNtqJXytZeeNhNbFt9NzS1+kNQeQ6xCPSemgLBlTS6jrRzkT7')}$zannRoot');
      final response = await http.get(url, headers: {'accept': 'text/html'});
      if (response.statusCode == 200) {
        // Run heavy Regex and JSON decode in background!
        return await compute(_parseZannHtml, response.body);
      }
    } catch (e) {
      print('Error fetching zann.app data: $e');
    }
    return {};
  }

  static Future<Map<String, dynamic>> _downloadAndExtractFromCdn(String wordId) async {
    final url = Uri.parse('${EncryptionService.decryptString('jztRb7JU7U8xmVZO/HBR834pGw+vGK/tS7vtgmIvF5Lldr15UJj7QCOpJONlEQuY')}$wordId.gz?t=$_token');
    final response = await http.get(url, headers: {
      'accept': '*/*',
      'origin': EncryptionService.decryptString('mo9kn0ePoTbvnQQlU46vuynFwAIG3ToauncQc16fxXo='),
      'referer': EncryptionService.decryptString('mo9kn0ePoTbvnQQlU46vu907Y7vVNYhvjE7ffCxYHj0='),
      'x-wordup-app-id': EncryptionService.decryptString('CAORgS8bg7cfoT5xXdrRGA=='),
      'x-wordup-source': EncryptionService.decryptString('pCnmcu9hiQZvgO+c56SoCQ==')
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch from WordUp CDN: ${response.statusCode}');
    }

    // Run heavy GZIP and JSON decode in background!
    return await compute(_decodeGzipBytes, response.bodyBytes);
  }

  static int _ttsPlaybackIndex = 0;

  static Future<File> _getTempTtsFile() async {
    final dir = await getTemporaryDirectory();
    _ttsPlaybackIndex = (_ttsPlaybackIndex + 1) % 5;
    return File('${dir.path}/tts_temp_$_ttsPlaybackIndex.mp3');
  }

  static Future<String> getAudioPath(String wordId, {String? wordText, required bool isUk, required bool useGoogleTts}) async {
    final text = wordText ?? 'word';
    final lang = isUk ? 'en-uk' : 'en-us';
    
    if (useGoogleTts) {
      return getSentenceAudioPath(text, isUk: isUk);
    } else {
      // Use Youdao Dictionary API (type=1 for UK, type=2 for US)
      final type = isUk ? 1 : 2;
      final dictUrl = '${EncryptionService.decryptString('UukRlyEUJoSVzxGCxzm3tHIBYBUKEQuxolnSdWfJKg02/Iesb2ZnDZWZQWOBtVcp')}${Uri.encodeComponent(text)}&type=$type';
      
      if (kIsWeb) return dictUrl;
      
      final file = await _getLocalFile('${wordId}_dict_$lang.mp3');
      if (await file.exists()) return file.path;
      
      try {
        final response = await http.get(Uri.parse(dictUrl)).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          await file.writeAsBytes(response.bodyBytes);
          return file.path;
        }
      } catch (e) {
        throw Exception('Dictionary API timed out or is unreachable');
      }
      
      throw Exception('Dictionary audio not found for this accent');
    }
  }

  static List<String> _splitTextForTts(String text, {int maxChunkLength = 140}) {
    final List<String> chunks = [];
    final sentences = text.split(RegExp(r'(?<=[.;:?!,])\s+'));
    
    String current = '';
    for (var s in sentences) {
      final candidate = current.isEmpty ? s : '$current $s';
      if (candidate.length <= maxChunkLength) {
        current = candidate;
      } else {
        if (current.isNotEmpty) chunks.add(current);
        if (s.length > maxChunkLength) {
          // If an individual clause is longer than maxChunkLength, split by words
          final words = s.split(' ');
          current = '';
          for (var w in words) {
            final wordCandidate = current.isEmpty ? w : '$current $w';
            if (wordCandidate.length <= maxChunkLength) {
              current = wordCandidate;
            } else {
              if (current.isNotEmpty) chunks.add(current);
              current = w;
            }
          }
        } else {
          current = s;
        }
      }
    }
    if (current.isNotEmpty) chunks.add(current);
    return chunks;
  }

  static Future<String> _fetchGoogleSentenceAudio(String text, {required bool isUk}) async {
    final lang = isUk ? 'en-uk' : 'en-us';
    final baseUrl = '${EncryptionService.decryptString('GMYdOcvHclMrN1/WjlGrHmOwZw4A0OLl4lrHfVFiDFo5ADRT1LBAE6dONVg+MdLjfWI2EojCarPcBZiHivvBCA==')}$lang&client=tw-ob&q=';
    
    if (kIsWeb && text.length <= 140) {
      return '$baseUrl${Uri.encodeComponent(text)}';
    }

    final chunks = _splitTextForTts(text, maxChunkLength: 140);
    final List<int> combinedBytes = [];

    for (var chunk in chunks) {
      final url = '$baseUrl${Uri.encodeComponent(chunk)}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        combinedBytes.addAll(response.bodyBytes);
      } else {
        throw Exception('Failed to load Google TTS audio chunk (${response.statusCode})');
      }
    }

    if (combinedBytes.isNotEmpty) {
      if (kIsWeb) {
        return 'data:audio/mp3;base64,${base64Encode(combinedBytes)}';
      }
      final file = await _getTempTtsFile();
      await file.writeAsBytes(combinedBytes);
      return file.path;
    }
    throw Exception('Failed to load Google TTS audio');
  }

  static Future<String> getSentenceAudioPath(String text, {required bool isUk}) async {
    final settings = SettingsService();
    final enableEdge = settings.enableEdgeTts;
    final enableGoogle = settings.enableGoogleTts;

    bool useEdge = true;
    if (enableEdge && enableGoogle) {
      useEdge = Random().nextBool();
    } else if (enableEdge) {
      useEdge = true;
    } else {
      useEdge = false;
    }

    if (useEdge) {
      try {
        final audioBytes = await EdgeTtsService.synthesize(text, isUk: isUk);
        if (audioBytes.isNotEmpty) {
          if (kIsWeb) {
            return 'data:audio/mp3;base64,${base64Encode(audioBytes)}';
          }
          final file = await _getTempTtsFile();
          await file.writeAsBytes(audioBytes);
          return file.path;
        }
      } catch (e) {
        print('Edge TTS failed ($e), falling back to Google TTS...');
        if (!enableGoogle) {
          rethrow;
        }
      }
    }

    return await _fetchGoogleSentenceAudio(text, isUk: isUk);
  }

}