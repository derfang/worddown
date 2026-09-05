import 'dart:convert';
import 'dart:io';

void main() {
  final content = File('assets/lists/1500_Essential_Words.json').readAsStringSync();
  final data = json.decode(content) as Map<String, dynamic>;
  print('List Keys: ${data.keys}');
  
  if (data.containsKey('Steps')) {
    print('Steps: ${data['Steps']}');
  }
}
