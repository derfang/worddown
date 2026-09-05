import 'dart:convert';
import 'dart:io';

void main() {
  final content = File('assets/lists/1500_Essential_Words.json').readAsStringSync();
  final data = json.decode(content) as Map<String, dynamic>;
  final uw = data['uw'] as String;
  print('UW string length: ${uw.length}');
  print('UW string start: ${uw.substring(0, 100)}');
}
