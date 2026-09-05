void main() {
  String rawSubtitles = "2000-3440-| He's relatable.■3440-5266-| Notice the height of the fall.■5266-8713-| Once a king, but now homeless and blind.■8713-12660-| It's more tragic, after all, if a king falls from a tall throne■12660-15624-| than if a jester falls off his step stool.";
  String cleanedSubtitles = rawSubtitles.replaceAll('■', ' ');
  cleanedSubtitles = cleanedSubtitles.replaceAll(RegExp(r'\d+-\d+-\|?\s*'), '');
  print(cleanedSubtitles.trim());
}
