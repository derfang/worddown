import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';

void main() async {
  for (int i = 1; i <= 200; i++) {
    try {
      final r = await http.get(Uri.parse('https://cdn-wordup.com/Contents/v2025-10-23/$i.gz'));
      if (r.statusCode == 200) {
        final jsonString = utf8.decode(GZipDecoder().decodeBytes(r.bodyBytes));
        final Map<String, dynamic> data = json.decode(jsonString);
        
        bool hasPhrases = (data['Phrases'] as List?)?.isNotEmpty ?? false;
        bool hasCollocations = (data['Collocations'] as List?)?.isNotEmpty ?? false;
        
        if (hasPhrases || hasCollocations) {
          print('Found in word $i');
          if (hasPhrases) {
            print('Phrases: ${data['Phrases']}');
          }
          if (hasCollocations) {
            print('Collocations: ${data['Collocations']}');
          }
          break;
        }
      }
    } catch (e) {}
  }
}
