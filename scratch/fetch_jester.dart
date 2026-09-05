import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';

void main() async {
  // 1. Find Word ID for "jester"
  final file = File('assets/word_dictionary.json');
  final content = file.readAsStringSync();
  final list = json.decode(content) as List;
  
  final word = list.firstWhere((w) => w['w'].toString().toLowerCase() == 'jester', orElse: () => null);
  if (word == null) {
    print('Jester not found in dictionary.');
    return;
  }
  
  final wordId = word['i'];
  print('Word ID for Jester: $wordId');
  
  // 2. Fetch WordData
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
    
    final Map<String, dynamic> data = json.decode(jsonString);
    
    print('\n--- DATA FOR JESTER ---');
    print('Quotes count: ${data['Quotes']?.length ?? 0}');
    if (data['Quotes'] != null) {
      for (var q in (data['Quotes'] as List).take(2)) {
        print(' - $q');
      }
    }
    
    print('\nSenses count: ${data['Senses']?.length ?? 0}');
    if (data['Senses'] != null) {
      for (var s in data['Senses']) {
        print(' - Type: ${s['ty']}, Def: ${s['de']}');
        print('   Example: ${s['ex']}');
        print('   Synonyms: ${s['sy']}');
      }
    }
    
    print('\nComparisons count: ${data['Comparisons']?.length ?? 0}');
    if (data['Comparisons'] != null) {
      for (var c in data['Comparisons']) {
        print(' - $c');
      }
    }
    
    print('\nPhrases count: ${data['Phrases']?.length ?? 0}');
    
    print('\nMisspellings: ${data['Misspellings']}');
  } else {
    print('Failed to fetch from CDN: ${response.statusCode}');
  }
}
