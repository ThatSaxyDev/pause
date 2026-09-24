/// A local, deliberately conservative preview of content before it is sent to
/// the analysis service. It is not a security verdict or a URL parser.
class PauseIntakePreview {
  const PauseIntakePreview({
    required this.valueForAnalysis,
    this.urls = const [],
    this.redactedFields = const [],
  });

  const PauseIntakePreview.empty() : this(valueForAnalysis: '');

  final String valueForAnalysis;
  final List<String> urls;
  final List<String> redactedFields;

  bool get hasRedactions => redactedFields.isNotEmpty;
}

/// Extracts reviewable URL candidates and masks values that should not leave
/// the device during a manual check.
class PauseIntakeSanitizer {
  static final _urlPattern = RegExp(
    r'(?:(?:https?://|www\.)[^\s<>()]+|(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}(?:/[^\s<>()]*)?)',
    caseSensitive: false,
  );
  static final _otpPattern = RegExp(
    r'\b(?:otp|one[- ]?time(?:[ -]?pass(?:word|code))?|verification[ -]?code|security[ -]?code|pin)\s*(?:is|:|=|-)?\s*\d{4,8}\b',
    caseSensitive: false,
  );
  static final _cardPattern = RegExp(r'\b(?:\d[ -]?){13,19}\b');
  static final _accountPattern = RegExp(
    r'\b(?:account(?:\s+number)?|acct)\s*(?:is|:|=|-)?\s*\d{8,18}\b',
    caseSensitive: false,
  );

  const PauseIntakeSanitizer();

  PauseIntakePreview prepare(String value) {
    final urls = <String>[];
    for (final match in _urlPattern.allMatches(value)) {
      final candidate = _trimUrlPunctuation(match.group(0)!);
      if (candidate.isNotEmpty && !urls.contains(candidate)) {
        urls.add(candidate);
      }
    }

    var valueForAnalysis = value;
    final redactedFields = <String>[];
    valueForAnalysis = _redact(
      valueForAnalysis,
      _otpPattern,
      '[one-time code removed]',
      'one-time code',
      redactedFields,
    );
    valueForAnalysis = _redact(
      valueForAnalysis,
      _accountPattern,
      '[account number removed]',
      'account number',
      redactedFields,
    );
    valueForAnalysis = _redact(
      valueForAnalysis,
      _cardPattern,
      '[card number removed]',
      'card number',
      redactedFields,
    );

    return PauseIntakePreview(
      valueForAnalysis: valueForAnalysis,
      urls: urls,
      redactedFields: redactedFields,
    );
  }

  String _redact(
    String value,
    RegExp pattern,
    String replacement,
    String fieldName,
    List<String> redactedFields,
  ) {
    if (!pattern.hasMatch(value)) return value;
    redactedFields.add(fieldName);
    return value.replaceAll(pattern, replacement);
  }

  String _trimUrlPunctuation(String value) {
    const trailingPunctuation = ".,;:!?)]}'\"";
    var candidate = value;
    while (candidate.isNotEmpty &&
        trailingPunctuation.contains(candidate[candidate.length - 1])) {
      candidate = candidate.substring(0, candidate.length - 1);
    }
    return candidate;
  }
}
