import 'dart:io';
import 'dart:convert';

void main() async {
  // Read known words list (which is actually ranking)
  final rankingText = await File('known_words_hypothitical.txt').readAsString();
  final innerText = rankingText.trim().replaceAll('"', '');
  final idStrings = innerText.split(',');
  final ids = idStrings.map((s) => int.tryParse(s.trim())).where((id) => id != null).cast<int>().toList();
  
  // Write to assets/data/frequency_ranking.json
  await File('assets/data/frequency_ranking.json').writeAsString(json.encode(ids));
  print('Wrote ${ids.length} words to frequency_ranking.json');
  
  // Clear known_words.json as requested
  await File('known_words.json').writeAsString('[]');
  print('Cleared known_words.json');
}
