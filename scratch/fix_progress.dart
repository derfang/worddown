import 'dart:io';
import 'dart:convert';

void main() {
  final f = File(Platform.environment['USERPROFILE']! + '\\Documents\\local_progress.json');
  final c = f.readAsStringSync();
  final List d = json.decode(c);
  for (var v in d) {
    if ((v['RememberCount'] as int) >= 12) {
      v['RememberCount'] = 11;
    }
  }
  f.writeAsStringSync(json.encode(d));
}
