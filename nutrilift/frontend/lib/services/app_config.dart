/// Single source of truth for app configuration
/// Change _baseHost to match your environment:
///   - Emulator: '10.0.2.2' (Android emulator → host machine localhost)
///   - Physical device (USB/WiFi): your computer's local IP e.g. '192.168.1.100'
///   - PC browser (Chrome): '127.0.0.1'
class AppConfig {
  static const String _baseHost = '10.0.2.2';
  static const int _basePort = 8000;

  static String get baseUrl => 'http://$_baseHost:$_basePort/api';
}
