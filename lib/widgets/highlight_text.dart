import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class HighlightTaskData {
  final String text;
  final String selfWord;
  final Map<String, int> learningWords;

  HighlightTaskData(this.text, this.selfWord, this.learningWords);
}

class HighlightToken {
  final String text;
  final bool isSelf;
  final int? learningId;
  final String? learningText;

  HighlightToken(this.text, {this.isSelf = false, this.learningId, this.learningText});
}

bool _isMatch(String textWord, String targetWord) {
  if (targetWord.isEmpty) return false;
  if (targetWord.contains(' ')) return false;
  if (textWord == targetWord) return true;
  
  if (targetWord.length <= 3) {
    if (textWord == targetWord + 's') return true;
    if (textWord == targetWord + 'es') return true;
    if (textWord == targetWord + 'd') return true;
    if (textWord == targetWord + 'ed') return true;
    if (targetWord.endsWith('e') && textWord == targetWord.substring(0, targetWord.length - 1) + 'ing') return true;
    if (textWord == targetWord + targetWord[targetWord.length-1] + 'ing') return true;
    return false;
  }
  
  final suffixes = const ['s', 'es', 'd', 'ed', 'ing', 'ly', 'ment', 'tion', 'er', 'est'];
  for (var suffix in suffixes) {
    if (textWord == targetWord + suffix) return true;
    if (targetWord == textWord + suffix) return true;
  }
  
  if (targetWord.endsWith('e')) {
    String root = targetWord.substring(0, targetWord.length - 1);
    if (textWord == root + 'ing') return true;
    if (textWord == root + 'ed') return true;
    if (textWord == root + 'er') return true;
    if (textWord == root + 'est') return true;
    if (textWord == root + 'ation') return true;
  }

  if (textWord.endsWith('e')) {
    String root = textWord.substring(0, textWord.length - 1);
    if (targetWord == root + 'ing') return true;
    if (targetWord == root + 'ed') return true;
  }
  
  if (targetWord.length >= 3) {
    String lastChar = targetWord[targetWord.length - 1];
    if (textWord == targetWord + lastChar + 'ing') return true;
    if (textWord == targetWord + lastChar + 'ed') return true;
    if (textWord == targetWord + lastChar + 'er') return true;
  }

  if (textWord.length >= 3) {
    String lastChar = textWord[textWord.length - 1];
    if (targetWord == textWord + lastChar + 'ing') return true;
    if (targetWord == textWord + lastChar + 'ed') return true;
  }
  
  if (targetWord.endsWith('y')) {
    String root = targetWord.substring(0, targetWord.length - 1) + 'i';
    if (textWord == root + 'es') return true;
    if (textWord == root + 'ed') return true;
    if (textWord == root + 'er') return true;
    if (textWord == root + 'est') return true;
    if (textWord == root + 'ness') return true;
    if (textWord == root + 'ly') return true;
  }

  if (textWord.endsWith('y')) {
    String root = textWord.substring(0, textWord.length - 1) + 'i';
    if (targetWord == root + 'es') return true;
    if (targetWord == root + 'ed') return true;
    if (targetWord == root + 'ness') return true;
  }
  
  return false;
}

