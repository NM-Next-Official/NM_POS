import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/app_user.dart';
import '../../models/auth_session.dart';
import '../../models/otp_request.dart';
import '../../models/user_role.dart';
import 'auth_service.dart';

/// MOCK Auth Service — for development only.
///
///   • Admin: only `nmnext.official@gmail.com` (any password)
///   • Anyone else: any email/phone + password works
///   • OTP code is ALWAYS `123456`
class MockAuthService implements AuthService {
  static const String _adminEmail = 'nmnext.official@gmail.com';
  static const String _mockOtpCode = '123456';

  static const _sessionKey = 'auth_session';
  static const _otpKeyPrefix = 'otp_token_';
  static const _uuid = Uuid();

  final Map<String, AppUser> _users = {};

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ───────── Session ─────────

  @override
  Future<AuthSession?> restoreSession() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_sessionKey);
    if (raw == null) return null;
    try {
      final session = AuthSession.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (session.isExpired) {
        await logout();
        return null;
      }
      return session;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    final prefs = await _prefs;
    await prefs.remove(_sessionKey);
  }

  // ───────── Login ─────────

  @override
  Future<AuthSession> loginWithEmail({
    required String email,
    required String password,
  }) async {
    await _delay();
    final normalized = email.trim().toLowerCase();

    if (normalized == _adminEmail) {
      if (password.isEmpty) {
        throw const AuthException('invalid-password', 'Password required');
      }
      return _persistAndReturn(_buildAdmin());
    }

    final user = _users[normalized];
    if (user == null) {
      throw const AuthException(
        'user-not-found',
        'No account found with this email',
      );
    }
    return _persistAndReturn(user);
  }

  @override
  Future<AuthSession> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    await _delay();
    final normalized = _normalizePhone(phone);
    final user = _users[normalized];
    if (user == null) {
      throw const AuthException(
        'user-not-found',
        'No account found with this phone number',
      );
    }
    return _persistAndReturn(user);
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
    await _delay();

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

    if (user.email != null) _users[user.email!] = user;
    if (user.phone != null) _users[user.phone!] = user;

    return _persistAndReturn(user);
  }

  // ───────── OTP ─────────

  @override
  Future<void> sendOtp({
    required String destination,
    required OtpChannel channel,
    required OtpPurpose purpose,
  }) async {
    await _delay();
    final prefs = await _prefs;
    await prefs.setString(
      '$_otpKeyPrefix${purpose.name}_${_normalizeDestination(destination, channel)}',
      DateTime.now().toIso8601String(),
    );
    // ignore: avoid_print
    print('📧 [MOCK] OTP "$_mockOtpCode" sent to $destination ($channel)');
  }

  @override
  Future<String> verifyOtp({
    required String destination,
    required String code,
    required OtpPurpose purpose,
  }) async {
    await _delay();

    if (code.trim() != _mockOtpCode) {
      throw const AuthException('invalid-otp', 'Incorrect OTP code');
    }

    final token = _uuid.v4();
    final prefs = await _prefs;
    await prefs.setString(
      '$_otpKeyPrefix${purpose.name}_${destination}_token',
      token,
    );
    return token;
  }

  // ───────── Password Reset ─────────

  @override
  Future<void> resetPassword({
    required String destination,
    required String verificationToken,
    required String newPassword,
  }) async {
    await _delay();

    if (newPassword.length < 6) {
      throw const AuthException(
        'weak-password',
        'Password must be at least 6 characters',
      );
    }

    final prefs = await _prefs;
    final storedToken = prefs.getString(
      '$_otpKeyPrefix${OtpPurpose.passwordReset.name}_${destination}_token',
    );
    if (storedToken == null || storedToken != verificationToken) {
      throw const AuthException(
        'invalid-token',
        'Verification expired. Please request a new OTP.',
      );
    }
  }

  // ───────── Helpers ─────────

  @override
  Future<bool> emailExists(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized == _adminEmail) return true;
    return _users.containsKey(normalized);
  }

  @override
  Future<bool> phoneExists(String phone) async {
    return _users.containsKey(_normalizePhone(phone));
  }

  // ───────── Internals ─────────

  AppUser _buildAdmin() => AppUser(
        id: 'admin-0000',
        email: _adminEmail,
        firstName: 'NM',
        lastName: 'Admin',
        role: UserRole.admin,
        createdAt: DateTime.now(),
      );

  Future<AuthSession> _persistAndReturn(AppUser user) async {
    final session = AuthSession(
      user: user,
      accessToken: _uuid.v4(),
      refreshToken: _uuid.v4(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );
    final prefs = await _prefs;
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
    return session;
  }

  String _normalizePhone(String phone) =>
      phone.replaceAll(RegExp(r'[^\d+]'), '');

  String _normalizeDestination(String dest, OtpChannel channel) {
    return channel == OtpChannel.email
        ? dest.trim().toLowerCase()
        : _normalizePhone(dest);
  }

  Future<void> _delay() =>
      Future.delayed(Duration(milliseconds: 300 + Random().nextInt(400)));
}