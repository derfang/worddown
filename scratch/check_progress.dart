import 'dart:convert';
import 'dart:io';

void main() {
  final progress = jsonDecode(File('current_progress.json').readAsStringSync());
  final mire = progress['Words'].where((w) => w['WordId'] == 2297).toList();
  print('Mire progress: $mire');
  print('Is in KnownWordIds: ${progress['KnownWordIds'].contains(2297)}');
}
