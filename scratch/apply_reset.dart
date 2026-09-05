import 'dart:io';
import 'dart:convert';

void main() async {
  // Read known words
  final knownWordsText = await File('known_words_hypothitical.txt').readAsString();
  // It has quotes around it, e.g. `"1,2,3"`
  final innerText = knownWordsText.trim().replaceAll('"', '');
  final idStrings = innerText.split(',');
  final ids = idStrings.map((s) => int.tryParse(s.trim())).where((id) => id != null).toList();
  
  // Write to known_words.json
  await File('known_words.json').writeAsString(json.encode(ids));
  print('Wrote ${ids.length} known words to known_words.json');
  
  // Delete local_progress.json to force re-import
  final progressFile = File('local_progress.json');
  if (await progressFile.exists()) {
    await progressFile.delete();
    print('Deleted local_progress.json');
  } else {
    print('local_progress.json not found');
  }
  
  // Clear to_learn_words.json
  await File('to_learn_words.json').writeAsString('[]');
  print('Cleared to_learn_words.json');
}
