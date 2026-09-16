import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'wordup_api.dart';

class CacheCategoryStats {
  final int count;
  final int bytes;

  const CacheCategoryStats({required this.count, required this.bytes});

  static const empty = CacheCategoryStats(count: 0, bytes: 0);

  String get formattedSize => CacheManagerService.formatBytes(bytes);
}

class AppCacheStats {
  final CacheCategoryStats wordDefinitions;
  final CacheCategoryStats pronunciations;
  final CacheCategoryStats media;

  const AppCacheStats({
    required this.wordDefinitions,
    required this.pronunciations,
    required this.media,
  });

  static const empty = AppCacheStats(
    wordDefinitions: CacheCategoryStats.empty,
    pronunciations: CacheCategoryStats.empty,
    media: CacheCategoryStats.empty,
  );

  int get totalBytes => wordDefinitions.bytes + pronunciations.bytes + media.bytes;
  int get totalCount => wordDefinitions.count + pronunciations.count + media.count;
  String get formattedTotalSize => CacheManagerService.formatBytes(totalBytes);
}

class CacheManagerService {
  static Future<Directory?> _getCacheDir() async {
    if (kIsWeb) return null;
    try {
      final appDocs = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDocs.path}/wordup_cache');
      return cacheDir;
    } catch (_) {
      return null;
    }
  }

  /// Calculates real-time detailed storage metrics for all cache categories.
  static Future<AppCacheStats> getCacheStats() async {
    if (kIsWeb) return AppCacheStats.empty;

    try {
      final cacheDir = await _getCacheDir();
      if (cacheDir == null || !await cacheDir.exists()) {
        return AppCacheStats.empty;
      }

      int defCount = 0;
      int defBytes = 0;

      int audioCount = 0;
      int audioBytes = 0;

      int mediaCount = 0;
      int mediaBytes = 0;

      await for (final entity in cacheDir.list(followLinks: false)) {
        try {
          if (entity is File) {
            final name = entity.uri.pathSegments.isNotEmpty ? entity.uri.pathSegments.last : '';
            final stat = await entity.stat();
            final size = stat.size;

            if (name.endsWith('.json')) {
              defCount++;
              defBytes += size;
            } else if (name.endsWith('.mp3')) {
              audioCount++;
              audioBytes += size;
            }
          } else if (entity is Directory) {
            // Word media subdirectories (e.g., wordup_cache/<wordId>/)
            await for (final subEntity in entity.list(recursive: true, followLinks: false)) {
              if (subEntity is File) {
                final stat = await subEntity.stat();
                mediaCount++;
                mediaBytes += stat.size;
              }
            }
          }
        } catch (_) {}
      }

      return AppCacheStats(
        wordDefinitions: CacheCategoryStats(count: defCount, bytes: defBytes),
        pronunciations: CacheCategoryStats(count: audioCount, bytes: audioBytes),
        media: CacheCategoryStats(count: mediaCount, bytes: mediaBytes),
      );
    } catch (e) {
      debugPrint('Error computing cache stats: $e');
      return AppCacheStats.empty;
    }
  }

  /// Clears only downloaded word definition JSON files.
  static Future<CacheCategoryStats> clearWordDefinitions() async {
    if (kIsWeb) {
      WordupApi.clearMemoryCache();
      return CacheCategoryStats.empty;
    }

    int deletedCount = 0;
    int freedBytes = 0;

    try {
      WordupApi.clearMemoryCache();
      final cacheDir = await _getCacheDir();
      if (cacheDir == null || !await cacheDir.exists()) {
        return CacheCategoryStats.empty;
      }

      await for (final entity in cacheDir.list(followLinks: false)) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            final stat = await entity.stat();
            await entity.delete();
            deletedCount++;
            freedBytes += stat.size;
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Error clearing word definitions cache: $e');
    }

    return CacheCategoryStats(count: deletedCount, bytes: freedBytes);
  }

  /// Clears only downloaded pronunciation audio files.
  static Future<CacheCategoryStats> clearPronunciations() async {
    if (kIsWeb) return CacheCategoryStats.empty;

    int deletedCount = 0;
    int freedBytes = 0;

    try {
      final cacheDir = await _getCacheDir();
      if (cacheDir == null || !await cacheDir.exists()) {
        return CacheCategoryStats.empty;
      }

      await for (final entity in cacheDir.list(followLinks: false)) {
        if (entity is File && entity.path.endsWith('.mp3')) {
          try {
            final stat = await entity.stat();
            await entity.delete();
            deletedCount++;
            freedBytes += stat.size;
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Error clearing pronunciations cache: $e');
    }

    return CacheCategoryStats(count: deletedCount, bytes: freedBytes);
  }

  /// Clears all downloaded illustrations and media files (images, thumbnails).
  static Future<CacheCategoryStats> clearMedia() async {
    if (kIsWeb) return CacheCategoryStats.empty;

    int deletedCount = 0;
    int freedBytes = 0;

    try {
      final cacheDir = await _getCacheDir();
      if (cacheDir == null || !await cacheDir.exists()) {
        return CacheCategoryStats.empty;
      }

      await for (final entity in cacheDir.list(followLinks: false)) {
        if (entity is Directory) {
          try {
            await for (final subEntity in entity.list(recursive: true, followLinks: false)) {
              if (subEntity is File) {
                final stat = await subEntity.stat();
                deletedCount++;
                freedBytes += stat.size;
              }
            }
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Error clearing media cache: $e');
    }

    return CacheCategoryStats(count: deletedCount, bytes: freedBytes);
  }

  /// Clears all cached word files, dictionary audios, and media assets.
  /// (Does NOT touch SQLite progress database, user credentials, or settings!)
  static Future<AppCacheStats> clearAllCache() async {
    if (kIsWeb) {
      WordupApi.clearMemoryCache();
      return AppCacheStats.empty;
    }

    final initialStats = await getCacheStats();

    try {
      WordupApi.clearMemoryCache();
      final cacheDir = await _getCacheDir();
      if (cacheDir != null && await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create(recursive: true);
      }

      // Also ensure legacy audio cache dir is cleaned if present
      final appDocs = await getApplicationDocumentsDirectory();
      final legacyAudioDir = Directory('${appDocs.path}/wordup_audio_cache');
      if (await legacyAudioDir.exists()) {
        await legacyAudioDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing all cache: $e');
    }

    return initialStats;
  }

  /// Formats byte numbers into human-readable strings (e.g. 1.2 MB).
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
