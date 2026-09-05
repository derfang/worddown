import 'dart:io';
import 'dart:convert';

void main() {
  final content = File('current_progress.json').readAsStringSync();
  // Decode double JSON encoding if it is a string of string
  var decoded = json.decode(content);
  if (decoded is String) {
    decoded = json.decode(decoded);
  }
  final List data = decoded as List;
  print('Length: ${data.length}');
  int knownCount = data.where((p) => p['RememberCount'] == 11).length;
  int learningCount = data.where((p) => p['RememberCount'] < 11).length;
  print('Known Count (11): $knownCount');
  print('Learning Count (<11): $learningCount');
  
  // also check RememberCount == 12
  int extraKnownCount = data.where((p) => p['RememberCount'] == 12).length;
  print('Extra Known Count (12): $extraKnownCount');
}
