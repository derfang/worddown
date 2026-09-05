import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_down/models/word.dart';
import 'package:word_down/widgets/highlight_text.dart';

void main() {
  group('WordVideo subtitle parsing', () {
    test('parses segments with timestamps and text correctly', () {
      const rawData =
          '38785814|How to speak monkey|2000-3611╣piece by piece,■3611-4959╣and if we do not protect■4959-7476╣the critically endangered tamarin|4Vfn5CV9juI|275000-295000';

      final video = WordVideo.fromString(rawData);

      expect(video.title, 'How to speak monkey');
      expect(video.youtubeId, '4Vfn5CV9juI');
      expect(video.startTimeMs, 275000);
      expect(video.segments.length, 3);

      expect(video.segments[0].startMs, 2000);
      expect(video.segments[0].endMs, 3611);
      expect(video.segments[0].text, 'piece by piece,');

      expect(video.segments[1].startMs, 3611);
      expect(video.segments[1].endMs, 4959);
      expect(video.segments[1].text, 'and if we do not protect');

      expect(video.segments[2].startMs, 4959);
      expect(video.segments[2].endMs, 7476);
      expect(video.segments[2].text, 'the critically endangered tamarin');
    });
  });

  group('HighlightText.buildSpans', () {
    test('highlights selfWord in yellow and learningWords in cyan', () {
      final spans = HighlightText.buildSpans(
        text: 'The etiquette of green artists in Cameroon',
        selfWord: 'etiquette',
        learningWords: {'artist': 101, 'artists': 101},
        normalStyle: const TextStyle(color: Colors.white, fontSize: 16),
      );

      final selfSpan = spans.firstWhere((s) => s.text == 'etiquette');
      expect(selfSpan.style?.color, Colors.yellowAccent);
      expect(selfSpan.style?.fontWeight, FontWeight.bold);

      final learningSpan = spans.firstWhere((s) => s.text == 'artists');
      expect(learningSpan.style?.color, Colors.cyanAccent);
      expect(learningSpan.style?.fontWeight, FontWeight.bold);

      final normalSpan = spans.firstWhere((s) => s.text == 'The');
      expect(normalSpan.style?.color, Colors.white);
    });
  });
}
