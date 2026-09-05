import 'dart:io';
import 'dart:convert';

void main() {
  final content = File(r'C:\Users\PADIDAR\Desktop\task\worddown\assets\word_dictionary.json').readAsStringSync();
  final list = json.decode(content) as List;
  final word = list.firstWhere((w) => w['w'] == 'jester', orElse: () => null);
  print(word);
}
