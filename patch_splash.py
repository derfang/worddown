import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

old_build = r'''
  @override
  Widget build\(BuildContext context\) \{
    return Scaffold\(
      backgroundColor: const Color\(0xFF0F172A\),
      body: Center\(
        child: Column\(
          mainAxisAlignment: MainAxisAlignment.center,
          children: \[
            Icon\(Icons.auto_stories, size: 80, color: const Color\(0xFF6366F1\)\),
            SizedBox\(height: 24\),
            Text\(
              'word down',
              style: TextStyle\(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2\),
            \),
            SizedBox\(height: 32\),
            CircularProgressIndicator\(color: const Color\(0xFF6366F1\)\),
          \],
        \),
      \),
    \);
  \}
'''

new_build = """
  @override
  Widget build(BuildContext context) {
    // This perfectly mimics the native Android 12 splash screen for a seamless transition
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // The logo exactly in the center, matching the Android system splash
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/icon.png',
                width: 144, // Standard Android 12 splash icon size
                height: 144,
              ),
            ),
          ),
          // Loading spinner tucked at the bottom so it fades in cleanly
          Positioned(
            bottom: 60,
            child: CircularProgressIndicator(color: const Color(0xFF6366F1)),
          ),
        ],
      ),
    );
  }
"""

# replace
import re
code = re.sub(r'  @override\n  Widget build\(BuildContext context\).*?    \);\n  \}', new_build.strip('\n'), code, flags=re.DOTALL)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("main.dart splashed.")
