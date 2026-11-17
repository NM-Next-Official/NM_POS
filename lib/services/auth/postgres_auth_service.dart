import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

import '../../models/app_user.dart';
import '../../models/auth_session.dart';
import '../../models/otp_request.dart';
import '../../models/user_role.dart';
import '../db/postgres_db.dart';
import 'auth_service.dart';
import 'otp_email_sender.dart';

/// PostgreSQL-backed auth service.
///
/// ⚠️ Development-only pattern. In production the app must talk to a
///     backend API — never connect to PostgreSQL directly.
class PostgresAuthService implements AuthService {
  static const String _adminEmail = 'nmnext.official@gmail.com';
  static const String _adminDefaultPassword = 'admin123';
  static const _uuid = Uuid();

  // ───────── Session ─────────

  @override
  Future<AuthSession?> restoreSession() async {
    final pool = await PostgresDb.instance.pool;
    final rows = await pool.execute(
      Sql.named('''
        SELECT s.access_token, s.refresh_token, s.expires_at, u.*
        FROM sessions s
        JOIN users u ON u.id = s.user_id
        WHERE s.expires_at > NOW()
        ORDER BY s.created_at DESC
        LIMIT 1
      '''),
    );
    if (rows.isEmpty) return null;
    return _rowToSession(rows.first.toColumnMap());
  }

  @override
  Future<void> logout() async {
    final pool = await PostgresDb.instance.pool;
    await pool.execute(Sql.named('DELETE FROM sessions'));
  }

  // ───────── Login ─────────

  @override
  Future<AuthSession> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();

    if (normalized == _adminEmail && !await emailExists(_adminEmail)) {
      await _createAdminUser(_adminDefaultPassword);
    }

