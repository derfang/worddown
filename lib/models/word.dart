class WordTip {
  final String title;
  final String description;
  final String example;
  String? imageUrl;

  WordTip({required this.title, required this.description, required this.example, this.imageUrl});

  factory WordTip.fromString(String data) {
    final parts = data.split('|');
    return WordTip(
      title: parts.isNotEmpty ? parts[0] : '',
      description: parts.length > 1 ? parts[1] : '',
      example: parts.length > 2 ? parts[2] : '',
    );
  }
}

class WordSense {
  final String id;
  final String de;
  final String ex;
  final String ty;
  final String sy;
  final String op;
  final List<WordTip> tips;
  String? imageUrl;

  WordSense({required this.id, required this.de, required this.ex, required this.ty, this.sy = '', this.op = '', this.tips = const [], this.imageUrl});

  factory WordSense.fromJson(Map<String, dynamic> json) {
    List<WordTip> parsedTips = [];
    if (json['tp'] != null) {
      final String tpStr = json['tp'].toString();
      parsedTips = tpStr.split('\r\n').where((s) => s.trim().isNotEmpty).map((s) => WordTip.fromString(s)).toList();
    }

    return WordSense(
      id: json['id'] ?? '',
      de: json['de'] ?? '',
      ex: json['ex'] ?? '',
      ty: json['ty'] ?? '',
      sy: _cleanWords(json['sy']),
      op: _cleanWords(json['op']),
      tips: parsedTips,
    );
  }

  static String _cleanWords(dynamic value) {
    if (value == null) return '';
    final str = value.toString().trim();
    if (str.isEmpty) return '';
    const invalid = {'none', 'null', 'n/a', 'na', 'nil', 'no', '-'};
    final parts = str
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && !invalid.contains(e.toLowerCase()))
        .toList();
    return parts.join(', ');
  }
}

class WordPhrase {
  final String doText;
  final String de;
  final String ex;
  final String ty;

  WordPhrase({required this.doText, required this.de, required this.ex, required this.ty});

  factory WordPhrase.fromJson(Map<String, dynamic> json) {
    return WordPhrase(
      doText: json['do'] ?? json['txt'] ?? '',
      de: json['de'] ?? '',
      ex: json['ex'] ?? '',
      ty: json['ty'] ?? '',
    );
  }
}

class SubtitleSegment {
  final int startMs;
  final int endMs;
  final String text;

  SubtitleSegment({required this.startMs, required this.endMs, required this.text});
}

class WordVideo {
  final String title;
  final String subtitles;
  final String youtubeId;
  final int startTimeMs;
  final List<SubtitleSegment> segments;

  WordVideo({
    required this.title,
    required this.subtitles,
    required this.youtubeId,
    required this.startTimeMs,
    this.segments = const [],
  });

  factory WordVideo.fromString(String data) {
    final parts = data.split('|');
    if (parts.length >= 5) {
      final times = parts[4].split('-');
      final start = times.isNotEmpty ? int.tryParse(times[0]) ?? 0 : 0;
      
      String rawSubtitles = parts[2];
      List<SubtitleSegment> segmentList = [];

      // Subtitle chunks are separated by '■'
      // Each chunk typically has format: "<startMs>-<endMs>╣<text>"
      final chunks = rawSubtitles.split('■');
      for (var chunk in chunks) {
        final t = chunk.trim();
        if (t.isEmpty) continue;
        
        final segParts = t.split('╣');
        if (segParts.length >= 2) {
          final range = segParts[0].split('-');
          final segStart = range.isNotEmpty ? int.tryParse(range[0]) ?? 0 : 0;
          final segEnd = range.length > 1 ? int.tryParse(range[1]) ?? 0 : 0;
          final segText = segParts.sublist(1).join('╣').replaceAll(RegExp(r'\d+-\d+[╣\|-]*\s*'), '').trim();
          if (segText.isNotEmpty) {
            segmentList.add(SubtitleSegment(startMs: segStart, endMs: segEnd, text: segText));
          }
        } else {
          final cleaned = t.replaceAll(RegExp(r'\d+-\d+[╣\|-]*\s*'), '').trim();
          if (cleaned.isNotEmpty) {
            segmentList.add(SubtitleSegment(startMs: 0, endMs: 0, text: cleaned));
          }
        }
      }

      String cleanedSubtitles = rawSubtitles.replaceAll('■', ' ');
      cleanedSubtitles = cleanedSubtitles.replaceAll(RegExp(r'\d+-\d+[╣\|-]*\s*'), '');
      
      return WordVideo(
        title: parts[1],
        subtitles: cleanedSubtitles.trim(),
        youtubeId: parts[3],
        startTimeMs: start,
        segments: segmentList,
      );
    }
    return WordVideo(title: 'Video', subtitles: '', youtubeId: '', startTimeMs: 0, segments: const []);
  }
}

class WordQuote {
  final String authorName;
  final String authorRole;
  final String text;
  String? imageUrl;

