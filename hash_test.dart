import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  final texts = [
    "Group Entertainer",
    "Social Balance",
    "Historical Context",
    "Group Entertainer|Know that a jester in a group brings laughter to friends but should avoid being offensive.|Sara, the group's jester, lightened the mood with her impersonations."
  ];

  for (final t in texts) {
    print(base64Url.encode(sha1.convert(utf8.encode(t)).bytes).replaceAll('=', ''));
    print(base64Url.encode(sha256.convert(utf8.encode(t)).bytes).replaceAll('=', ''));
    print(base64Url.encode(md5.convert(utf8.encode(t)).bytes).replaceAll('=', ''));
  }
}
