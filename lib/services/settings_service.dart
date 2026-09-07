import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

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

  // TTS Providers
  bool enableEdgeTts = true;
  bool enableGoogleTts = true;

  // Background Music / Audio Focus behavior: 'duck' or 'pause'
  String audioFocusMode = 'duck';

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

    enableEdgeTts = _prefs.getBool('enableEdgeTts') ?? true;
    enableGoogleTts = _prefs.getBool('enableGoogleTts') ?? true;
    // Ensure at least one is enabled if both were somehow false
    if (!enableEdgeTts && !enableGoogleTts) {
      enableEdgeTts = true;
    }

    audioFocusMode = _prefs.getString('audioFocusMode') ?? 'duck';
    updateGlobalAudioContext();
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

  Future<bool> setEdgeTts(bool val) async {
    if (!val && !enableGoogleTts) {
      return false; // Prevent disabling all providers
    }
    enableEdgeTts = val;
    await _prefs.setBool('enableEdgeTts', val);
    return true;
  }

  Future<bool> setGoogleTts(bool val) async {
    if (!val && !enableEdgeTts) {
      return false; // Prevent disabling all providers
    }
    enableGoogleTts = val;
    await _prefs.setBool('enableGoogleTts', val);
    return true;
  }

  Future<void> setAudioFocusMode(String mode) async {
    audioFocusMode = mode;
    await _prefs.setString('audioFocusMode', mode);
    updateGlobalAudioContext();
  }

  void updateGlobalAudioContext() {
    final isDuck = audioFocusMode == 'duck';
    final audioContext = AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.speech,
        usageType: AndroidUsageType.assistant,
        audioFocus: isDuck
            ? AndroidAudioFocus.gainTransientMayDuck
            : AndroidAudioFocus.gainTransient,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: isDuck
            ? {AVAudioSessionOptions.duckOthers}
            : {},
      ),
    );
    AudioPlayer.global.setAudioContext(audioContext);
  }
}
