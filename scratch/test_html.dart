import 'package:http/http.dart' as http;
import 'dart:io';

Future<void> main() async {
  final url = Uri.parse('https://www.zann.app/dictionary/jester');
  final response = await http.get(url, headers: {'accept': 'text/html'});
  
  if (response.statusCode == 200) {
    File('scratch/jester_page.html').writeAsStringSync(response.body);
    print('Saved to scratch/jester_page.html');
  }
}
