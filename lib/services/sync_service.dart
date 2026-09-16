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

  DocumentReference get _syncDoc {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');
    return _firestore.collection('users').doc(user.uid).collection('data').doc('syncData');
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
    } finally {
      isSyncing.value = false;
      syncStatus.value = 'Idle';
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

  Future<void> _syncDown(String uid) async {
    isSyncing.value = true;
    syncStatus.value = 'Downloading from Cloud...';
    addLog('Connecting to cloud (users/$uid/data/syncData)...');
    try {
      final doc = await _syncDoc.get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        addLog('Found cloud syncData document.');
        
        final pService = ProgressService();
        final mergeResult = pService.mergeFromCloud(
          cloudProgressMap: data['progressMap'] is Map ? Map<String, dynamic>.from(data['progressMap'] as Map) : null,
          cloudKnownWords: data['knownWords'] is List ? data['knownWords'] as List<dynamic> : null,
          cloudQueuedWords: data['queuedWords'] is List ? data['queuedWords'] as List<dynamic> : null,
          cloudPreferredImages: data['preferredImages'] is Map ? Map<String, dynamic>.from(data['preferredImages'] as Map) : null,
        );
        
        addLog('Merged cloud data: ${mergeResult.localUpdatedFromCloud} updated from cloud, '
               '${mergeResult.localKeptNewer} local kept ahead, '
               '${mergeResult.masteredCleaned} mastered cleaned.');

        if (mergeResult.hasLocalChangesToUpload) {
          addLog('Local device has newer/pending progress. Merging back to cloud...');
          await _syncUp(uid);
        } else {
          addLog('Local and Cloud are in sync.');
        }
        lastError.value = null;
      } else {
        addLog('Cloud syncData document does not exist yet for this user. Performing initial upload...');
        await _syncUp(uid);
      }

      await ProgressService().saveAllLocal();
      addLog('Sync down and local save finished successfully.');
      lastError.value = null;
    } catch (e) {
      lastError.value = e.toString();
      addLog('Error during syncDown: $e');
      print('Error syncing down from Firestore: $e');
    } finally {
      isSyncing.value = false;
      syncStatus.value = 'Idle';
      lastSynced.value = DateTime.now();
    }
  }

  Future<void> _syncUp(String uid) async {
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
      
      await _syncDoc.set({
        'progressMap': progressMapData,
        'knownWords': pService.knownWordIds.toList(),
        'queuedWords': pService.queuedWordsToLearn.toList(),
        'preferredImages': imageData,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      pService.clearAllPendingSync();
      await pService.savePendingSync();
      lastSynced.value = DateTime.now();
    } catch (e) {
      print('Error syncing up to Firestore: $e');
      rethrow;
    }
  }

  Future<void> pushProgress(int wordId, Map<String, dynamic>? data) async {
    try {
      if (data == null) {
        await _syncDoc.set({
          'progressMap': {
            wordId.toString(): FieldValue.delete()
          }
        }, SetOptions(merge: true));
      } else {
        await _syncDoc.set({
          'progressMap': {
            wordId.toString(): data
          }
        }, SetOptions(merge: true));
      }
      ProgressService().clearPendingSync([wordId]);
      await ProgressService().savePendingSync();
    } catch (e) {
      addLog('Word $wordId push failed (queued for sync): $e');
    }
  }

  Future<void> pushKnownWord(int wordId, bool isKnown) async {
    try {
      await _syncDoc.set({
        'knownWords': isKnown ? FieldValue.arrayUnion([wordId]) : FieldValue.arrayRemove([wordId])
      }, SetOptions(merge: true));
      ProgressService().clearPendingSync([wordId]);
      await ProgressService().savePendingSync();
    } catch (e) {
      addLog('Push known word $wordId failed (queued for sync): $e');
    }
  }

  Future<void> pushQueuedWord(int wordId, bool isQueued) async {
    try {
      await _syncDoc.set({
        'queuedWords': isQueued ? FieldValue.arrayUnion([wordId]) : FieldValue.arrayRemove([wordId])
      }, SetOptions(merge: true));
      ProgressService().clearPendingSync([wordId]);
      await ProgressService().savePendingSync();
    } catch (e) {
      addLog('Push queued word $wordId failed (queued for sync): $e');
    }
  }

  Future<void> pushPreferredImage(int wordId, String imageUrl) async {
    try {
      await _syncDoc.set({
        'preferredImages': {
          wordId.toString(): imageUrl
        }
      }, SetOptions(merge: true));
    } catch (e) {
      addLog('Push preferred image for $wordId failed: $e');
    }
  }
}
