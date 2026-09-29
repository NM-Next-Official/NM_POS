import '../../models/auth_session.dart';
import '../../models/otp_request.dart';
import '../../models/user_role.dart';

class AuthException implements Exception {
  final String code;
  final String message;
  const AuthException(this.code, this.message);
  @override
  String toString() => 'AuthException($code): $message';
}

abstract class AuthService {
  // Session
  Future<AuthSession?> restoreSession();
  Future<void> logout();

  // Login
  Future<AuthSession> loginWithEmail({
    required String email,
    required String password,
  });

  Future<AuthSession> loginWithPhone({
    required String phone,
    required String password,
  });

  // Signup
  Future<AuthSession> signup({
    required UserRole role,
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    required String password,
    String? businessName,
    String? businessAddress,
  });

  // OTP
  Future<void> sendOtp({
    required String destination,
    required OtpChannel channel,
    required OtpPurpose purpose,
  });

  Future<String> verifyOtp({
    required String destination,
    required String code,
    required OtpPurpose purpose,
  });

  // Password Reset
  Future<void> resetPassword({
    required String destination,
    required String verificationToken,
    required String newPassword,
  });

  // Helpers
  Future<bool> emailExists(String email);
  Future<bool> phoneExists(String phone);
}