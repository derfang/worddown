import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize and sign in anonymously if not logged in
  static Future<User?> signInAnonymously() async {
    if (_auth.currentUser != null) {
      return _auth.currentUser;
    }
    try {
      final userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      print("Failed to sign in anonymously: \$e");
      return null;
    }
  }

  static Future<void> syncWordProgress(int wordId, int rememberCount, String practiceDue) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('users').doc(user.uid).collection('progress').doc(wordId.toString());
    
    await docRef.set({
      'wordId': wordId,
      'rememberCount': rememberCount,
      'practiceDue': practiceDue,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> getWordProgress(int wordId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final docRef = _firestore.collection('users').doc(user.uid).collection('progress').doc(wordId.toString());
    final snapshot = await docRef.get();
    
    if (snapshot.exists) {
      return snapshot.data();
    }
    return null;
  }
}
