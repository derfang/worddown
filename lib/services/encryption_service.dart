import 'package:encrypt/encrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';

class EncryptionService {
  static String? _masterKeyBase64;
  static String? _masterIvBase64;

  static bool get isInitialized => _masterKeyBase64 != null && _masterIvBase64 != null;

  static void initialize(String key, String iv) {
    _masterKeyBase64 = key;
    _masterIvBase64 = iv;
  }

  static Future<void> saveToLocalStorage(String key, String iv) async {
    initialize(key, iv);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('enc_master_key', key);
      await prefs.setString('enc_master_iv', iv);
    } catch (_) {}
  }

  static Future<bool> loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString('enc_master_key');
      final iv = prefs.getString('enc_master_iv');
      if (key != null && key.isNotEmpty && iv != null && iv.isNotEmpty) {
        initialize(key, iv);
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<void> clearLocalStorage() async {
    _masterKeyBase64 = null;
    _masterIvBase64 = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('enc_master_key');
      await prefs.remove('enc_master_iv');
    } catch (_) {}
  }

  static String decryptString(String encryptedBase64) {
    if (_masterKeyBase64 == null) return encryptedBase64;
    final key = Key.fromBase64(_masterKeyBase64!);
    final iv = IV.fromBase64(_masterIvBase64!);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
    
    return encrypter.decrypt64(encryptedBase64, iv: iv);
  }

  static String decryptFile(List<int> encryptedBytes) {
    if (_masterKeyBase64 == null) return utf8.decode(encryptedBytes);
    final key = Key.fromBase64(_masterKeyBase64!);
    final iv = IV.fromBase64(_masterIvBase64!);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
    
    final encrypted = Encrypted(Uint8List.fromList(encryptedBytes));
    return encrypter.decrypt(encrypted, iv: iv);
  }

  /// Decrypts raw AES-256-CBC encrypted bytes and returns the plain bytes.
  /// Used for encrypted image files (.webp.enc) from Hugging Face.
  static Uint8List? decryptBytes(List<int> encryptedBytes) {
    if (_masterKeyBase64 == null) return null;
    try {
      final key = Key.fromBase64(_masterKeyBase64!);
      final iv = IV.fromBase64(_masterIvBase64!);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
      final encrypted = Encrypted(Uint8List.fromList(encryptedBytes));
      final decrypted = encrypter.decryptBytes(encrypted, iv: iv);
      return Uint8List.fromList(decrypted);
    } catch (e) {
      return null;
    }
  }
}
