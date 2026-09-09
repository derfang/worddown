import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_service.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  final Map<String, String> _memoryCache = {};
  SharedPreferences? _prefs;

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Translates a word from English into the specified target language (defaults to SettingsService().translationLanguage).
  /// Returns null if translation is disabled ('off'), empty, or if an error occurs.
  Future<String?> translate(String word, {String? targetLang}) async {
    final lang = targetLang ?? SettingsService().translationLanguage;
    if (lang == 'off' || lang.trim().isEmpty) return null;

    final trimmed = word.trim().toLowerCase();
    if (trimmed.isEmpty) return null;

    final cacheKey = 'tr_${lang}_$trimmed';

    // 1. Check in-memory cache
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey];
    }

    // 2. Check persistent SharedPreferences cache
    await _ensurePrefs();
    final cached = _prefs?.getString(cacheKey);
    if (cached != null && cached.trim().isNotEmpty) {
      _memoryCache[cacheKey] = cached.trim();
      return cached.trim();
    }

    // 3. Query Google Translate GTX endpoint
    try {
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=$lang&dt=t&q=${Uri.encodeComponent(trimmed)}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty && data[0] is List && data[0].isNotEmpty) {
          final firstSentence = data[0][0];
          if (firstSentence is List && firstSentence.isNotEmpty) {
            final translatedText = firstSentence[0]?.toString().trim();
            if (translatedText != null && translatedText.isNotEmpty) {
              _memoryCache[cacheKey] = translatedText;
              await _prefs?.setString(cacheKey, translatedText);
              return translatedText;
            }
          }
        }
      }
    } catch (_) {
      // Return null quietly on network timeout or failure
    }
    return null;
  }
}
