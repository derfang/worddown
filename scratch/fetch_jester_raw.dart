import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';

void main() async {
  final wordId = 1654; // Jester
  
  final url = Uri.parse('https://cdn-wordup.com/Contents/v2025-10-23/$wordId.gz?t=058daa1c-96cf-4b55-b016-115dd35136e1');
  final response = await http.get(url, headers: {
    'accept': '*/*',
    'origin': 'https://web.wordupapp.co',
    'referer': 'https://web.wordupapp.co/',
    'x-wordup-app-id': 'wordup_full',
    'x-wordup-source': 'web'
  });
  
  if (response.statusCode == 200) {
    final bytes = response.bodyBytes;
    final decompressed = GZipDecoder().decodeBytes(bytes);
    final jsonString = utf8.decode(decompressed);
    
    // Write to a pretty-printed JSON file
    final data = json.decode(jsonString);
    final encoder = JsonEncoder.withIndent('  ');
    final prettyString = encoder.convert(data);
    
    File('scratch/jester_raw.json').writeAsStringSync(prettyString);
    print('Saved to scratch/jester_raw.json');
  } else {
    print('Failed to fetch from CDN: ${response.statusCode}');
  }
}
