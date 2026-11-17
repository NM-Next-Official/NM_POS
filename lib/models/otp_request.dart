import 'user_role.dart';

enum OtpChannel { email, phone }

enum OtpPurpose { signup, login, passwordReset, phoneVerify }

class PendingSignupData {
  final UserRole role;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String? businessName;
  final String? businessAddress;

  const PendingSignupData({
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.businessName,
    this.businessAddress,
  });
}