List<String> _generateCandidates(String textWord) {
  if (textWord.isEmpty) return [];
  
  final Set<String> candidates = {textWord};
  final len = textWord.length;
  
  final suffixes = const ['s', 'es', 'd', 'ed', 'ing', 'ly', 'ment', 'tion', 'er', 'est'];
  for (var suffix in suffixes) {
    candidates.add(textWord + suffix);
  }
  
  if (textWord.endsWith('e')) {
    final root = textWord.substring(0, len - 1);
    candidates.add(root + 'ing');
    candidates.add(root + 'ed');
  }
  
  if (len >= 3) {
    final lastChar = textWord[len - 1];
    candidates.add(textWord + lastChar + 'ing');
    candidates.add(textWord + lastChar + 'ed');
  }
  
  if (textWord.endsWith('y')) {
    final root = textWord.substring(0, len - 1) + 'i';
    candidates.add(root + 'es');
    candidates.add(root + 'ed');
    candidates.add(root + 'ness');
  }
  
  if (textWord.endsWith('s')) candidates.add(textWord.substring(0, len - 1));
  if (textWord.endsWith('es')) {
    candidates.add(textWord.substring(0, len - 2));
    if (len >= 4 && textWord.endsWith('ies')) {
      candidates.add(textWord.substring(0, len - 3) + 'y');
    }
  }
  if (textWord.endsWith('d')) candidates.add(textWord.substring(0, len - 1));
  if (textWord.endsWith('ed')) {
    candidates.add(textWord.substring(0, len - 2));
    candidates.add(textWord.substring(0, len - 1));
    if (len >= 4 && textWord.endsWith('ied')) {
      candidates.add(textWord.substring(0, len - 3) + 'y');
    }
    if (len >= 4 && textWord[len-3] == textWord[len-4]) {
      candidates.add(textWord.substring(0, len - 3));
    }
  }
  if (textWord.endsWith('ing')) {
    candidates.add(textWord.substring(0, len - 3));
    candidates.add(textWord.substring(0, len - 3) + 'e');
    if (len >= 5 && textWord[len-4] == textWord[len-5]) {
      candidates.add(textWord.substring(0, len - 4));
    }
  }
  if (textWord.endsWith('ly')) {
    candidates.add(textWord.substring(0, len - 2));
    if (len >= 4 && textWord.endsWith('ily')) {
      candidates.add(textWord.substring(0, len - 3) + 'y');
    }
  }
  if (textWord.endsWith('ment')) candidates.add(textWord.substring(0, len - 4));
  if (textWord.endsWith('tion')) candidates.add(textWord.substring(0, len - 4));
  if (textWord.endsWith('ation')) candidates.add(textWord.substring(0, len - 5) + 'e');
  if (textWord.endsWith('er')) {
    candidates.add(textWord.substring(0, len - 2));
    candidates.add(textWord.substring(0, len - 2) + 'e');
    if (len >= 4 && textWord.endsWith('ier')) {
      candidates.add(textWord.substring(0, len - 3) + 'y');
    }
    if (len >= 5 && textWord[len-3] == textWord[len-4]) {
      candidates.add(textWord.substring(0, len - 3));
    }
  }
  if (textWord.endsWith('est')) {
    candidates.add(textWord.substring(0, len - 3));
    candidates.add(textWord.substring(0, len - 3) + 'e');
    if (len >= 5 && textWord.endsWith('iest')) {
      candidates.add(textWord.substring(0, len - 4) + 'y');
    }
  }
  if (textWord.endsWith('ness')) {
    candidates.add(textWord.substring(0, len - 4));
    if (len >= 6 && textWord.endsWith('iness')) {
      candidates.add(textWord.substring(0, len - 5) + 'y');
    }
  }
  
  return candidates.toList();
}

List<HighlightToken> _computeTokens(HighlightTaskData data) {
  final RegExp wordRegex = RegExp(r"[a-zA-Z']+");
  List<HighlightToken> tokens = [];
  
  data.text.splitMapJoin(
    wordRegex,
    onMatch: (Match m) {
      String word = m.group(0)!;
      String lower = word.toLowerCase();
      
      bool isSelf = _isMatch(lower, data.selfWord);
      
      if (isSelf) {
        tokens.add(HighlightToken(word, isSelf: true));
        return '';
      }
      
      int? matchedLearningId;
      String? matchedLearningText;
      
      final candidates = _generateCandidates(lower);
      for (var candidate in candidates) {
        if (data.learningWords.containsKey(candidate)) {
          if (_isMatch(lower, candidate)) {
            matchedLearningId = data.learningWords[candidate];
            matchedLearningText = candidate;
            break;
          }
        }
      }
      
      if (matchedLearningId != null) {
        tokens.add(HighlightToken(word, learningId: matchedLearningId, learningText: matchedLearningText));
      } else {
        tokens.add(HighlightToken(word));
      }
      
      return '';
    },
    onNonMatch: (String nonMatch) {
      tokens.add(HighlightToken(nonMatch));
      return '';
    },
  );
  
  return tokens;
}

