import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/settings_service.dart';
import '../services/encryption_service.dart';
import '../services/wordup_api.dart';
import '../services/cache_manager_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  AppCacheStats? _cacheStats;
  bool _loadingStats = false;

  @override
  void initState() {
    super.initState();
    _refreshCacheStats();
  }

  Future<void> _refreshCacheStats() async {
    if (!mounted) return;
    setState(() => _loadingStats = true);
    final stats = await CacheManagerService.getCacheStats();
    if (!mounted) return;
    setState(() {
      _cacheStats = stats;
      _loadingStats = false;
    });
  }

  Future<void> _clearWordDefinitions() async {
    final stats = await CacheManagerService.clearWordDefinitions();
    await _refreshCacheStats();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cleared ${stats.count} word definitions (${stats.formattedSize}). Words will re-fetch fresh when viewed.'),
        backgroundColor: const Color(0xFF1E293B),
      ),
    );
  }

  Future<void> _clearPronunciations() async {
    final stats = await CacheManagerService.clearPronunciations();
    await _refreshCacheStats();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cleared ${stats.count} pronunciation audio files (${stats.formattedSize}).'),
        backgroundColor: const Color(0xFF1E293B),
      ),
    );
  }

  Future<void> _clearMedia() async {
    final stats = await CacheManagerService.clearMedia();
    await _refreshCacheStats();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cleared ${stats.count} images and media illustrations (${stats.formattedSize}).'),
        backgroundColor: const Color(0xFF1E293B),
      ),
    );
  }

  Future<void> _confirmAndClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Clear All Cache?', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'This will remove all downloaded word definitions, pronunciation audio, and media illustrations.\n\nYour learning progress, streaks, and account data will NOT be affected.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final freed = await CacheManagerService.clearAllCache();
      await _refreshCacheStats();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cleared all cache (${freed.formattedTotalSize} freed across ${freed.totalCount} items).'),
          backgroundColor: const Color(0xFF1E293B),
        ),
      );
    }
  }

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
                cacheExtent: 1500,
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
                initialData: FirebaseAuth.instance.currentUser,
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  final user = snapshot.data ?? FirebaseAuth.instance.currentUser;
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
                'Storage & Cache',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Inspect and manage offline cached definitions, pronunciations, and media illustrations.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _buildCacheManagementCard(theme),
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
                'Verify connection to your live GitHub Encrypted REST API.',
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
                  child: ListTile(
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

  Widget _buildCacheManagementCard(ThemeData theme) {
    final stats = _cacheStats;
    final totalBytes = stats?.totalBytes ?? 0;
    final totalCount = stats?.totalCount ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Total footprint and refresh button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.storage_rounded, color: theme.primaryColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Cache Footprint',
                        style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _loadingStats ? 'Calculating...' : (stats?.formattedTotalSize ?? '0 B'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (!_loadingStats && stats != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '($totalCount items)',
                              style: const TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: _loadingStats
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: theme.primaryColor),
                        )
                      : const Icon(Icons.refresh, color: Colors.white70),
                  tooltip: 'Refresh Cache Metrics',
                  onPressed: _loadingStats ? null : _refreshCacheStats,
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Storage Proportion Progress Bar
            if (totalBytes > 0 && stats != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      if (stats.wordDefinitions.bytes > 0)
                        Expanded(
                          flex: (stats.wordDefinitions.bytes * 1000 / totalBytes).round().clamp(1, 1000),
                          child: Container(color: Colors.cyanAccent),
                        ),
                      if (stats.pronunciations.bytes > 0)
                        Expanded(
                          flex: (stats.pronunciations.bytes * 1000 / totalBytes).round().clamp(1, 1000),
                          child: Container(color: const Color(0xFFA855F7)), // Purple
                        ),
                      if (stats.media.bytes > 0)
                        Expanded(
                          flex: (stats.media.bytes * 1000 / totalBytes).round().clamp(1, 1000),
                          child: Container(color: Colors.amberAccent),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Legend row
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _buildLegendItem('Word Data', Colors.cyanAccent),
                  _buildLegendItem('Pronunciations', const Color(0xFFA855F7)),
                  _buildLegendItem('Illustrations & Media', Colors.amberAccent),
                ],
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Text(
                  'No offline cache files stored on device.',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            ],

            const Divider(color: Colors.white12, height: 28),

            // 1. Word Definitions Tile
            _buildCategoryRow(
              icon: Icons.article_outlined,
              iconColor: Colors.cyanAccent,
              title: 'Word Definitions (JSON)',
              subtitle: '${stats?.wordDefinitions.count ?? 0} words • ${stats?.wordDefinitions.formattedSize ?? '0 B'}',
              hasItems: (stats?.wordDefinitions.count ?? 0) > 0,
              onClear: _clearWordDefinitions,
            ),

            const Divider(color: Colors.white12, height: 16),

            // 2. Pronunciations Tile
            _buildCategoryRow(
              icon: Icons.volume_up_outlined,
              iconColor: const Color(0xFFA855F7),
              title: 'Pronunciation Audio (MP3)',
              subtitle: '${stats?.pronunciations.count ?? 0} audio files • ${stats?.pronunciations.formattedSize ?? '0 B'}',
              hasItems: (stats?.pronunciations.count ?? 0) > 0,
              onClear: _clearPronunciations,
            ),

            const Divider(color: Colors.white12, height: 16),

            // 3. Media & Illustrations Tile
            _buildCategoryRow(
              icon: Icons.image_outlined,
              iconColor: Colors.amberAccent,
              title: 'Illustrations & Media',
              subtitle: '${stats?.media.count ?? 0} media files • ${stats?.media.formattedSize ?? '0 B'}',
              hasItems: (stats?.media.count ?? 0) > 0,
              onClear: _clearMedia,
            ),

            const Divider(color: Colors.white12, height: 28),

            // Clear All Cache Action Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: totalCount > 0 ? Colors.redAccent : Colors.white24,
                  side: BorderSide(
                    color: totalCount > 0 ? Colors.redAccent.withOpacity(0.5) : Colors.white12,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(
                  Icons.delete_sweep_outlined,
                  color: totalCount > 0 ? Colors.redAccent : Colors.white24,
                  size: 20,
                ),
                label: Text(
                  'Clear All Cache',
                  style: TextStyle(
                    color: totalCount > 0 ? Colors.redAccent : Colors.white24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: totalCount > 0 ? _confirmAndClearAll : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _buildCategoryRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool hasItems,
    required VoidCallback onClear,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: hasItems ? Colors.white70 : Colors.white24,
              side: BorderSide(color: hasItems ? Colors.white24 : Colors.white10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: hasItems ? onClear : null,
            child: const Text('Clear', style: TextStyle(fontSize: 12)),
          ),
        ],
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
