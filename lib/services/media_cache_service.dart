import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/word.dart';
import '../services/encryption_service.dart';


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

  static Future<File?> cacheSingleMedia(int wordId, String url) async {
    try {
      final cacheDir = await _getWordCacheDir(wordId);
      final fileName = _getFileNameFromUrl(url);
      final file = File('${cacheDir.path}/$fileName');
      if (await file.exists() && await file.length() > 0) {
        return file;
      }
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (e) {
      print('Failed to cache single media $url: $e');
    }
    return null;
  }

  /// Converts a WordUp/Zann CDN image URL to its Hugging Face backup URL.
  /// e.g. https://word-images.cdn-wordup.com/sensesMobile/d70a7242-f5a5.webp
  ///   → https://huggingface.co/datasets/derfang/worddown-media/resolve/main/images/d7/0a/d70a7242-f5a5.webp.enc
  static String? toHuggingFaceUrl(String originalUrl) {
    try {
      final filename = Uri.parse(originalUrl).pathSegments.last; // e.g. "d70a7242-f5a5.webp"
      if (filename.isEmpty || !filename.contains('.')) return null;
      final p1 = filename.substring(0, 2).toLowerCase();
      final p2 = filename.substring(2, 4).toLowerCase();
      return 'https://huggingface.co/datasets/derfang/worddown-media'
             '/resolve/main/images/$p1/$p2/$filename.enc';
    } catch (_) {
      return null;
    }
  }

  /// Downloads a .webp.enc from Hugging Face, decrypts it in RAM,
  /// writes the plain .webp to disk, and returns the local File.
  static Future<File?> fetchAndDecryptFromHuggingFace(
    int wordId,
    String originalUrl,
  ) async {
    if (!EncryptionService.isInitialized) return null;
    final hfUrl = toHuggingFaceUrl(originalUrl);
    if (hfUrl == null) return null;

    try {
      final response = await http.get(Uri.parse(hfUrl)).timeout(const Duration(milliseconds: 2000));
      if (response.statusCode != 200) return null;

      final plainBytes = EncryptionService.decryptBytes(response.bodyBytes);
      if (plainBytes == null || plainBytes.isEmpty) return null;

      // Store the decrypted .webp using the same stable filename as normal cache
      final cacheDir = await _getWordCacheDir(wordId);
      final fileName = _getFileNameFromUrl(originalUrl);
      final file = File('${cacheDir.path}/$fileName');
      await file.writeAsBytes(plainBytes);
      return file;
    } catch (e) {
      print('Failed to fetch/decrypt HF image for $originalUrl: $e');
      return null;
    }
  }

  /// Ensures media is cached locally to disk:
  /// 1. Instant return if already on local disk.
  /// 2. Fetches & decrypts from Hugging Face backup (with 2s timeout).
  /// 3. Falls back to original CDN URL (with 5s timeout).
  /// Returns the local File, or null if all attempts fail.
  static Future<File?> ensureMediaCached(int wordId, String originalUrl) async {
    // 1. Check local disk
    final local = await getLocalFile(wordId, originalUrl);
    if (local != null && await local.exists() && await local.length() > 0) {
      return local;
    }

    // 2. Try Hugging Face backup
    try {
      final hfFile = await fetchAndDecryptFromHuggingFace(wordId, originalUrl);
      if (hfFile != null && await hfFile.exists() && await hfFile.length() > 0) {
        return hfFile;
      }
    } catch (_) {}

    // 3. Fall back to original CDN
    try {
      return await cacheSingleMedia(wordId, originalUrl);
    } catch (_) {}

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
            final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
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