  WordQuote({required this.authorName, required this.authorRole, required this.text, this.imageUrl});

  factory WordQuote.fromString(String data) {
    final parts = data.split('|');
    if (parts.length >= 5) {
      return WordQuote(
        authorName: parts[2],
        authorRole: parts[3],
        text: parts.sublist(4).join('|'),
      );
    }
    return WordQuote(authorName: 'Unknown', authorRole: '', text: data);
  }
}

class WordComparison {
  final String word;
  final String text;

  WordComparison({required this.word, required this.text});

  factory WordComparison.fromString(String data) {
    final parts = data.split('|');
    if (parts.length >= 2) {
      return WordComparison(
        word: parts[0],
        text: parts.sublist(1).join('|'),
      );
    }
    return WordComparison(word: data, text: '');
  }
}

class WordData {
  final int wordId;
  final List<WordSense> senses;
  List<WordQuote> quotes;
  final List<WordVideo> videos;
  final List<WordComparison> comparisons;
  String? imageUrl;
  
  // New properties
  final String usage;
  final List<String> wisdom;
  final List<String> facts;
  final List<String> collocations;
  final String misspellings;
  final List<WordPhrase> phrases;
  final List<WordPhrase> compounds;

  WordData({
    required this.wordId,
    required this.senses,
    required this.quotes,
    required this.videos,
    required this.comparisons,
    required this.usage,
    required this.wisdom,
    required this.facts,
    required this.collocations,
    required this.misspellings,
    required this.phrases,
    required this.compounds,
    this.imageUrl,
  });

  factory WordData.fromJson(int wordId, Map<String, dynamic> json) {
    List<WordSense> senseList = [];
    if (json['Senses'] != null) {
      senseList = (json['Senses'] as List).map((i) => WordSense.fromJson(i)).toList();
    }

    List<WordQuote> quoteList = [];
    if (json['Quotes'] != null) {
      quoteList = (json['Quotes'] as List).map((i) => WordQuote.fromString(i.toString())).toList();
    }
    
    if (json['ZannQuotes'] != null) {
      final List zannQuotes = json['ZannQuotes'] as List;
      for (var zq in zannQuotes) {
        final text = zq['Text']?.toString() ?? '';
        final imageSrc = zq['ImageSrc']?.toString() ?? '';
        if (imageSrc.isNotEmpty) {
          // Find matching quote
          for (var q in quoteList) {
            if (text.contains(q.text) || q.text.contains(text) || q.authorName == zq['Name']) {
              q.imageUrl = imageSrc;
              break;
            }
          }
        }
      }
    }

    List<WordVideo> videoList = [];
    if (json['Videos'] != null) {
      videoList = (json['Videos'] as List)
          .map((i) => WordVideo.fromString(i.toString()))
          .where((v) => v.youtubeId.isNotEmpty)
          .toList();
    }

    List<WordComparison> comparisonList = [];
    if (json['Comparisons'] != null) {
      comparisonList = (json['Comparisons'] as List).map((i) => WordComparison.fromString(i.toString())).toList();
    }

    List<String> parseStringList(String key) {
      if (json[key] != null) {
        return (json[key] as List).map((e) => e.toString()).toList();
      }
      return [];
    }
    
    List<WordPhrase> parsePhraseList(String key) {
      if (json[key] != null) {
        return (json[key] as List).map((i) => WordPhrase.fromJson(i)).toList();
      }
      return [];
    }

    // Process Zann app data if available
    final zannSenses = json['ZannSenses'] as List?;
    String? mainImageUrl = json['ZannWordImage']?.toString();
    
    if (zannSenses != null && zannSenses.isNotEmpty) {
      if (mainImageUrl == null || mainImageUrl.isEmpty) {
        mainImageUrl = zannSenses.first['ImageSrc']?.toString();
      }
      
      for (var sense in senseList) {
        final zSenseList = zannSenses.cast<Map<String,dynamic>>().where((s) => s['id'] == sense.id).toList();
        if (zSenseList.isNotEmpty) {
          final zSense = zSenseList.first;
          sense.imageUrl = zSense['ImageSrc']?.toString();
          
          final zTips = zSense['Tips'] as List?;
          if (zTips != null) {
            // Match tips by index
            for (int i = 0; i < sense.tips.length; i++) {
              if (i < zTips.length) {
                sense.tips[i].imageUrl = zTips[i]['imageUrl']?.toString();
              }
            }
          }
        }
      }
    }

    return WordData(
      wordId: wordId,
      senses: senseList,
      quotes: quoteList,
      videos: videoList,
      comparisons: comparisonList,
      usage: json['Usage']?.toString() ?? '',
      wisdom: parseStringList('Wisdom'),
      facts: parseStringList('Facts'),
      collocations: parseStringList('Collocations'),
      misspellings: json['Misspellings']?.toString() ?? '',
      phrases: parsePhraseList('Phrases'),
      compounds: parsePhraseList('Compounds'),
      imageUrl: mainImageUrl,
    );
  }
}
