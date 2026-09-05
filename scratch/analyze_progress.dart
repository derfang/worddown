import 'dart:convert';
import 'dart:io';

void main() {
  final progress = jsonDecode(File('current_progress.json').readAsStringSync());
  final List words = progress['Words'];
  
  // Actually let's just find max count
  int maxCount = 0;
  for (var w in words) {
    if (w['RememberCount'] > maxCount) maxCount = w['RememberCount'];
  }
  print('Max RememberCount: $maxCount');
  
  // Find words with maxCount
  print('Words with count $maxCount: ${words.where((w) => w['RememberCount'] == maxCount).take(3).toList()}');
}
