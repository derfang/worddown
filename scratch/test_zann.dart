import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  String wordText = 'jester';
  Map<String, dynamic> data = {};
  
  final url = Uri.parse('https://www.zann.app/dictionary/$wordText');
  print('Fetching: $url');
  final response = await http.get(url, headers: {'accept': 'text/html'});
  print('Status: ${response.statusCode}');
  
  if (response.statusCode == 200) {
    final html = response.body;
    
    final jsonRegex = RegExp(r'<script id="__NEXT_DATA__" type="application/json"[^>]*>([\s\S]*?)</script>');
    final jsonMatch = jsonRegex.firstMatch(html);
    
    if (jsonMatch != null) {
      print('Found NEXT DATA');
      final jsonStr = jsonMatch.group(1)!;
      final nextData = json.decode(jsonStr);
      final pageProps = nextData['props']?['pageProps'];
      
      if (pageProps != null) {
        if (pageProps['quotes'] != null) {
          print('Found quotes: ${pageProps['quotes'].length}');
        }
        if (pageProps['senses'] != null) {
          final senses = pageProps['senses'];
          final wordObj = senses[wordText] ?? senses.values.firstWhere((v) => v['wordRoot'] == wordText, orElse: () => null);
          if (wordObj != null && wordObj['wordImage'] != null) {
            print('Found wordImage: ${wordObj['wordImage']}');
          } else {
            print('Word image not found. Keys in senses: ${senses.keys}');
            if (wordObj != null) {
              print('wordObj keys: ${wordObj.keys}');
            }
          }
        }
      }
    } else {
      print('NEXT DATA not found');
    }

    final tipsRegex = RegExp(r'https://word-images\.cdn-wordup\.com/tipsMobile/[a-zA-Z0-9_-]+\.webp');
    final tipMatches = tipsRegex.allMatches(html);
    print('Found tips: ${tipMatches.length}');
  }
}
