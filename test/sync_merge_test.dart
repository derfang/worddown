import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:word_down/services/progress_service.dart';

class FakePathProviderPlatform extends PathProviderPlatform {
  final String tempDir;
  FakePathProviderPlatform(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir;

  @override
  Future<String?> getApplicationSupportPath() async => tempDir;

  @override
  Future<String?> getTemporaryPath() async => tempDir;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('worddown_sync_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('WordProgress serialization & backward compatibility', () {
    test('Correctly deserializes older JSON without LastReviewed', () {
      final oldJson = {
        'WordId': 1234,
        'RememberCount': 7,
        'PracticeDue': '2026-10-01T12:00:00.000',
      };

      final progress = WordProgress.fromJson(oldJson);
      expect(progress.wordId, 1234);
      expect(progress.rememberCount, 7);
      expect(progress.practiceDue, DateTime.parse('2026-10-01T12:00:00.000'));
      expect(progress.lastReviewed, isNull);
    });

    test('Serializes and deserializes new JSON with LastReviewed', () {
      final now = DateTime.now();
      final wp = WordProgress(
        wordId: 5678,
        rememberCount: 9,
        practiceDue: now.add(const Duration(days: 30)),
        lastReviewed: now,
      );

      final json = wp.toJson();
      expect(json.containsKey('LastReviewed'), isTrue);

      final restored = WordProgress.fromJson(json);
      expect(restored.wordId, 5678);
      expect(restored.rememberCount, 9);
      expect(restored.lastReviewed?.toIso8601String(), now.toIso8601String());
    });
  });

  group('Monotonic Safe Cloud Merge', () {
    test('Cloud higher rememberCount updates local progress', () {
      final service = ProgressService();
      
      // Seed local with step 3
      service.mergeFromCloud(
        cloudProgressMap: {
          '100': {
            'WordId': 100,
            'RememberCount': 3,
            'PracticeDue': '2026-09-15T00:00:00.000',
          }
        },
      );
      expect(service.getProgress(100)?.rememberCount, 3);

      // Now cloud has step 6
      final result = service.mergeFromCloud(
        cloudProgressMap: {
          '100': {
            'WordId': 100,
            'RememberCount': 6,
            'PracticeDue': '2026-09-28T00:00:00.000',
          }
        },
      );

      expect(result.localUpdatedFromCloud, 1);
      expect(result.localKeptNewer, 0);
      expect(service.getProgress(100)?.rememberCount, 6);
    });

    test('Local higher rememberCount is NOT regressed by older cloud data', () {
      final service = ProgressService();

      // Seed local at step 8
      service.mergeFromCloud(
        cloudProgressMap: {
          '200': {
            'WordId': 200,
            'RememberCount': 8,
            'PracticeDue': '2026-11-01T00:00:00.000',
          }
        },
      );
      expect(service.getProgress(200)?.rememberCount, 8);

      // Cloud with stale data (step 5) comes in
      final result = service.mergeFromCloud(
        cloudProgressMap: {
          '200': {
            'WordId': 200,
            'RememberCount': 5,
            'PracticeDue': '2026-09-20T00:00:00.000',
          }
        },
      );

      // Must NOT regress!
      expect(result.localUpdatedFromCloud, 0);
      expect(result.localKeptNewer, 1);
      expect(service.getProgress(200)?.rememberCount, 8);
      // Because local was ahead, it must flag that local changes need upload
      expect(result.hasLocalChangesToUpload, isTrue);
    });

    test('Mastered words are irreversible and cleaned from active ladder', () {
      final service = ProgressService();

      // Put word 300 in learning ladder
      service.mergeFromCloud(
        cloudProgressMap: {
          '300': {
            'WordId': 300,
            'RememberCount': 10,
            'PracticeDue': '2026-10-01T00:00:00.000',
          }
        },
      );
      expect(service.getProgress(300), isNotNull);

      // Now word 300 is reported known from cloud
      final result = service.mergeFromCloud(
        cloudKnownWords: [300],
      );

      expect(service.knownWordIds.contains(300), isTrue);
      expect(service.getProgress(300), isNull);
      expect(result.masteredCleaned, 1);
    });

    test('Pending sync tracking records and clears word changes', () {
      final service = ProgressService();
      expect(service.pendingSyncWordIds.isEmpty, isTrue);

      service.markPendingSync(401);
      service.markPendingSync(402);
      expect(service.pendingSyncWordIds.contains(401), isTrue);
      expect(service.pendingSyncWordIds.contains(402), isTrue);

      service.clearPendingSync([401]);
      expect(service.pendingSyncWordIds.contains(401), isFalse);
      expect(service.pendingSyncWordIds.contains(402), isTrue);

      service.clearAllPendingSync();
      expect(service.pendingSyncWordIds.isEmpty, isTrue);
    });
  });
}
