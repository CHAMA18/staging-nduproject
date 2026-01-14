/// Small utilities for sanitizing AI-generated text before it is shown in UI
class TextSanitizer {
  /// Remove markdown asterisk markers that can appear in AI output (e.g. *bold* or **bold**)
  /// and trim surrounding whitespace.
  static String sanitizeAiText(String? input) {
    if (input == null) return '';
    return input.replaceAll('*', '').trim();
  }
}
