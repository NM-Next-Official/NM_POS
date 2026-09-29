import 'package:postgres/postgres.dart';

import '../../config/db_config.dart';

/// Singleton connection pool to PostgreSQL.
class PostgresDb {
  PostgresDb._();
  static final PostgresDb instance = PostgresDb._();

  Pool? _pool;

  Future<Pool> get pool async {
    if (_pool != null && _pool!.isOpen) return _pool!;  // ← changed: isClosed → isOpen
    _pool = Pool.withEndpoints(
      [
        Endpoint(
          host: DbConfig.host,
          port: DbConfig.port,
          database: DbConfig.database,
          username: DbConfig.username,
          password: DbConfig.password,
        ),
      ],
      settings: PoolSettings(
        maxConnectionCount: DbConfig.maxConnections,
        connectTimeout: DbConfig.connectionTimeout,   // ← changed: connectionTimeout → connectTimeout
        maxConnectionAge: DbConfig.idleTimeout,       // ← changed: idleTimeout → maxConnectionAge
        sslMode: DbConfig.useSSL ? SslMode.require : SslMode.disable,
      ),
    );
    return _pool!;
  }

  /// Ensures a working connection at startup.
  Future<void> init() async {
    final p = await pool;
    await p.execute('SELECT 1');
  }

  Future<void> close() async {
    await _pool?.close();
    _pool = null;
  }
}