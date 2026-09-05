import 'dart:io';
import 'dart:convert';

void main() {
  final file = File(r'C:\Users\PADIDAR\.gemini\antigravity-ide\brain\6dc28303-8f65-4cf1-af7c-9c05c75abd7d\.system_generated\steps\3992\content.md');
  final content = file.readAsStringSync();
  
  final regex = RegExp(r'<script id="__NEXT_DATA__" type="application/json">([\s\S]*?)</script>');
  final match = regex.firstMatch(content);
  
  if (match != null) {
    final jsonStr = match.group(1)!;
    final data = json.decode(jsonStr);
    
    final outFile = File(r'C:\Users\PADIDAR\.gemini\antigravity-ide\brain\6dc28303-8f65-4cf1-af7c-9c05c75abd7d\scratch\zann_jester.json');
    outFile.writeAsStringSync(JsonEncoder.withIndent('  ').convert(data));
    print('Extracted __NEXT_DATA__ to scratch/zann_jester.json');
  } else {
    print('Could not find __NEXT_DATA__');
  }
}
