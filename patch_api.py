import re

with open('lib/services/wordup_api.dart', 'r', encoding='utf-8') as f:
    code = f.read()

replacements = {
    r"'058daa1c-96cf-4b55-b016-115dd35136e1'": "EncryptionService.decryptString('+af/iXwKxqZD7kKqV20wJYIV908a3oM1/VoQfveGmXXWRs2AZlEx3Np4BzXarCpL')",
    r"'https://cdn-wordup.com/Contents/v2025-10-23/'": "EncryptionService.decryptString('jztRb7JU7U8xmVZO/HBR834pGw+vGK/tS7vtgmIvF5Lldr15UJj7QCOpJONlEQuY')",
    r"'https://www.zann.app/dictionary/'": "EncryptionService.decryptString('4SARJC22cy8Xc8tGNtqJXytZeeNhNbFt9NzS1+kNQeQ6xCPSemgLBlTS6jrRzkT7')",
    r"'https://web.wordupapp.co'": "EncryptionService.decryptString('mo9kn0ePoTbvnQQlU46vuynFwAIG3ToauncQc16fxXo=')",
    r"'https://web.wordupapp.co/'": "EncryptionService.decryptString('mo9kn0ePoTbvnQQlU46vu907Y7vVNYhvjE7ffCxYHj0=')",
    r"'wordup_full'": "EncryptionService.decryptString('CAORgS8bg7cfoT5xXdrRGA==')",
    r"'web'": "EncryptionService.decryptString('pCnmcu9hiQZvgO+c56SoCQ==')",
    r"'https://translate.google.com/translate_tts\?ie=UTF-8&tl='": "EncryptionService.decryptString('GMYdOcvHclMrN1/WjlGrHmOwZw4A0OLl4lrHfVFiDFo5ADRT1LBAE6dONVg+MdLjfWI2EojCarPcBZiHivvBCA==')",
    r"'https://dict.youdao.com/dictvoice\?audio='": "EncryptionService.decryptString('UukRlyEUJoSVzxGCxzm3tHIBYBUKEQuxolnSdWfJKg02/Iesb2ZnDZWZQWOBtVcp')"
}

for k, v in replacements.items():
    code = re.sub(k, v, code)

# Add import if missing
if "import 'encryption_service.dart';" not in code:
    code = code.replace("import 'dart:convert';", "import 'dart:convert';\nimport 'encryption_service.dart';")

with open('lib/services/wordup_api.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("wordup_api.dart patched.")
