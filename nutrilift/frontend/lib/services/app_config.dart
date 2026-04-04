/// Single source of truth for app configuration
/// Change _baseHost to match your environment:
///   - Emulator: '10.0.2.2' (Android emulator → host machine localhost)
///   - Physical device (USB/WiFi): your computer's local IP e.g. '192.168.1.100'
///   - PC browser (Chrome): '127.0.0.1'
class AppConfig {
  static const String _baseHost = '192.168.10.65';
  static const int _basePort = 8000;

  static String get baseUrl => 'http://$_baseHost:$_basePort/api';

  static String get mediaBase => 'http://$_baseHost:$_basePort';

  /// Resolves any media URL to the current server.
  /// Handles: relative paths (/media/...), absolute URLs with any IP.
  static String resolveMediaUrl(String url) {
    if (url.isEmpty) return url;
    // Already a relative path
    if (url.startsWith('/media/')) return '$mediaBase$url';
    // Absolute URL — replace whatever host:port is in it with current server
    try {
      final uri = Uri.parse(url);
      return uri.replace(host: _baseHost, port: _basePort, scheme: 'http').toString();
    } catch (_) {
      return url;
    }
  }
}
