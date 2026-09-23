class PauseApiConfig {
  const PauseApiConfig._();

  /// Localhost works in the iOS simulator. Set PAUSE_API_BASE_URL to an HTTPS
  /// deployment URL for a release build, for example:
  /// --dart-define=PAUSE_API_BASE_URL=https://api.pause.example
  static const baseUrl = String.fromEnvironment(
    'PAUSE_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000',
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
