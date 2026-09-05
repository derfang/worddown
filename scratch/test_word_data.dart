import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:archive/archive.dart';

void main() async {
  final url = Uri.parse('https://cdn-wordup.com/Contents/v2025-10-23/18191.gz?t=058daa1c-96cf-4b55-b016-115dd35136e1');
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
    print(jsonString.substring(0, 500)); // Print start
    
    final Map<String, dynamic> data = json.decode(jsonString);
    if (data['Quotes'] != null) {
      print('Quotes: ${data['Quotes'].take(2).toList()}');
    }
    if (data['Senses'] != null) {
      print('Senses: ${data['Senses'].take(2).toList()}');
    }
    if (data['Misspellings'] != null) {
      print('Misspellings: ${data['Misspellings']}');
    }
  } else {
    print('Failed: ${response.statusCode}');
  }
}
