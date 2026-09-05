import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'dart:convert';
import 'dart:io';

void main() async {
  final r = await http.get(Uri.parse('https://cdn-wordup.com/Contents/v2025-10-23/16334.gz'));
  final j = utf8.decode(GZipDecoder().decodeBytes(r.bodyBytes));
  print(j);
}
