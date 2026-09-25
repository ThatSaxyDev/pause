class PauseApiConfig {
  const PauseApiConfig._();

  /// Production mobile builds use the deployed API. Local development can
  /// override this with PAUSE_API_BASE_URL (for example, localhost on iOS or
  /// the host gateway address on Android).
  static const baseUrl = String.fromEnvironment(
    'PAUSE_API_BASE_URL',
    defaultValue: 'https://pause-api.kiishi.space',
  );

  static Uri get baseUri {
    final uri = Uri.parse(baseUrl);
    final isLocal = uri.host == '127.0.0.1' || uri.host == 'localhost';
    if (!isLocal && uri.scheme != 'https') {
      throw const FormatException(
        'Pause requires HTTPS outside local development.',
      );
    }
    return uri.replace(path: uri.path.replaceFirst(RegExp(r'/$'), ''));
  }
}
