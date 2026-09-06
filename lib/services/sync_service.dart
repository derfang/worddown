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

  Future<void> _syncDown(String uid) async {
    isSyncing.value = true;
    syncStatus.value = 'Downloading from Cloud...';
    addLog('Connecting to cloud (users/$uid/data/syncData)...');
    try {
      final doc = await _syncDoc.get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        addLog('Found cloud syncData document. Processing keys: ${data.keys.toList()}');
        
        if (data.containsKey('progressMap')) {
          final progressData = data['progressMap'] as Map;
          for (var entry in progressData.entries) {
            final wordData = Map<String, dynamic>.from(entry.value as Map);
            ProgressService().updateProgressFromCloud(int.parse(entry.key.toString()), wordData);
          }
          addLog('Loaded ${progressData.length} progress entries from cloud');
        }
        
        if (data.containsKey('knownWords')) {
          final knownData = data['knownWords'] as List<dynamic>;
          for (var wordId in knownData) {
            ProgressService().addKnownWordFromCloud((wordId as num).toInt());
          }
          addLog('Loaded ${knownData.length} known words from cloud');
        }

        if (data.containsKey('queuedWords')) {
          final queuedData = data['queuedWords'] as List<dynamic>;
          for (var wordId in queuedData) {
            ProgressService().addQueuedWordFromCloud((wordId as num).toInt());
          }
          addLog('Loaded ${queuedData.length} queued words from cloud');
        }

        if (data.containsKey('preferredImages')) {
          final imageData = data['preferredImages'] as Map;
          for (var entry in imageData.entries) {
            ProgressService().addPreferredImageFromCloud(int.parse(entry.key.toString()), entry.value.toString());
          }
        }
        lastError.value = null;
      } else {
        addLog('Cloud syncData document does not exist yet for this user.');
      }
      
      // Upload anything local that isn't in cloud yet
      addLog('Performing syncUp merge...');
      await _syncUp(uid);

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
      
      lastSynced.value = DateTime.now();
    } catch (e) {
      print('Error syncing up to Firestore: $e');
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
    } catch (e) {}
  }

  Future<void> pushKnownWord(int wordId, bool isKnown) async {
    try {
      await _syncDoc.set({
        'knownWords': isKnown ? FieldValue.arrayUnion([wordId]) : FieldValue.arrayRemove([wordId])
      }, SetOptions(merge: true));
    } catch (e) {}
  }

  Future<void> pushQueuedWord(int wordId, bool isQueued) async {
    try {
      await _syncDoc.set({
        'queuedWords': isQueued ? FieldValue.arrayUnion([wordId]) : FieldValue.arrayRemove([wordId])
      }, SetOptions(merge: true));
    } catch (e) {}
  }

  Future<void> pushPreferredImage(int wordId, String imageUrl) async {
    try {
      await _syncDoc.set({
        'preferredImages': {
          wordId.toString(): imageUrl
        }
      }, SetOptions(merge: true));
    } catch (e) {}
  }
}
