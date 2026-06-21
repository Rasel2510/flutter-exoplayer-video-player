/// Pure helpers for naming and filtering media tracks (audio / subtitle).
///
/// Kept free of Flutter and media_kit imports so the logic is trivially
/// unit-testable and shared between the provider and the track sheets.
abstract final class TrackLabels {
  /// media_kit injects synthetic `'auto'` / `'no'` placeholder ids alongside
  /// the real demuxed tracks. These are not selectable tracks the file
  /// actually contains, so the UI filters them out.
  static bool isPlaceholderId(String id) => id == 'auto' || id == 'no';

  /// ISO-639 (and a few common 3-letter) language codes → display names.
  static const Map<String, String> _languageNames = {
    'en': 'English', 'eng': 'English',
    'es': 'Spanish', 'spa': 'Spanish',
    'fr': 'French', 'fre': 'French', 'fra': 'French',
    'de': 'German', 'ger': 'German', 'deu': 'German',
    'it': 'Italian', 'ita': 'Italian',
    'pt': 'Portuguese', 'por': 'Portuguese',
    'ru': 'Russian', 'rus': 'Russian',
    'ja': 'Japanese', 'jpn': 'Japanese',
    'ko': 'Korean', 'kor': 'Korean',
    'zh': 'Chinese', 'chi': 'Chinese', 'zho': 'Chinese',
    'ar': 'Arabic', 'ara': 'Arabic',
    'hi': 'Hindi', 'hin': 'Hindi',
    'bn': 'Bengali', 'ben': 'Bengali',
    'ur': 'Urdu', 'urd': 'Urdu',
    'tr': 'Turkish', 'tur': 'Turkish',
    'vi': 'Vietnamese', 'vie': 'Vietnamese',
    'th': 'Thai', 'tha': 'Thai',
    'id': 'Indonesian', 'ind': 'Indonesian',
    'nl': 'Dutch', 'dut': 'Dutch', 'nld': 'Dutch',
    'pl': 'Polish', 'pol': 'Polish',
    'uk': 'Ukrainian', 'ukr': 'Ukrainian',
  };

  /// Readable language name for a track's language code, or null when the code
  /// is missing / undefined. Unknown codes fall back to their upper-cased form.
  static String? languageName(String? code) {
    if (code == null) return null;
    final normalized = code.toLowerCase().trim();
    if (normalized.isEmpty || normalized == 'und') return null;
    return _languageNames[normalized] ?? code.toUpperCase();
  }

  /// Label for an audio/subtitle row:
  ///  • an explicit embedded title always wins (the real "name" of the track);
  ///  • otherwise a lone track just reads "Default" — it's the file's only/
  ///    default track, so don't guess a language for it;
  ///  • with several tracks, fall back to the language name, then a number.
  static String trackLabel({
    String? title,
    String? language,
    required int index,
    required int total,
  }) {
    final t = title?.trim();
    if (t != null && t.isNotEmpty) return t;
    if (total <= 1) return 'Default';
    final lang = languageName(language);
    if (lang != null) return lang;
    return 'Track ${index + 1}';
  }
}
