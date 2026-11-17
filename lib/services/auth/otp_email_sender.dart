import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/db_config.dart';

/// Sends OTP mail through the NM POS mail server (Resend / Gmail API / dev console).
/// Configure target URL with --dart-define=NM_POS_API_URL=https://api.example.com in production.
class OtpEmailSender {
  OtpEmailSender._();

  static String get _effectiveBaseUrl {
    const fromEnv = String.fromEnvironment('NM_POS_API_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    final host = DbConfig.host;
    // Map localhost to 10.0.2.2 when running inside Android emulator
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://10.0.2.2:8080';
      }
    }
    return 'http://$host:8080';
  }

  static Future<void> send({
    required String email,
    required String code,
    required String purpose,
  }) async {
    final baseUrl = _effectiveBaseUrl;
    final response = await http
        .post(
          Uri.parse('$baseUrl/v1/email/otp'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'code': code, 'purpose': purpose}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 202) {
      String message = 'Email delivery failed. Please try again.';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['error'] is String) message = body['error'] as String;
      } catch (_) {}
      throw Exception(message);
    }
  }
}
