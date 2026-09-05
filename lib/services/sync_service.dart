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

  Future<void> _syncDown(String uid) async {
    isSyncing.value = true;
    try {
      // 1. Pull ProgressMap
      final progressDocs = await _firestore.collection('users').doc(uid).collection('progressMap').get();
      final cloudProgressIds = progressDocs.docs.map((d) => int.parse(d.id)).toSet();
      for (var doc in progressDocs.docs) {
        final data = doc.data();
        ProgressService().updateProgressFromCloud(int.parse(doc.id), data);
      }

      // 2. Pull KnownWords
      final knownDocs = await _firestore.collection('users').doc(uid).collection('knownWords').get();
      final cloudKnownIds = knownDocs.docs.map((d) => int.parse(d.id)).toSet();
      for (var doc in knownDocs.docs) {
        ProgressService().addKnownWordFromCloud(int.parse(doc.id));
      }

      // 3. Pull QueuedWords
      final queuedDocs = await _firestore.collection('users').doc(uid).collection('queuedWords').get();
      final cloudQueuedIds = queuedDocs.docs.map((d) => int.parse(d.id)).toSet();
      for (var doc in queuedDocs.docs) {
        ProgressService().addQueuedWordFromCloud(int.parse(doc.id));
      }

      // 4. Pull PreferredImages
      final imageDocs = await _firestore.collection('users').doc(uid).collection('preferredImages').get();
      final cloudImageIds = imageDocs.docs.map((d) => int.parse(d.id)).toSet();
      for (var doc in imageDocs.docs) {
        final data = doc.data();
        ProgressService().addPreferredImageFromCloud(int.parse(doc.id), data['imageUrl']);
      }
      
      // Merge logic: Upload anything we have locally that wasn't in the cloud
      final pService = ProgressService();
      
      final List<Future<void> Function()> uploadTasks = [];

      for (var p in pService.allProgress) {
        if (!cloudProgressIds.contains(p.wordId)) {
          uploadTasks.add(() => pushProgress(p.wordId, p.toJson()));
        }
      }
      
      for (var wordId in pService.knownWordIds) {
        if (!cloudKnownIds.contains(wordId)) {
          uploadTasks.add(() => pushKnownWord(wordId, true));
        }
      }
      
      for (var wordId in pService.queuedWordsToLearn) {
        if (!cloudQueuedIds.contains(wordId)) {
          uploadTasks.add(() => pushQueuedWord(wordId, true));
        }
      }
      
      for (var entry in pService.preferredImages.entries) {
        if (!cloudImageIds.contains(entry.key)) {
          uploadTasks.add(() => pushPreferredImage(entry.key, entry.value));
        }
      }
      
      // Process uploads in batches of 20 to avoid freezing the app and exhausting sockets
      const batchSize = 20;
      for (var i = 0; i < uploadTasks.length; i += batchSize) {
        final end = (i + batchSize < uploadTasks.length) ? i + batchSize : uploadTasks.length;
        final batch = uploadTasks.sublist(i, end).map((f) => f());
        await Future.wait(batch);
      }

      // Save all changes locally once after syncing everything down
      await ProgressService().saveAllLocal();
    } catch (e) {
      print('Error syncing down from Firestore: $e');
    } finally {
      isSyncing.value = false;
      lastSynced.value = DateTime.now();
    }
  }

  Future<void> _syncUp(String uid) async {
    try {
      final pService = ProgressService();
      
      // We use batching or just rapid async calls because Firestore handles concurrent writes well.
      // But for simplicity and to avoid hitting limits immediately, we'll just await them in batches or sequentially.
      
      for (var wordId in pService.knownWordIds) {
        await pushKnownWord(wordId, true);
      }
      
      for (var wordId in pService.queuedWordsToLearn) {
        await pushQueuedWord(wordId, true);
      }
      
      for (var p in pService.allProgress) {
        await pushProgress(p.wordId, p.toJson());
      }
      
      for (var entry in pService.preferredImages.entries) {
        await pushPreferredImage(entry.key, entry.value);
      }
      
      lastSynced.value = DateTime.now();
    } catch (e) {
      print('Error syncing up to Firestore: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> pushProgress(int wordId, Map<String, dynamic>? data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = _firestore.collection('users').doc(user.uid).collection('progressMap').doc(wordId.toString());
    if (data == null) {
      await docRef.delete();
    } else {
      await docRef.set(data);
    }
  }

  Future<void> pushKnownWord(int wordId, bool isKnown) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = _firestore.collection('users').doc(user.uid).collection('knownWords').doc(wordId.toString());
    if (isKnown) {
      await docRef.set({'addedAt': FieldValue.serverTimestamp()});
    } else {
      await docRef.delete();
    }
  }

  Future<void> pushQueuedWord(int wordId, bool isQueued) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = _firestore.collection('users').doc(user.uid).collection('queuedWords').doc(wordId.toString());
    if (isQueued) {
      await docRef.set({'addedAt': FieldValue.serverTimestamp()});
    } else {
      await docRef.delete();
    }
  }

  Future<void> pushPreferredImage(int wordId, String imageUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = _firestore.collection('users').doc(user.uid).collection('preferredImages').doc(wordId.toString());
    await docRef.set({'imageUrl': imageUrl});
  }
}
