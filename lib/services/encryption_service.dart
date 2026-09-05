import 'package:encrypt/encrypt.dart';
import 'dart:convert';
import 'dart:typed_data';

class EncryptionService {
  static String? _masterKeyBase64;
  static String? _masterIvBase64;

  static void initialize(String key, String iv) {
    _masterKeyBase64 = key;
    _masterIvBase64 = iv;
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
}
