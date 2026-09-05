import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';

void main() async {
  final url = Uri.parse('https://cdn-wordup.com/Contents/v2025-10-23/1654.gz?t=058daa1c-96cf-4b55-b016-115dd35136e1');
  final response = await http.get(url, headers: {
    'accept': '*/*',
    'origin': 'https://web.wordupapp.co',
    'referer': 'https://web.wordupapp.co/',
    'x-wordup-app-id': 'wordup_full',
    'x-wordup-source': 'web'
  });

  if (response.statusCode == 200) {
    List<int> bytes = response.bodyBytes;
    final decompressed = GZipDecoder().decodeBytes(bytes);
    final jsonString = utf8.decode(decompressed);
    final data = json.decode(jsonString);
    final videos = data['Videos'];
    print("VIDEOS:");
    for (var v in videos) {
      print(v);
    }
  } else {
    print("Failed: ${response.statusCode}");
  }
}
