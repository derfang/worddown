import re

with open('lib/services/database_service.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Replace dictionary load
code = code.replace(
    "final String jsonString = await rootBundle.loadString('assets/word_dictionary.json');",
    "final byteData = await rootBundle.load('assets/word_dictionary.json.enc');\n    final String jsonString = EncryptionService.decryptFile(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));"
)

# Replace frequency load
code = code.replace(
    "final rankString = await rootBundle.loadString('assets/data/frequency_ranking.json');",
    "final rankByteData = await rootBundle.load('assets/data/frequency_ranking.json.enc');\n      final rankString = EncryptionService.decryptFile(rankByteData.buffer.asUint8List(rankByteData.offsetInBytes, rankByteData.lengthInBytes));"
)

if "import 'encryption_service.dart';" not in code:
    code = code.replace("import 'dart:convert';", "import 'dart:convert';\nimport 'encryption_service.dart';")

with open('lib/services/database_service.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("database_service.dart patched.")
