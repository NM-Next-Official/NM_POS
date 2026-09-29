/// PostgreSQL connection settings.
///
/// ⚠️ For development only. In production, credentials must live
///     behind a backend API — never embedded in the mobile app.
class DbConfig {
  DbConfig._();

  /// Set to `false` to keep SQLite for offline dev.
  static const bool usePostgres = true;

  /// ─────────────────────────────────────────────────────────
  /// Connection target
  /// ─────────────────────────────────────────────────────────
  ///
  /// Windows desktop  → 'localhost'
  /// Android emulator → '10.0.2.2'   (maps to host's localhost)
  /// Android device   → your PC's LAN IP, e.g. '192.168.1.42'
  /// iOS simulator    → 'localhost'
  /// iOS device       → your Mac's LAN IP
  /// ─────────────────────────────────────────────────────────
  static const String host = 'localhost';

  static const int port = 5432;
  static const String database = 'nm_pos';
  static const String username = 'nm_pos_app';
  static const String password = 'nmpos_dev_2026';

  /// Use SSL for remote connections. Local dev doesn't need it.
  static const bool useSSL = false;

  /// Connection pool tuning.
  static const int maxConnections = 5;
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration idleTimeout = Duration(minutes: 5);
}