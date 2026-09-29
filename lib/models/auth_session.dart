import 'app_user.dart';

class AuthSession {
  final AppUser user;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );
}