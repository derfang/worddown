import 'dart:io';
import 'dart:convert';

void main() {
  final content = File(r'C:\Users\PADIDAR\.gemini\antigravity-ide\brain\6dc28303-8f65-4cf1-af7c-9c05c75abd7d\.system_generated\steps\3992\content.md').readAsStringSync();
  final regex = RegExp(r'<script id="__NEXT_DATA__" type="application/json">(.*?)</script>');
  final match = regex.firstMatch(content);
  if (match != null) {
    final jsonStr = match.group(1)!;
    final data = json.decode(jsonStr);
    final pageProps = data['props']['pageProps'];
    print("Keys in pageProps: ${pageProps.keys.toList()}");
    
    // check for tips
    final senses = pageProps['senses'];
    final wordRoot = pageProps['word']?['wordRoot'] ?? 'jester';
    print("Senses keys: ${senses.keys.toList()}");
    
    final jesterSense = senses[wordRoot];
    if (jesterSense != null) {
      print("Jester sense keys: ${jesterSense.keys.toList()}");
      if (jesterSense['tips'] != null) {
        print("Tips: ${json.encode(jesterSense['tips'])}");
      }
    }
  }
}
