import 'dart:convert';
import 'encryption_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/word.dart';
import 'progress_service.dart';
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

  static Future<Map<String, dynamic>> fetchWordData(String wordId, {String? wordText, bool isPrefetch = false}) async {
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

    // 2. Fetch from network if not cached
    if (needsCdnFetch) {
      if (wordText != null) {
        // Fetch CDN and Zann CONCURRENTLY to half the loading time!
        final results = await Future.wait([
          _downloadAndExtractFromCdn(wordId),
          _fetchZannDataOnly(wordText),
        ]);
        
        data = results[0];
        final zannData = results[1];
        
        if (zannData.containsKey('ZannQuotes')) data['ZannQuotes'] = zannData['ZannQuotes'];
        if (zannData.containsKey('ZannSenses')) data['ZannSenses'] = zannData['ZannSenses'];
        
        if (!kIsWeb && localFile != null) {
          await localFile.writeAsString(json.encode(data));
        }
        if (kIsWeb) _webMemoryCache[wordId] = data;
        return data!;
      } else {
        data = await _downloadAndExtractFromCdn(wordId);
        if (!kIsWeb && localFile != null) {
          await localFile.writeAsString(json.encode(data));
        }
        if (kIsWeb) _webMemoryCache[wordId] = data;
        return data!;
      }
    }

    // 3. If loaded from cache but lacks Zann data...
    if (wordText != null && data != null) {
      if (!data.containsKey('ZannSenses') && !data.containsKey('ZannQuotes')) {
        final zannData = await _fetchZannDataOnly(wordText);
        if (zannData.containsKey('ZannQuotes')) data['ZannQuotes'] = zannData['ZannQuotes'];
        if (zannData.containsKey('ZannSenses')) data['ZannSenses'] = zannData['ZannSenses'];
        
        if (!kIsWeb && localFile != null) {
          await localFile.writeAsString(json.encode(data));
        }
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
          _downloadAndCacheWord(id.toString());
          prefetchedCount++;
        }
      }
    } catch (e) {
      print('Background prefetch failed: $e');
    }
  }

  static Future<void> _downloadAndCacheWord(String wordId) async {
    try {
      await fetchWordData(wordId, isPrefetch: true);
    } catch (e) {
      // Silent failure
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

  static Future<String> getAudioPath(String wordId, {String? wordText, required bool isUk, required bool useGoogleTts}) async {
    final text = wordText ?? 'word';
    final lang = isUk ? 'en-uk' : 'en-us';
    
    if (useGoogleTts) {
      final urlString = '${EncryptionService.decryptString('GMYdOcvHclMrN1/WjlGrHmOwZw4A0OLl4lrHfVFiDFo5ADRT1LBAE6dONVg+MdLjfWI2EojCarPcBZiHivvBCA==')}$lang&client=tw-ob&q=${Uri.encodeComponent(text)}';
      if (kIsWeb) return urlString;
      
      final file = await _getLocalFile('${wordId}_tts_$lang.mp3');
      if (await file.exists()) return file.path;
      
      final response = await http.get(Uri.parse(urlString));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
      throw Exception('Failed to load Google TTS audio');
    } else {
      // Use Youdao Dictionary API (type=1 for UK, type=2 for US)
      final type = isUk ? 1 : 2;
      final dictUrl = '${EncryptionService.decryptString('UukRlyEUJoSVzxGCxzm3tHIBYBUKEQuxolnSdWfJKg02/Iesb2ZnDZWZQWOBtVcp')}${Uri.encodeComponent(text)}&type=$type';
      
      if (kIsWeb) return dictUrl;
      
      final file = await _getLocalFile('${wordId}_dict_$lang.mp3');
      if (await file.exists()) return file.path;
      
      try {
        final response = await http.get(Uri.parse(dictUrl)).timeout(Duration(seconds: 5));
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

  static Future<String> getSentenceAudioPath(String text, {required bool isUk}) async {
    final lang = isUk ? 'en-uk' : 'en-us';
    // Use Google TTS for sentences since dictionary APIs only work well for single words
    final urlString = '${EncryptionService.decryptString('GMYdOcvHclMrN1/WjlGrHmOwZw4A0OLl4lrHfVFiDFo5ADRT1LBAE6dONVg+MdLjfWI2EojCarPcBZiHivvBCA==')}$lang&client=tw-ob&q=${Uri.encodeComponent(text)}';
    
    if (kIsWeb) return urlString;
    
    final hash = md5.convert(utf8.encode(text)).toString();
    final file = await _getLocalFile('sentence_${hash}_$lang.mp3');
    
    if (await file.exists()) return file.path;
    
    final response = await http.get(Uri.parse(urlString));
    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    }
    throw Exception('Failed to load sentence TTS audio');
  }

}