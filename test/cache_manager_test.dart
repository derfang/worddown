import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:word_down/services/cache_manager_service.dart';

class FakePathProviderPlatform extends PathProviderPlatform {
  final String tempDir;
  FakePathProviderPlatform(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir;

  @override
  Future<String?> getTemporaryPath() async => tempDir;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cache_manager_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  test('formatBytes formats properly across magnitudes', () {
    expect(CacheManagerService.formatBytes(0), '0 B');
    expect(CacheManagerService.formatBytes(512), '512 B');
    expect(CacheManagerService.formatBytes(1024), '1.0 KB');
    expect(CacheManagerService.formatBytes(1536), '1.5 KB');
    expect(CacheManagerService.formatBytes(1024 * 1024 * 5), '5.0 MB');
    expect(CacheManagerService.formatBytes(1024 * 1024 * 1024 * 2), '2.00 GB');
  });

  test('getCacheStats accurately groups definitions, audio, and media', () async {
    final cacheDir = Directory('${tempDir.path}/wordup_cache');
    await cacheDir.create(recursive: true);

    // 2 JSON definition files (100 bytes each)
    await File('${cacheDir.path}/101.json').writeAsBytes(List.filled(100, 1));
    await File('${cacheDir.path}/102.json').writeAsBytes(List.filled(100, 1));

    // 1 Audio file (500 bytes)
    await File('${cacheDir.path}/101_dict_en-us.mp3').writeAsBytes(List.filled(500, 2));

    // Media in word subdirectory (300 bytes total)
    final mediaDir = Directory('${cacheDir.path}/101');
    await mediaDir.create(recursive: true);
    await File('${mediaDir.path}/img1.jpg').writeAsBytes(List.filled(150, 3));
    await File('${mediaDir.path}/img2.webp').writeAsBytes(List.filled(150, 3));

    final stats = await CacheManagerService.getCacheStats();

    expect(stats.wordDefinitions.count, 2);
    expect(stats.wordDefinitions.bytes, 200);

    expect(stats.pronunciations.count, 1);
    expect(stats.pronunciations.bytes, 500);

    expect(stats.media.count, 2);
    expect(stats.media.bytes, 300);

    expect(stats.totalCount, 5);
    expect(stats.totalBytes, 1000);
  });

  test('Selective cache clearing works for definitions, pronunciations, and media', () async {
    final cacheDir = Directory('${tempDir.path}/wordup_cache');
    await cacheDir.create(recursive: true);

    // Setup initial files
    await File('${cacheDir.path}/101.json').writeAsBytes(List.filled(100, 1));
    await File('${cacheDir.path}/101_dict_en-us.mp3').writeAsBytes(List.filled(500, 2));
    final mediaDir = Directory('${cacheDir.path}/101');
    await mediaDir.create(recursive: true);
    await File('${mediaDir.path}/img1.jpg').writeAsBytes(List.filled(300, 3));

    // 1. Clear definitions
    final clearedDef = await CacheManagerService.clearWordDefinitions();
    expect(clearedDef.count, 1);
    expect(clearedDef.bytes, 100);
    expect(await File('${cacheDir.path}/101.json').exists(), isFalse);
    expect(await File('${cacheDir.path}/101_dict_en-us.mp3').exists(), isTrue);
    expect(await File('${mediaDir.path}/img1.jpg').exists(), isTrue);

    // 2. Clear pronunciations
    final clearedAudio = await CacheManagerService.clearPronunciations();
    expect(clearedAudio.count, 1);
    expect(clearedAudio.bytes, 500);
    expect(await File('${cacheDir.path}/101_dict_en-us.mp3').exists(), isFalse);
    expect(await File('${mediaDir.path}/img1.jpg').exists(), isTrue);

    // 3. Clear media
    final clearedMedia = await CacheManagerService.clearMedia();
    expect(clearedMedia.count, 1);
    expect(clearedMedia.bytes, 300);
    expect(await File('${mediaDir.path}/img1.jpg').exists(), isFalse);

    final statsAfter = await CacheManagerService.getCacheStats();
    expect(statsAfter.totalCount, 0);
    expect(statsAfter.totalBytes, 0);
  });

  test('clearAllCache purges all files and directories', () async {
    final cacheDir = Directory('${tempDir.path}/wordup_cache');
    await cacheDir.create(recursive: true);

    await File('${cacheDir.path}/101.json').writeAsBytes(List.filled(100, 1));
    await File('${cacheDir.path}/101_dict_en-us.mp3').writeAsBytes(List.filled(500, 2));
    final mediaDir = Directory('${cacheDir.path}/101');
    await mediaDir.create(recursive: true);
    await File('${mediaDir.path}/img1.jpg').writeAsBytes(List.filled(300, 3));

    final freed = await CacheManagerService.clearAllCache();
    expect(freed.totalCount, 3);
    expect(freed.totalBytes, 900);

    final statsAfter = await CacheManagerService.getCacheStats();
    expect(statsAfter.totalCount, 0);
    expect(statsAfter.totalBytes, 0);
  });
}
