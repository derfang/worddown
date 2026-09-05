import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';

void main() async {
  final r = await http.get(Uri.parse('https://cdn-wordup.com/Contents/v2025-10-23/16334.gz'));
  final jsonString = utf8.decode(GZipDecoder().decodeBytes(r.bodyBytes));
  final Map<String, dynamic> data = json.decode(jsonString);
  
  print('--- Top Level Keys ---');
  for (var key in data.keys) {
    var value = data[key];
    String typeInfo = '';
    if (value is List) {
      typeInfo = 'List (length: ${value.length})';
      if (value.isNotEmpty) {
        if (value.first is Map) {
          typeInfo += ' containing Maps with keys: ${(value.first as Map).keys}';
        } else {
          typeInfo += ' containing ${value.first.runtimeType}';
        }
      }
    } else if (value is Map) {
      typeInfo = 'Map with keys: ${value.keys}';
    } else {
      typeInfo = value.runtimeType.toString();
    }
    print('- $key: $typeInfo');
  }
}
