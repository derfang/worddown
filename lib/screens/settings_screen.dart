import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/settings_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();

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
                            onPressed: () => FirebaseAuth.instance.signOut(),
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
