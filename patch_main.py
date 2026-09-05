import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Make sure we have the right imports
if "import 'package:firebase_auth/firebase_auth.dart';" not in code:
    code = code.replace("import 'package:firebase_core/firebase_core.dart';", "import 'package:firebase_core/firebase_core.dart';\nimport 'package:firebase_auth/firebase_auth.dart';\nimport 'package:cloud_firestore/cloud_firestore.dart';\nimport 'services/encryption_service.dart';\nimport 'screens/login_screen.dart';")

# We need to change the _initializeApp method in SplashLoadingScreen
new_init = """
  Future<void> _initializeApp() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      print('Firebase initialization failed: ');
    }

    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user == null) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => LoginScreen()),
          );
        }
      } else {
        try {
          // Fetch keys from Firestore
          final doc = await FirebaseFirestore.instance.collection('config').doc('secrets').get();
          
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            final String key = data['key'];
            final String iv = data['iv'];
            
            EncryptionService.initialize(key, iv);
            
            await DatabaseService.init();
            await ProgressService().init();
            await SettingsService().init();

            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => HomeScreen()),
              );
            }
          } else {
            throw Exception('Secret keys not found in database.');
          }
        } catch (e) {
          print('Access Denied or Error: ');
          await FirebaseAuth.instance.signOut();
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Access Denied. You are not on the approved list.')),
             );
             Navigator.of(context).pushReplacement(
               MaterialPageRoute(builder: (_) => LoginScreen()),
             );
          }
        }
      }
    });
  }
"""

# Replace the old _initializeApp
code = re.sub(r'  Future<void> _initializeApp\(\) async \{.*?\n  \}', new_init.strip('\n'), code, flags=re.DOTALL)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("main.dart patched.")
