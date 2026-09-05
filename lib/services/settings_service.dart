import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  late SharedPreferences _prefs;

  // Toggles for different question types
  bool enableMeaningQuestion = true;
  bool enableQuoteQuestion = true;
  bool enableSynonymQuestion = true;
  bool enableSpellingQuestion = true;
  bool enableCompareQuestion = true;
  bool enableAntonymQuestion = true;
  bool enableExampleQuestion = true;
  bool enableMisspellingQuestion = true;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    enableMeaningQuestion = _prefs.getBool('enableMeaningQuestion') ?? true;
    enableQuoteQuestion = _prefs.getBool('enableQuoteQuestion') ?? true;
    enableSynonymQuestion = _prefs.getBool('enableSynonymQuestion') ?? true;
    enableSpellingQuestion = _prefs.getBool('enableSpellingQuestion') ?? true;
    enableCompareQuestion = _prefs.getBool('enableCompareQuestion') ?? true;
    enableAntonymQuestion = _prefs.getBool('enableAntonymQuestion') ?? true;
    enableExampleQuestion = _prefs.getBool('enableExampleQuestion') ?? true;
    enableMisspellingQuestion = _prefs.getBool('enableMisspellingQuestion') ?? true;
  }

  Future<void> setMeaningQuestion(bool val) async {
    enableMeaningQuestion = val;
    await _prefs.setBool('enableMeaningQuestion', val);
  }

  Future<void> setQuoteQuestion(bool val) async {
    enableQuoteQuestion = val;
    await _prefs.setBool('enableQuoteQuestion', val);
  }

  Future<void> setSynonymQuestion(bool val) async {
    enableSynonymQuestion = val;
    await _prefs.setBool('enableSynonymQuestion', val);
  }

  Future<void> setSpellingQuestion(bool val) async {
    enableSpellingQuestion = val;
    await _prefs.setBool('enableSpellingQuestion', val);
  }

  Future<void> setCompareQuestion(bool val) async {
    enableCompareQuestion = val;
    await _prefs.setBool('enableCompareQuestion', val);
  }

  Future<void> setAntonymQuestion(bool val) async {
    enableAntonymQuestion = val;
    await _prefs.setBool('enableAntonymQuestion', val);
  }

  Future<void> setExampleQuestion(bool val) async {
    enableExampleQuestion = val;
    await _prefs.setBool('enableExampleQuestion', val);
  }

  Future<void> setMisspellingQuestion(bool val) async {
    enableMisspellingQuestion = val;
    await _prefs.setBool('enableMisspellingQuestion', val);
  }
}