    final pool = await PostgresDb.instance.pool;
    final rows = await pool.execute(
      Sql.named('SELECT * FROM users WHERE LOWER(email) = @email LIMIT 1'),
      parameters: {'email': normalized},
    );
    if (rows.isEmpty) {
      throw const AuthException(
        'user-not-found',
        'No account found with this email',
      );
    }
    final row = rows.first.toColumnMap();
    if (!_verifyPassword(password, row['password_hash'] as String,
        row['password_salt'] as String)) {
      throw const AuthException('invalid-password', 'Incorrect password');
    }
    return _createSession(_rowToUser(row));
  }

  @override
  Future<AuthSession> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    final normalized = _normalizePhone(phone);
    final pool = await PostgresDb.instance.pool;
    final rows = await pool.execute(
      Sql.named('SELECT * FROM users WHERE phone = @phone LIMIT 1'),
      parameters: {'phone': normalized},
    );
    if (rows.isEmpty) {
      throw const AuthException(
        'user-not-found',
        'No account found with this phone number',
      );
    }
    final row = rows.first.toColumnMap();
    if (!_verifyPassword(password, row['password_hash'] as String,
        row['password_salt'] as String)) {
      throw const AuthException('invalid-password', 'Incorrect password');
    }
    return _createSession(_rowToUser(row));
  }

  // ───────── Signup ─────────

  @override
  Future<AuthSession> signup({
    required UserRole role,
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    required String password,
    String? businessName,
    String? businessAddress,
    String? verificationToken,
  }) async {
    if (email == null && phone == null) {
      throw const AuthException(
        'missing-identifier',
        'Email or phone is required',
      );
    }
    if (email != null && await emailExists(email)) {
      throw const AuthException('email-in-use', 'This email is already taken');
    }
    if (phone != null && await phoneExists(phone)) {
      throw const AuthException(
        'phone-in-use',
        'This phone number is already taken',
      );
    }

    final pool = await PostgresDb.instance.pool;

    if (verificationToken != null && email != null) {
      final normalizedEmail = email.trim().toLowerCase();
      final proof = await pool.execute(
        Sql.named('''
          SELECT id FROM otp_codes
          WHERE id = @proof AND destination = @dest
            AND purpose = 'signup' AND verified = TRUE
        '''),
        parameters: {'proof': verificationToken, 'dest': normalizedEmail},
      );
      if (proof.isEmpty) {
        throw const AuthException(
          'invalid-otp-token',
          'Email verification is required or has expired. Please verify your email.',
        );
      }
    }

    final user = AppUser(
      id: _uuid.v4(),
      email: email?.trim().toLowerCase(),
      phone: phone != null ? _normalizePhone(phone) : null,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      role: role,
      businessName: businessName?.trim(),
      businessAddress: businessAddress?.trim(),
      outletIds: role == UserRole.owner ? [_uuid.v4()] : const [],
      createdAt: DateTime.now(),
    );

    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);

    await pool.execute(
      Sql.named('''
        INSERT INTO users
          (id, email, phone, first_name, last_name,
           password_hash, password_salt, role,
           business_name, business_address, outlet_ids)
        VALUES
          (@id, @email, @phone, @firstName, @lastName,
           @hash, @salt, @role,
           @bizName, @bizAddr, @outletIds)
      '''),
      parameters: {
        'id': user.id,
        'email': user.email,
        'phone': user.phone,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'hash': hash,
        'salt': salt,
        'role': user.role.key,
        'bizName': user.businessName,
        'bizAddr': user.businessAddress,
        'outletIds': jsonEncode(user.outletIds),
      },
    );

    // Clean up verified signup OTP codes for this destination
    if (email != null) {
      await pool.execute(
        Sql.named("DELETE FROM otp_codes WHERE destination = @dest AND purpose = 'signup'"),
        parameters: {'dest': user.email},
      );
    }

    return _createSession(user);
  }

  // ───────── OTP ─────────

  @override
  Future<void> sendOtp({
    required String destination,
    required OtpChannel channel,
    required OtpPurpose purpose,
  }) async {
    if (channel != OtpChannel.email) {
      throw const AuthException(
          'email-only', 'Only email verification is supported.');
    }
    if (purpose == OtpPurpose.passwordReset) {
      final exists = channel == OtpChannel.email
          ? await emailExists(destination)
          : await phoneExists(destination);
      if (!exists) {
        throw const AuthException(
          'user-not-found',
          'No account found with this information',
        );
      }
    }
    if (purpose == OtpPurpose.signup) {
      final exists = channel == OtpChannel.email
          ? await emailExists(destination)
          : await phoneExists(destination);
      if (exists) {
        throw const AuthException(
          'email-in-use',
          'This email is already registered. Please sign in instead.',
        );
      }
    }

    final normalized = channel == OtpChannel.email
        ? destination.trim().toLowerCase()
        : _normalizePhone(destination);

    final rand = Random.secure();
    final code = (100000 + rand.nextInt(900000)).toString();
    final expiresAt = DateTime.now().add(const Duration(minutes: 10));

    final pool = await PostgresDb.instance.pool;

    await pool.execute(
      Sql.named('''
        DELETE FROM otp_codes
        WHERE destination = @dest AND purpose = @purpose
      '''),
      parameters: {'dest': normalized, 'purpose': purpose.name},
    );

    await pool.execute(
      Sql.named('''
        INSERT INTO otp_codes
          (id, destination, channel, purpose, code, expires_at)
        VALUES
          (@id, @dest, @channel, @purpose, @code, @expiresAt)
      '''),
      parameters: {
        'id': _uuid.v4(),
        'dest': normalized,
        'channel': channel.name,
        'purpose': purpose.name,
        'code': code,
        'expiresAt': expiresAt,
      },
    );

    try {
      await OtpEmailSender.send(
        email: normalized,
        code: code,
        purpose: purpose.name,
      );
    } catch (error) {
      await pool.execute(
        Sql.named('''
          DELETE FROM otp_codes
          WHERE destination = @dest AND purpose = @purpose AND code = @code
        '''),
        parameters: {'dest': normalized, 'purpose': purpose.name, 'code': code},
      );
      final details = error.toString().toLowerCase();
      if (error is TimeoutException ||
          details.contains('socketexception') ||
          details.contains('connection refused') ||
          details.contains('failed host lookup')) {
        throw const AuthException(
          'email-service-unavailable',
          'Email service is unreachable. Start the NM POS mail API, then try again.',
        );
      }
      if (error is AuthException) rethrow;
      throw const AuthException(
        'email-delivery-failed',
        'Could not send the verification email. Please try again.',
      );
    }
  }

  @override
  Future<String> verifyOtp({
    required String destination,
    required String code,
    required OtpPurpose purpose,
  }) async {
    final channel =
        destination.contains('@') ? OtpChannel.email : OtpChannel.phone;
    final normalized = channel == OtpChannel.email
        ? destination.trim().toLowerCase()
        : _normalizePhone(destination);

    final pool = await PostgresDb.instance.pool;

    final rows = await pool.execute(
      Sql.named('''
        SELECT id, code, expires_at FROM otp_codes
        WHERE destination = @dest AND purpose = @purpose AND verified = FALSE
        ORDER BY created_at DESC LIMIT 1
      '''),
      parameters: {'dest': normalized, 'purpose': purpose.name},
    );

    if (rows.isEmpty) {
      throw const AuthException('invalid-otp', 'Incorrect or expired OTP code');
    }

    final row = rows.first.toColumnMap();
    final storedCode = row['code'] as String;
    final expiresAt = (row['expires_at'] as DateTime).toLocal();

    if (DateTime.now().isAfter(expiresAt) || storedCode != code.trim()) {
      throw const AuthException('invalid-otp', 'Incorrect or expired OTP code');
    }

    final marked = await pool.execute(
      Sql.named('''
        UPDATE otp_codes SET verified = TRUE
        WHERE id = @id AND verified = FALSE AND expires_at > NOW()
      '''),
      parameters: {'id': row['id']},
    );
    if (marked.affectedRows == 0) {
      throw const AuthException('invalid-otp',
          'This code has expired or was already used. Request a new code.');
    }

    // The OTP row UUID is the one-time reset proof. It is checked and consumed
    // by resetPassword so knowing an email address alone cannot change a password.
    return row['id'].toString();
  }

  // ───────── Password Reset ─────────

  @override
  Future<void> resetPassword({
    required String destination,
    required String verificationToken,
    required String newPassword,
  }) async {
    if (newPassword.length < 6) {
      throw const AuthException(
        'weak-password',
        'Password must be at least 6 characters',
      );
    }

    final isEmail = destination.contains('@');
    final normalized = isEmail
        ? destination.trim().toLowerCase()
        : _normalizePhone(destination);

    final pool = await PostgresDb.instance.pool;

    final salt = _generateSalt();
    final hash = _hashPassword(newPassword, salt);
    await pool.runTx((tx) async {
      final proof = await tx.execute(
        Sql.named('''
          SELECT id FROM otp_codes
          WHERE id = @proof AND destination = @dest
            AND purpose = 'passwordReset' AND channel = 'email'
            AND verified = TRUE AND expires_at > NOW()
          FOR UPDATE
        '''),
        parameters: {'proof': verificationToken, 'dest': normalized},
      );
      if (proof.isEmpty) {
        throw const AuthException('invalid-reset-proof',
            'Your reset code is no longer valid. Request a new code.');
      }

      final users = await tx.execute(
        Sql.named('''
          SELECT id FROM users WHERE ${isEmail ? 'LOWER(email)' : 'phone'} = @ident LIMIT 1
        '''),
        parameters: {'ident': normalized},
      );
      if (users.isEmpty) {
        throw const AuthException('user-not-found', 'Account no longer exists');
      }
      final userId = users.first.toColumnMap()['id'];
      await tx.execute(
        Sql.named('''
          UPDATE users SET password_hash = @hash, password_salt = @salt, updated_at = NOW()
          WHERE id = @id
        '''),
        parameters: {'hash': hash, 'salt': salt, 'id': userId},
      );
      await tx.execute(Sql.named('DELETE FROM sessions WHERE user_id = @id'),
          parameters: {'id': userId});
      await tx.execute(
        Sql.named(
            "DELETE FROM otp_codes WHERE destination = @dest AND purpose = 'passwordReset'"),
        parameters: {'dest': normalized},
      );
    });
  }

  // ───────── Helpers ─────────

  @override
  Future<bool> emailExists(String email) async {
    final pool = await PostgresDb.instance.pool;
    final rows = await pool.execute(
      Sql.named('SELECT 1 FROM users WHERE LOWER(email) = @email LIMIT 1'),
      parameters: {'email': email.trim().toLowerCase()},
    );
    return rows.isNotEmpty;
  }

  @override
  Future<bool> phoneExists(String phone) async {
    final pool = await PostgresDb.instance.pool;
    final rows = await pool.execute(
      Sql.named('SELECT 1 FROM users WHERE phone = @phone LIMIT 1'),
      parameters: {'phone': _normalizePhone(phone)},
    );
    return rows.isNotEmpty;
  }

  // ───────── Internals ─────────

  Future<void> _createAdminUser(String password) async {
    final admin = AppUser(
      id: _uuid.v4(),
      email: _adminEmail,
      firstName: 'NM',
      lastName: 'Admin',
      role: UserRole.admin,
      createdAt: DateTime.now(),
    );
    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);

    final pool = await PostgresDb.instance.pool;
    await pool.execute(
      Sql.named('''
        INSERT INTO users
          (id, email, first_name, last_name,
           password_hash, password_salt, role, outlet_ids)
        VALUES
          (@id, @email, @fn, @ln, @hash, @salt, @role, '')
      '''),
      parameters: {
        'id': admin.id,
        'email': admin.email,
        'fn': admin.firstName,
        'ln': admin.lastName,
        'hash': hash,
        'salt': salt,
        'role': admin.role.key,
      },
    );
  }

  Future<AuthSession> _createSession(AppUser user) async {
    final session = AuthSession(
      user: user,
      accessToken: _uuid.v4(),
      refreshToken: _uuid.v4(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );

    final pool = await PostgresDb.instance.pool;
    await pool.execute(
      Sql.named('''
        INSERT INTO sessions
          (id, user_id, access_token, refresh_token, expires_at)
        VALUES
          (@id, @userId, @access, @refresh, @expires)
      '''),
      parameters: {
        'id': _uuid.v4(),
        'userId': user.id,
        'access': session.accessToken,
        'refresh': session.refreshToken,
        'expires': session.expiresAt,
      },
    );

    return session;
  }

  AppUser _rowToUser(Map<String, dynamic> row) {
    final outletJson = (row['outlet_ids'] as String?) ?? '';
    final outletList = outletJson.isEmpty
        ? <String>[]
        : (jsonDecode(outletJson) as List).cast<String>();

    return AppUser(
      id: row['id'].toString(),
      email: row['email'] as String?,
      phone: row['phone'] as String?,
      firstName: row['first_name'] as String,
      lastName: row['last_name'] as String,
      role: UserRole.fromString(row['role'] as String),
      businessName: row['business_name'] as String?,
      businessAddress: row['business_address'] as String?,
      outletIds: outletList,
      profileImageData: row['profile_image_data'] is Uint8List
          ? row['profile_image_data'] as Uint8List
          : null,
      createdAt: (row['created_at'] as DateTime).toLocal(),
    );
  }

  AuthSession _rowToSession(Map<String, dynamic> row) {
    return AuthSession(
      user: _rowToUser(row),
      accessToken: row['access_token'] as String,
      refreshToken: row['refresh_token'] as String,
      expiresAt: (row['expires_at'] as DateTime).toLocal(),
    );
  }

  String _generateSalt() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt::$password');
    return sha256.convert(bytes).toString();
  }

  bool _verifyPassword(String password, String expectedHash, String salt) {
    final computed = _hashPassword(password, salt);
    if (computed.length != expectedHash.length) return false;
    var diff = 0;
    for (var i = 0; i < computed.length; i++) {
      diff |= computed.codeUnitAt(i) ^ expectedHash.codeUnitAt(i);
    }
    return diff == 0;
  }

  String _normalizePhone(String phone) =>
      phone.replaceAll(RegExp(r'[^\d+]'), '');
}
