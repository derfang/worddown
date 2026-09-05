import 'dart:io';

void main() {
  final content = File(r'C:\Users\PADIDAR\.gemini\antigravity-ide\brain\6dc28303-8f65-4cf1-af7c-9c05c75abd7d\.system_generated\steps\3992\content.md').readAsStringSync();
  final regex = RegExp(r'https://[^\"''<>]+\.(?:webp|jpg|jpeg|png)');
  final matches = regex.allMatches(content);
  final uniqueUrls = matches.map((m) => m.group(0)).toSet();
  for (final url in uniqueUrls) {
    print(url);
  }
}
