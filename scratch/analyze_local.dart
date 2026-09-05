import 'dart:io';
import 'dart:convert';

void main() {
  final c = File(Platform.environment['USERPROFILE']! + '\\Documents\\local_progress.json').readAsStringSync();
  final d = json.decode(c) as List;
  var m = <int,int>{};
  for (var v in d) {
    m[v['RememberCount']] = (m[v['RememberCount']] ?? 0) + 1;
  }
  print(m);
}
