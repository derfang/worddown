import 'dart:convert';
import 'encryption_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class DictWord {
  final int id;
  final String text;
  final String meaning;
  
  DictWord({required this.id, required this.text, required this.meaning});
  
  factory DictWord.fromJson(Map<String, dynamic> json) {
    return DictWord(
      id: json['i'] ?? 0,
      text: json['w'] ?? '',
      meaning: json['m'] ?? '',
    );
  }
}

class DatabaseService {
  static List<DictWord> _allWords = [];
  static Map<int, DictWord> _wordMap = {};
  static Map<int, int> _frequencyRanks = {};

  static final List<String> availableCurriculums = [
    '1500_Essential_Words',
    'Electrical_Engineering',
    'Electronics',
    'GRE',
    'IELTS',
    'Idioms',
    'Phrasal_Verbs',
    'TOEFL'
  ];

  static Future<void> init() async {
    // Load the 4.5MB dictionary mapping from assets into memory
    final byteData = await rootBundle.load('assets/word_dictionary.json.enc');
    final String jsonString = EncryptionService.decryptFile(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    _allWords = await compute(_parseDictWords, jsonString);
    _wordMap = {for (var w in _allWords) w.id: w};

    try {
      final rankByteData = await rootBundle.load('assets/data/frequency_ranking.json.enc');
      final rankString = EncryptionService.decryptFile(rankByteData.buffer.asUint8List(rankByteData.offsetInBytes, rankByteData.lengthInBytes));
      _frequencyRanks = await compute(_parseFrequencyRanks, rankString);
    } catch (e) {
      print('Error loading frequency ranks: $e');
    }
  }

  static List<DictWord> _parseDictWords(String jsonString) {
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => DictWord.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Map<int, int> _parseFrequencyRanks(String jsonString) {
    final List<dynamic> rankList = json.decode(jsonString);
    Map<int, int> ranks = {};
    for (int i = 0; i < rankList.length; i++) {
      ranks[rankList[i] as int] = i + 1;
    }
    return ranks;
  }

  static int? getWordRank(int id) {
    return _frequencyRanks[id];
  }

  static DictWord? getWordById(int id) {
    return _wordMap[id];
  }

  static List<DictWord> getRandomWords(int count, {int? excludeId}) {
    if (_allWords.isEmpty) return [];
    
    // We cannot easily shuffle the entire list of 50k words efficiently every time.
    // Instead we pick random indices.
    final rand = Random();
    List<DictWord> results = [];
    while(results.length < count) {
      final index = rand.nextInt(_allWords.length);
      final word = _allWords[index];
      if (word.id != excludeId && !results.contains(word)) {
        results.add(word);
      }
    }
    return results;
  }

  static List<DictWord> searchWords(String query) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    
    // Get all matches
    var matches = _allWords.where((w) => w.text.toLowerCase().startsWith(lowerQuery)).toList();
    
    // Sort by frequency rank
    matches.sort((a, b) {
      final rankA = _frequencyRanks[a.id] ?? 999999;
      final rankB = _frequencyRanks[b.id] ?? 999999;
      return rankA.compareTo(rankB);
    });

    // Return max 50 suggestions for performance
    return matches.take(50).toList();
  }

  static Future<List<DictWord>> getCurriculum(String name) async {
    try {
      final String jsonString = await rootBundle.loadString('assets/lists/$name.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      final String uwString = data['uw'] ?? '';
      
      if (uwString.isEmpty) return [];
      
      final List<int> ids = uwString
          .split(',')
          .map((e) => int.tryParse(e) ?? -1)
          .where((e) => e != -1)
          .toList();
      
      return ids
          .map((id) => _wordMap[id])
          .where((w) => w != null)
          .cast<DictWord>()
          .toList();
    } catch (e) {
      return [];
    }
  }
}