class HighlightText extends StatefulWidget {
  final String text;
  final String selfWord;
  final Map<String, int> learningWords;
  final TextStyle normalStyle;
  final void Function(int id, String text)? onWordTap;
  final TextAlign textAlign;

  const HighlightText({
    Key? key,
    required this.text,
    required this.selfWord,
    required this.learningWords,
    required this.normalStyle,
    this.onWordTap,
    this.textAlign = TextAlign.start,
  }) : super(key: key);

  static List<TextSpan> buildSpans({
    required String text,
    required String selfWord,
    required Map<String, int> learningWords,
    required TextStyle normalStyle,
    void Function(int id, String text)? onWordTap,
    Color selfColor = Colors.yellowAccent,
    Color learningColor = Colors.cyanAccent,
  }) {
    final tokens = _computeTokens(HighlightTaskData(text, selfWord, learningWords));
    
    final highlightSelfStyle = normalStyle.copyWith(
      color: selfColor,
      fontWeight: FontWeight.bold,
    );
    
    final highlightLearningStyle = normalStyle.copyWith(
      color: learningColor,
      fontWeight: FontWeight.bold,
    );

    return tokens.map((t) {
      if (t.isSelf) {
        return TextSpan(text: t.text, style: highlightSelfStyle);
      } else if (t.learningId != null) {
        return TextSpan(
          text: t.text, 
          style: highlightLearningStyle,
          recognizer: onWordTap != null ? (TapGestureRecognizer()..onTap = () {
            onWordTap(t.learningId!, t.learningText!);
          }) : null,
        );
      } else {
        return TextSpan(text: t.text, style: normalStyle);
      }
    }).toList();
  }

  @override
  _HighlightTextState createState() => _HighlightTextState();
}

class _HighlightTextState extends State<HighlightText> {
  List<TextSpan>? _spans;

  @override
  void initState() {
    super.initState();
    _computeSpans();
  }

  @override
  void didUpdateWidget(HighlightText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text ||
        widget.selfWord != oldWidget.selfWord ||
        widget.learningWords != oldWidget.learningWords ||
        widget.normalStyle != oldWidget.normalStyle) {
      _computeSpans();
    }
  }

  void _computeSpans() {
    final tokens = _computeTokens(HighlightTaskData(widget.text, widget.selfWord, widget.learningWords));

    final highlightSelfStyle = widget.normalStyle.copyWith(
      color: Colors.yellowAccent,
      fontWeight: FontWeight.bold,
    );
    
    final highlightLearningStyle = widget.normalStyle.copyWith(
      color: Colors.cyanAccent,
      fontWeight: FontWeight.bold,
    );

    List<TextSpan> spans = tokens.map((t) {
      if (t.isSelf) {
        return TextSpan(text: t.text, style: highlightSelfStyle);
      } else if (t.learningId != null) {
        return TextSpan(
          text: t.text, 
          style: highlightLearningStyle,
          recognizer: widget.onWordTap != null ? (TapGestureRecognizer()..onTap = () {
            widget.onWordTap!(t.learningId!, t.learningText!);
          }) : null,
        );
      } else {
        return TextSpan(text: t.text, style: widget.normalStyle);
      }
    }).toList();

    setState(() {
      _spans = spans;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_spans == null) {
      return Text(widget.text, style: widget.normalStyle, textAlign: widget.textAlign);
    }
    return RichText(
      textAlign: widget.textAlign,
      text: TextSpan(children: _spans!),
    );
  }
}
