import 'dart:io';
import 'dart:convert';

void main() {
  final c = File(Platform.environment['USERPROFILE']! + '\\Documents\\local_progress.json').readAsStringSync();
  final d = json.decode(c) as List;
  var known = d.where((p) => p['RememberCount'] == 12).length;
  print('Known: $known');
  var learning = d.where((p) => p['RememberCount'] > 0 && p['RememberCount'] < 12).length;
  print('Learning: $learning');
}
