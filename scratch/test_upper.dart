import 'package:http/http.dart' as http;

Future<void> main() async {
  final url = Uri.parse('https://www.zann.app/dictionary/JESTER');
  final response = await http.get(url, headers: {'accept': 'text/html'});
  print(response.statusCode);
}
