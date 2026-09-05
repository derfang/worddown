import 'dart:convert';
import 'dart:io';

void main() {
  final content = File('assets/word_dictionary.json').readAsStringSync();
  final data = json.decode(content) as List;
  if (data.isNotEmpty) {
    print('Sample item keys: ${data[0].keys}');
    print('Sample item: ${data[0]}');
  }
}
