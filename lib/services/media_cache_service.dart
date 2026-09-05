import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/word.dart';

class MediaCacheService {
  static Future<Directory> _getWordCacheDir(int wordId) async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/wordup_cache/$wordId');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  static String _getFileNameFromUrl(String url) {
    // Dart's String.hashCode is randomized per execution!
    // We must use a stable hashing function to find the file after app restart.
    int stableHash = 0;
    for (int i = 0; i < url.length; i++) {
      stableHash = 31 * stableHash + url.codeUnitAt(i);
      stableHash = stableHash & 0xFFFFFFFF; // keep it 32-bit
    }
    
    final uri = Uri.parse(url);
    final fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'unknown';
    
    // Ensure filename isn't overly long for Windows
    String safeName = fileName;
    if (safeName.length > 50) {
      safeName = safeName.substring(safeName.length - 50);
    }
    
    return '${stableHash}_$safeName';
  }

  static Future<File?> getLocalFile(int wordId, String originalUrl) async {
    try {
      final cacheDir = await _getWordCacheDir(wordId);
      final fileName = _getFileNameFromUrl(originalUrl);
      final file = File('${cacheDir.path}/$fileName');
      if (await file.exists()) {
        return file;
      }
    } catch (e) {
      print('Error getting local file for $originalUrl: $e');
    }
    return null;
  }

  static Future<void> cacheWordMedia(int wordId, WordData data) async {
    try {
      final cacheDir = await _getWordCacheDir(wordId);
      
      // Collect all image URLs
      final Set<String> urlsToCache = {};
      
      if (data.imageUrl != null && data.imageUrl!.isNotEmpty) {
        urlsToCache.add(data.imageUrl!);
      }
      
      for (var sense in data.senses) {
        if (sense.imageUrl != null && sense.imageUrl!.isNotEmpty) {
          urlsToCache.add(sense.imageUrl!);
        }
        for (var tip in sense.tips) {
          if (tip.imageUrl != null && tip.imageUrl!.isNotEmpty) {
            urlsToCache.add(tip.imageUrl!);
          }
        }
      }
      
      for (var video in data.videos) {
        urlsToCache.add('https://img.youtube.com/vi/${video.youtubeId}/hqdefault.jpg');
      }

      // Download each URL
      for (var url in urlsToCache) {
        try {
          final fileName = _getFileNameFromUrl(url);
          final file = File('${cacheDir.path}/$fileName');
          
          if (!await file.exists()) {
            final response = await http.get(Uri.parse(url));
            if (response.statusCode == 200) {
              await file.writeAsBytes(response.bodyBytes);
            }
          }
        } catch (e) {
          print('Failed to cache media $url: $e');
        }
      }
    } catch (e) {
      print('Error in cacheWordMedia for word $wordId: $e');
    }
  }

  static Future<void> clearWordCache(int wordId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      
      // Delete the word's media directory
      final mediaDir = Directory('${dir.path}/wordup_cache/$wordId');
      if (await mediaDir.exists()) {
        await mediaDir.delete(recursive: true);
        print('Deleted media cache for word $wordId');
      }
      
      // Delete the JSON data file
      final jsonFile = File('${dir.path}/wordup_cache/$wordId.json');
      if (await jsonFile.exists()) {
        await jsonFile.delete();
        print('Deleted JSON cache for word $wordId');
      }
    } catch (e) {
      print('Error clearing cache for word $wordId: $e');
    }
  }
}
