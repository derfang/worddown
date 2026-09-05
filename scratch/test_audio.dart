import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';

void main() async {
  final url = Uri.parse('https://cdn-wordup.com/Contents/v2025-10-23/6432.gz?t=058daa1c-96cf-4b55-b016-115dd35136e1');
  final response = await http.get(url, headers: {
    'accept': '*/*',
    'origin': 'https://web.wordupapp.co',
    'referer': 'https://web.wordupapp.co/',
    'x-wordup-app-id': 'wordup_full',
    'x-wordup-source': 'web'
  });

  List<int> bytes = response.bodyBytes;
  String jsonString;
  if (bytes.length >= 2 && bytes[0] == 0x1F && bytes[1] == 0x8B) {
    final decompressed = GZipDecoder().decodeBytes(bytes);
    jsonString = utf8.decode(decompressed);
  } else {
    jsonString = utf8.decode(bytes);
  }

  final data = json.decode(jsonString);
  print(data.keys.toList());
  if (data.containsKey('Audio')) {
    print("Audio: ${data['Audio']}");
  }
  if (data.containsKey('Pronunciations')) {
    print("Pronunciations: ${data['Pronunciations']}");
  }
  if (data.containsKey('WordText') || data.containsKey('text') || data.containsKey('Text')) {
    print("Text is present");
  }
  print(jsonString.substring(0, 500));
}
