/// Central place for app-wide constants.
class AppConstants {
  AppConstants._();

  // ── API ─────────────────────────────────────────────────────────────
  /// Change to your machine's IP when testing on a physical device.
  /// Use http://10.0.2.2:8080 for Android emulator.
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  // ── Storage keys ────────────────────────────────────────────────────
  static const String tokenKey    = 'jwt_token';
  static const String userKey     = 'current_user';

  // ── Timeouts ────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
