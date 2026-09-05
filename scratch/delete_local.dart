import 'dart:io';

void main() async {
  final files = [
    'local_progress.json',
    'local_known_words.json',
    'local_to_learn_words.json',
    'local_preferred_images.json'
  ];
  for (var f in files) {
    try {
      final file = File(f);
      if (await file.exists()) {
        await file.delete();
        print('Deleted $f');
      }
    } catch (e) {
      print('Could not delete $f: $e');
    }
  }
}
