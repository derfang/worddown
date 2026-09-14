import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:word_down/services/wordup_api.dart';
import 'package:word_down/services/media_cache_service.dart';

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
    tempDir = await Directory.systemTemp.createTemp('worddown_cache_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    MediaCacheService.resetAppDocsPathForTesting();
  });

  tearDown(() async {
    MediaCacheService.resetAppDocsPathForTesting();
    try {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  test('Corrupt or sense-less cache files are detected and purged on read', () async {
    final cacheDir = Directory('${tempDir.path}/wordup_cache');
    await cacheDir.create(recursive: true);

    final corruptFile = File('${cacheDir.path}/999999.json');
    await corruptFile.writeAsString(json.encode({'ZannQuotes': ['quote1', 'quote2']}));
    expect(await corruptFile.exists(), isTrue);

    // Call fetchWordData
    final data = await WordupApi.fetchWordData('999999', wordText: 'testfake');

    // The corrupt file must have been purged from disk
    expect(await corruptFile.exists(), isFalse);
    // The failed fetch must NOT have written an empty file
    expect(data['Senses'], isNull);
  });

  test('0-byte media files are purged on read and return null', () async {
    final cacheDir = Directory('${tempDir.path}/wordup_cache/12345');
    await cacheDir.create(recursive: true);

    // Hash for 'https://cdn.example.com/test_empty.webp' is 3000766312
    const testUrl = 'https://cdn.example.com/test_empty.webp';
    final emptyFile = File('${cacheDir.path}/3000766312_test_empty.webp');
    await emptyFile.writeAsBytes([]);
    expect(await emptyFile.exists(), isTrue);
    expect(await emptyFile.length(), 0);

    final file = await MediaCacheService.getLocalFile(12345, testUrl);
    expect(file, isNull);
    expect(await emptyFile.exists(), isFalse);
  });

  test('Valid cached word data is read properly', () async {
    final cacheDir = Directory('${tempDir.path}/wordup_cache');
    await cacheDir.create(recursive: true);

    final validFile = File('${cacheDir.path}/123.json');
    await validFile.writeAsString(json.encode({
      'WordId': 123,
      'Word': 'hello',
      'Senses': [
        {'id': 's1', 'de': 'greeting', 'ex': 'hello world', 'ty': 'noun'}
      ]
    }));

    final data = await WordupApi.fetchWordData('123', wordText: 'hello');
    expect(data['Word'], 'hello');
    expect((data['Senses'] as List).length, 1);
    expect(await validFile.exists(), isTrue);
  });

  test('Cache file with only Zann data is treated as corrupt and deleted', () async {
    final cacheDir = Directory('${tempDir.path}/wordup_cache');
    await cacheDir.create(recursive: true);

    final zannOnlyFile = File('${cacheDir.path}/22896.json');
    // Exactly like the real 22896.json: has ZannQuotes and ZannSenses, but NO WordUp Senses
    await zannOnlyFile.writeAsString(json.encode({
      'ZannQuotes': [{'Text': 'hoodlum quote'}],
      'ZannSenses': [{'id': '1', 'de': 'hoodlum'}]
    }));
    expect(await zannOnlyFile.exists(), isTrue);

    // Call fetchWordData - should detect lack of Senses and delete the file
    await WordupApi.fetchWordData('22896', wordText: 'hoodlum');
    expect(await zannOnlyFile.exists(), isFalse);
  });
}
