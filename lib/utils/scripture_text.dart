class ScriptureText {
  ScriptureText._();

  static final RegExp _pipeAttrs = RegExp(
    r'\|(?:strong|lemma|morph|srcloc|x-morph|x-tw)="[^"]*"',
    caseSensitive: false,
  );

  static final RegExp _htmlWordTags =
      RegExp(r'</?w\b[^>]*>', caseSensitive: false);

  static final RegExp _multiSpace = RegExp(r'[ \t\u00a0]+');

  static final RegExp _spaceBeforePunct = RegExp(r'\s+([,.;:!?…])');

  static final RegExp _spaceAfterOpenQuote = RegExp(r'(["“‘(\[])\s+');

  static String clean(String raw) {
    if (raw.isEmpty) return raw;
    if (!raw.contains('|') && !raw.contains('<')) {
      return raw.trim();
    }

    var text = raw.replaceAll(_pipeAttrs, ' ');
    text = text.replaceAll(_htmlWordTags, ' ');
    text = text.replaceAll(_multiSpace, ' ');
    text = text.replaceAllMapped(_spaceBeforePunct, (m) => m[1]!);
    text = text.replaceAllMapped(_spaceAfterOpenQuote, (m) => m[1]!);
    return text.trim();
  }
}
