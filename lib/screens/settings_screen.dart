import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/settings_service.dart';
import '../services/encryption_service.dart';
import '../services/wordup_api.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();

  static const Map<String, String> _languages = {
    'fa': 'Persian (فارسی)',
    'ar': 'Arabic (العربية)',
    'es': 'Spanish (Español)',
    'fr': 'French (Français)',
    'de': 'German (Deutsch)',
    'tr': 'Turkish (Türkçe)',
    'ru': 'Russian (Русский)',
    'it': 'Italian (Italiano)',
    'zh-CN': 'Chinese (中文)',
    'ja': 'Japanese (日本語)',
    'ko': 'Korean (한국어)',
    'hi': 'Hindi (हिन्दी)',
    'off': 'Disabled (Off)',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              Color(0xFF1E1B4B), // Deep indigo
            ],
          ),
        ),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.all(24.0),
            children: [
              Text(
                'Account',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  if (user != null) {
                    return Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.account_circle, size: 40, color: theme.primaryColor),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Logged in as', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                Text(user.email ?? 'Unknown', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await EncryptionService.clearLocalStorage();
                              await FirebaseAuth.instance.signOut();
                            },
                            child: Text('Log Out', style: TextStyle(color: Colors.redAccent)),
                          )
                        ],
                      ),
                    );
                  } else {
                    return ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen()));
                      },
                      icon: Icon(Icons.cloud_sync, color: Colors.black87),
                      label: Text('Sign In to Sync Progress', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    );
                  }
                },
              ),
              SizedBox(height: 32),
              Text(
                'Question Types',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildToggle(
                'Meaning Selection',
                'Choose the correct definition from 4 options.',
                _settingsService.enableMeaningQuestion,
                (val) {
                  setState(() => _settingsService.setMeaningQuestion(val));
                }
              ),
              _buildToggle(
                'Quote Fill-in-the-Blank',
                'Complete famous quotes with the missing word.',
                _settingsService.enableQuoteQuestion,
                (val) {
                  setState(() => _settingsService.setQuoteQuestion(val));
                }
              ),
              _buildToggle(
                'Synonym / Antonym Matching',
                'Identify related or opposite words.',
                _settingsService.enableSynonymQuestion,
                (val) {
                  setState(() => _settingsService.setSynonymQuestion(val));
                }
              ),
              _buildToggle(
                'Audio Listening Challenge',
                'Listen to the word and select the correct meaning.',
                _settingsService.enableSpellingQuestion,
                (val) {
                  setState(() => _settingsService.setSpellingQuestion(val));
                }
              ),
              _buildToggle(
                'Compare With',
                'Distinguish between two easily confused words.',
                _settingsService.enableCompareQuestion,
                (val) {
                  setState(() => _settingsService.setCompareQuestion(val));
                }
              ),
              _buildToggle(
                'Antonym Questions',
                'Identify opposites of the target word.',
                _settingsService.enableAntonymQuestion,
                (val) {
                  setState(() => _settingsService.setAntonymQuestion(val));
                }
              ),
              _buildToggle(
                'Example Questions',
                'Fill in the blank for dictionary example sentences.',
                _settingsService.enableExampleQuestion,
                (val) {
                  setState(() => _settingsService.setExampleQuestion(val));
                }
              ),
              _buildToggle(
                'Misspelling Questions',
                'Identify the correct spelling from common misspellings.',
                _settingsService.enableMisspellingQuestion,
                (val) {
                  setState(() => _settingsService.setMisspellingQuestion(val));
                }
              ),
              const SizedBox(height: 32),
              Text(
                'Text-to-Speech (TTS)',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'When both providers are enabled, voices are chosen randomly on each playback for rich natural variety.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _buildToggle(
                'Edge Neural Voices',
                'Natural, high-definition British & American neural voices (Jenny, Guy, Sonia, Ryan, etc.).',
                _settingsService.enableEdgeTts,
                (val) async {
                  final success = await _settingsService.setEdgeTts(val);
                  if (!context.mounted) return;
                  if (!success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('At least one TTS provider must remain enabled.')),
                    );
                  }
                  setState(() {});
                },
              ),
              _buildToggle(
                'Google Translate TTS',
                'Classic web synthesizer.',
                _settingsService.enableGoogleTts,
                (val) async {
                  final success = await _settingsService.setGoogleTts(val);
                  if (!context.mounted) return;
                  if (!success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('At least one TTS provider must remain enabled.')),
                    );
                  }
                  setState(() {});
                },
              ),
              const SizedBox(height: 32),
              Text(
                'Word Translation',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Show a concise native translation next to the word in the word view screen.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.translate, color: theme.primaryColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Native Language', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 2),
                            Text(
                              _languages[_settingsService.translationLanguage] ?? 'Persian (فارسی)',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _languages.containsKey(_settingsService.translationLanguage)
                              ? _settingsService.translationLanguage
                              : 'fa',
                          dropdownColor: const Color(0xFF1E1B4B),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                          items: _languages.entries.map((entry) {
                            return DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value, style: const TextStyle(color: Colors.white)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _settingsService.setTranslationLanguage(val));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Background Music Behavior',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how WordDown interacts with other media players (Spotify, YouTube Music, Podcasts) when playing pronunciations.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Duck Music (Lower Volume)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: const Text('Temporarily lowers background music volume while the word or sentence is pronounced, then restores it.', style: TextStyle(color: Colors.white70)),
                      value: 'duck',
                      groupValue: _settingsService.audioFocusMode,
                      activeColor: theme.primaryColor,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _settingsService.setAudioFocusMode(val));
                        }
                      },
                    ),
                    Divider(color: Colors.white12, height: 1),
                    RadioListTile<String>(
                      title: const Text('Pause & Resume Music', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: const Text('Temporarily pauses background music while pronunciation plays, and resumes it when done.', style: TextStyle(color: Colors.white70)),
                      value: 'pause',
                      groupValue: _settingsService.audioFocusMode,
                      activeColor: theme.primaryColor,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _settingsService.setAudioFocusMode(val));
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Cloud API & Diagnostics',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Verify connection to your live GitHub Encrypted REST API and manage offline cache.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.cloud_done, color: theme.primaryColor),
                        ),
                        title: const Text('Test GitHub Cloud API', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: const Text('Sends a test ping to your encrypted API and tests AES decryption.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(child: CircularProgressIndicator()),
                            );
                            final res = await WordupApi.testCloudApi();
                            if (!context.mounted) return;
                            Navigator.of(context).pop();

                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1E293B),
                                title: Row(
                                  children: [
                                    Icon(
                                      res['success'] == true ? Icons.check_circle : Icons.error,
                                      color: res['success'] == true ? Colors.greenAccent : Colors.redAccent,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      res['success'] == true ? 'Cloud API Working!' : 'Connection Failed',
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                                content: Text(
                                  res['success'] == true
                                      ? 'Successfully fetched and decrypted word #${res['word']} from GitHub in ${res['latencyMs']}ms!\n\nPayload Size: ${res['bytes']} bytes\nSenses: ${res['senses']}\n\nYour encrypted Cloud REST API is 100% operational.'
                                      : 'Error: ${res['error']}\nLatency: ${res['latencyMs']}ms\n\nApp will use WordUp CDN fallback automatically.',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('Test Ping'),
                        ),
                      ),
                      const Divider(color: Colors.white12, height: 24),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete_sweep, color: Colors.orangeAccent),
                        ),
                        title: const Text('Clear Word Cache', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: const Text('Clears saved offline word JSON files so they re-fetch from the Cloud API.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        trailing: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orangeAccent,
                            side: const BorderSide(color: Colors.orangeAccent),
                          ),
                          onPressed: () async {
                            final count = await WordupApi.clearLocalCache();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Cleared $count cached words from device. Words will now re-fetch fresh from Cloud API.'),
                                backgroundColor: const Color(0xFF1E293B),
                              ),
                            );
                          },
                          child: const Text('Clear Cache'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _buildToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      child: SwitchListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.white70)),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
