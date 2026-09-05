import 'dart:convert';
import 'dart:io';

void main() {
  final html = File('scratch/jester_page.html').readAsStringSync();
  final jsonRegex = RegExp(r'<script id="__NEXT_DATA__" type="application/json"[^>]*>([\s\S]*?)</script>');
  final jsonMatch = jsonRegex.firstMatch(html);
  final nextData = json.decode(jsonMatch!.group(1)!);
  final pageProps = nextData['props']['pageProps'];
  
  final senses = pageProps['senses'] as List;
  print('Found ${senses.length} senses');
  for (var s in senses) {
    print('Sense ID: ${s['id']}');
    print('Sense image: ${s['ImageSrc']}');
    print('Sense tips count: ${(s['Tips'] as List?)?.length ?? 0}');
  }
}
