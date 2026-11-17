import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/auth_session.dart';
import '../models/otp_request.dart';
import '../models/user_role.dart';
import '../services/auth/auth_service.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service);

  final AuthService _service;

  AuthStatus _status = AuthStatus.unknown;
  AuthSession? _session;
  String? _errorMessage;
  bool _busy = false;

  AuthStatus get status => _status;
  AppUser? get user => _session?.user;
  String? get errorMessage => _errorMessage;
  bool get isBusy => _busy;
  bool get isAdmin => user?.isAdmin ?? false;
  bool get isOwner => user?.isOwner ?? false;
  bool get isBasic => user?.isBasic ?? false;

  void updateUser(AppUser updatedUser) {
    final session = _session;
    if (session == null) return;
    _session = AuthSession(
      user: updatedUser,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresAt: session.expiresAt,
    );
    notifyListeners();
  }

  Future<void> bootstrap() async {
    _setBusy(true);
    try {
      final restored = await _service.restoreSession();
      if (restored != null) {
        _session = restored;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> loginWithEmail(String email, String password) =>
      _run(() => _service.loginWithEmail(email: email, password: password));

  Future<bool> loginWithPhone(String phone, String password) =>
      _run(() => _service.loginWithPhone(phone: phone, password: password));

  Future<bool> signup({
    required UserRole role,
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    required String password,
    String? businessName,
    String? businessAddress,
    String? verificationToken,
  }) =>
      _run(() => _service.signup(
            role: role,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone,
            password: password,
            businessName: businessName,
            businessAddress: businessAddress,
            verificationToken: verificationToken,
          ));

  Future<bool> emailExists(String email) => _service.emailExists(email);

  Future<bool> phoneExists(String phone) => _service.phoneExists(phone);

  Future<void> sendOtp({
    required String destination,
    required OtpChannel channel,
    required OtpPurpose purpose,
  }) async {
    _clearError();
    _setBusy(true);
    try {
      await _service.sendOtp(
        destination: destination,
        channel: channel,
        purpose: purpose,
      );
    } on AuthException catch (e) {
      _errorMessage = e.message;
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> verifyOtp({
    required String destination,
    required String code,
    required OtpPurpose purpose,
  }) async {
    _clearError();
    _setBusy(true);
    try {
      return await _service.verifyOtp(
        destination: destination,
        code: code,
        purpose: purpose,
      );
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> resetPassword({
    required String destination,
    required String verificationToken,
    required String newPassword,
  }) async {
    _clearError();
    _setBusy(true);
    try {
      await _service.resetPassword(
        destination: destination,
        verificationToken: verificationToken,
        newPassword: newPassword,
      );
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _session = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> _run(Future<AuthSession> Function() action) async {
    _clearError();
    _setBusy(true);
    try {
      _session = await action();
      _status = AuthStatus.authenticated;
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
