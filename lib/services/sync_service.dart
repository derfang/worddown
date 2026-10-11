import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'progress_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _syncDown(user.uid);
      }
    });
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final ValueNotifier<bool> isSyncing = ValueNotifier(false);
  final ValueNotifier<DateTime?> lastSynced = ValueNotifier(null);
  final ValueNotifier<String?> lastError = ValueNotifier(null);
  final ValueNotifier<String> syncStatus = ValueNotifier('Idle');
  final List<String> logs = [];

  void addLog(String message) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    logs.add('[$time] $message');
    if (logs.length > 60) logs.removeAt(0);
    debugPrint('SyncService: $message');
  }

  /// Waits for any in-flight sync operation to complete up to [timeout].
  /// Returns true if idle, false if timeout was reached.
  Future<bool> waitForSyncToComplete(Duration timeout) async {
    if (!isSyncing.value) return true;
    final stopwatch = Stopwatch()..start();
    while (isSyncing.value && stopwatch.elapsed < timeout) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return !isSyncing.value;
  }

  DocumentReference get _syncDoc {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('data')
        .doc('syncData');
  }

  Future<void> forceSyncDown() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      lastError.value = 'Not logged in';
      addLog('Sync aborted: User not logged in');
      return;
    }
    await _syncDown(user.uid);
  }

  Future<void> forceSyncUp() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      lastError.value = 'Not logged in';
      addLog('Upload aborted: User not logged in');
      return;
    }
    isSyncing.value = true;
    syncStatus.value = 'Uploading to Cloud...';
    try {
      await _syncUp(user.uid);
      addLog('Upload completed successfully!');
      lastError.value = null;
    } catch (e) {
      lastError.value = e.toString();
      addLog('Upload failed: $e');
      syncStatus.value = 'Error';
    } finally {
      isSyncing.value = false;
      if (lastError.value == null) {
        syncStatus.value = 'Idle';
      }
    }
  }

  Future<void> flushPendingSync() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      lastError.value = 'Not logged in';
      addLog('Flush aborted: User not logged in');
      return;
    }
    final pending = ProgressService().pendingSyncWordIds;
    if (pending.isEmpty) {
      addLog('No pending changes to flush.');
      return;
    }
    addLog('Flushing ${pending.length} pending offline items to cloud...');
    await forceSyncUp();
  }

  bool get isFullySynced =>
      lastSynced.value != null &&
      lastError.value == null &&
      ProgressService().pendingSyncWordIds.isEmpty;

  Future<void> _syncDown(String uid) async {
    if (isSyncing.value) {
      addLog('Sync already in progress, skipping duplicate trigger.');
      return;
    }
    isSyncing.value = true;
    syncStatus.value = 'Connecting to Cloud...';
    addLog('Connecting to cloud server (users/$uid/data/syncData)...');
    try {
      final doc = await _syncDoc
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));

      if (doc.metadata.isFromCache) {
        throw Exception(
          'Cloud unreachable: Read from local cache instead of cloud server.',
        );
      }

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        addLog('Successfully retrieved fresh cloud syncData.');

        final pService = ProgressService();
        final mergeResult = pService.mergeFromCloud(
          cloudProgressMap: data['progressMap'] is Map
              ? Map<String, dynamic>.from(data['progressMap'] as Map)
              : null,
          cloudKnownWords: data['knownWords'] is List
              ? data['knownWords'] as List<dynamic>
              : null,
          cloudQueuedWords: data['queuedWords'] is List
              ? data['queuedWords'] as List<dynamic>
              : null,
          cloudQueuedWordsLastUpdated: data['queuedWordsLastUpdated'] is String
              ? data['queuedWordsLastUpdated'] as String
              : null,
          cloudPreferredImages: data['preferredImages'] is Map
              ? Map<String, dynamic>.from(data['preferredImages'] as Map)
              : null,
        );

        addLog(
          'Merged cloud data: ${mergeResult.localUpdatedFromCloud} updated from cloud, '
          '${mergeResult.localKeptNewer} local kept ahead, '
          '${mergeResult.masteredCleaned} mastered cleaned.',
        );

        if (mergeResult.hasLocalChangesToUpload) {
          addLog('Local device has newer changes. Uploading to cloud server...');
          await _syncUp(uid);
        } else {
          addLog('Local device and Cloud server are fully in sync.');
          lastSynced.value = DateTime.now();
          lastError.value = null;
        }
      } else {
        addLog('Cloud syncData document does not exist yet. Performing initial upload...');
        await _syncUp(uid);
      }

      await ProgressService().saveAllLocal();
      addLog('Sync completed successfully.');
    } catch (e) {
      final String formattedError;
      if (e is TimeoutException) {
        formattedError =
            'Cloud connection timed out (15s). Check network/VPN.';
      } else if (e is FirebaseException) {
        if (e.code == 'unavailable') {
          formattedError =
              'Cloud server unavailable. Check internet or VPN.';
        } else if (e.code == 'permission-denied') {
          formattedError = 'Firebase permission denied. Please re-login.';
        } else {
          formattedError = 'Firebase error (${e.code}): ${e.message ?? e.toString()}';
        }
      } else {
        formattedError = e.toString().replaceFirst('Exception: ', '');
      }
      lastError.value = formattedError;
      addLog('Sync down failed: $formattedError');
      debugPrint('SyncService _syncDown error: $formattedError');
      syncStatus.value = 'Error';
    } finally {
      isSyncing.value = false;
      if (lastError.value == null) {
        syncStatus.value = 'Idle';
      }
    }
  }

  Future<void> _syncUp(String uid) async {
    syncStatus.value = 'Uploading to Cloud...';
    try {
      final pService = ProgressService();

      final Map<String, dynamic> progressMapData = {};
      for (var p in pService.allProgress) {
        progressMapData[p.wordId.toString()] = p.toJson();
      }

      final Map<String, dynamic> imageData = {};
      for (var entry in pService.preferredImages.entries) {
        imageData[entry.key.toString()] = entry.value;
      }

      addLog('Writing progress snapshot to cloud...');
      await _syncDoc.set({
        'progressMap': progressMapData,
        'knownWords': pService.knownWordIds.toList(),
        'queuedWords': pService.queuedWordsToLearn.toList(),
        'queuedWordsLastUpdated': pService.queuedWordsLastUpdated?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'preferredImages': imageData,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      addLog('Awaiting cloud server acknowledgment...');
      await _firestore
          .waitForPendingWrites()
          .timeout(const Duration(seconds: 15));

      addLog('Cloud server confirmed receipt of all writes.');
      pService.clearAllPendingSync();
      await pService.savePendingSync();
      lastSynced.value = DateTime.now();
      lastError.value = null;
    } catch (e) {
      final formattedError = e is TimeoutException
          ? 'Cloud upload timed out (15s). Check network/VPN.'
          : e.toString().replaceFirst('Exception: ', '');
      lastError.value = formattedError;
      addLog('Cloud upload failed: $formattedError');
      debugPrint('SyncService _syncUp error: $formattedError');
      syncStatus.value = 'Error';
      rethrow;
    }
  }

  Future<void> pushProgress(int wordId, Map<String, dynamic>? data) async {
    try {
      if (data == null) {
        await _syncDoc.set({
          'progressMap': {wordId.toString(): FieldValue.delete()},
        }, SetOptions(merge: true));
      } else {
        await _syncDoc.set({
          'progressMap': {wordId.toString(): data},
        }, SetOptions(merge: true));
      }
      await _firestore
          .waitForPendingWrites()
          .timeout(const Duration(seconds: 4));
      ProgressService().clearPendingSync([wordId]);
      await ProgressService().savePendingSync();
    } catch (e) {
      addLog('Word $wordId push buffered locally (awaiting cloud sync): $e');
    }
  }

  Future<void> pushKnownWord(int wordId, bool isKnown) async {
    try {
      await _syncDoc.set({
        'knownWords': isKnown
            ? FieldValue.arrayUnion([wordId])
            : FieldValue.arrayRemove([wordId]),
      }, SetOptions(merge: true));
      await _firestore
          .waitForPendingWrites()
          .timeout(const Duration(seconds: 4));
      ProgressService().clearPendingSync([wordId]);
      await ProgressService().savePendingSync();
    } catch (e) {
      addLog('Push known word $wordId buffered locally: $e');
    }
  }

  Future<void> pushQueuedWord(int wordId, bool isQueued) async {
    try {
      await _syncDoc.set({
        'queuedWords': isQueued
            ? FieldValue.arrayUnion([wordId])
            : FieldValue.arrayRemove([wordId]),
        'queuedWordsLastUpdated': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      await _firestore
          .waitForPendingWrites()
          .timeout(const Duration(seconds: 4));
      ProgressService().clearPendingSync([wordId]);
      await ProgressService().savePendingSync();
    } catch (e) {
      addLog('Push queued word $wordId buffered locally: $e');
    }
  }

  Future<void> pushPreferredImage(int wordId, String imageUrl) async {
    try {
      await _syncDoc.set({
        'preferredImages': {wordId.toString(): imageUrl},
      }, SetOptions(merge: true));
      await _firestore
          .waitForPendingWrites()
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      addLog('Push preferred image for $wordId buffered locally: $e');
    }
  }
}
