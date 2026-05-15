import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for app configuration.
/// IP can be changed at runtime via ServerSettingsScreen without rebuilding.
class AppConfig {
  static const String _defaultHost = '192.168.137.1'; // PC hotspot default
  static const int _defaultPort = 8000;

  static const String _hostKey = 'server_host';
  static const String _portKey = 'server_port';

  // In-memory cache so we don't hit SharedPreferences on every request
  static String? _cachedHost;
  static int? _cachedPort;

  /// Call once at app startup to load saved settings into memory.
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedHost = prefs.getString(_hostKey);
    _cachedPort = prefs.getInt(_portKey);
  }

  static String get _host => _cachedHost ?? _defaultHost;
  static int get _port => _cachedPort ?? _defaultPort;

  static String get baseUrl => 'http://$_host:$_port/api';
  static String get mediaBase => 'http://$_host:$_port';

  static String get currentHost => _host;
  static int get currentPort => _port;

  /// Save new host/port and update in-memory cache immediately.
  static Future<void> setServer(String host, int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hostKey, host.trim());
    await prefs.setInt(_portKey, port);
    _cachedHost = host.trim();
    _cachedPort = port;
  }

  /// Reset to default values.
  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hostKey);
    await prefs.remove(_portKey);
    _cachedHost = null;
    _cachedPort = null;
  }

  /// Resolves any media URL to the current server.
  static String resolveMediaUrl(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('/media/')) return '$mediaBase$url';
    try {
      final uri = Uri.parse(url);
      return uri.replace(host: _host, port: _port, scheme: 'http').toString();
    } catch (_) {
      return url;
    }
  }
}
