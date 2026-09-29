import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../languages/app_localizations.dart';
import '../models/otp_request.dart';
import '../providers/auth_provider.dart';
import '../services/auth/auth_service.dart';
import '../widgets/auth/auth_button.dart';
import '../widgets/auth/auth_scaffold.dart';
import '../widgets/auth/otp_input.dart';
import 'reset_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String destination;
  final OtpChannel channel;
  final OtpPurpose purpose;

  const OtpVerificationScreen({
    super.key,
    required this.destination,
    required this.channel,
    required this.purpose,
  });

  @override
  State<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _codeController = TextEditingController();
  Timer? _timer;
  int _secondsLeft = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = 60;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) return;

    final auth = context.read<AuthProvider>();
    final t = AppLocalizations.of(context);

    final token = await auth.verifyOtp(
      destination: widget.destination,
      code: code,
      purpose: widget.purpose,
    );

    if (!mounted) return;

    if (token == null) {
      // Failed
      _codeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? t.otpInvalid),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
      return;
    }

    // Success — go to reset screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(
          destination: widget.destination,
          verificationToken: token,
        ),
      ),
    );
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    final t = AppLocalizations.of(context);

    try {
      await auth.sendOtp(
        destination: widget.destination,
        channel: widget.channel,
        purpose: widget.purpose,
      );
      _codeController.clear();
      _startCountdown();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${t.otpSentTo} → ${widget.destination}'),
          backgroundColor: const Color(0xFF1B5E20),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();

    return AuthScaffold(
      title: t.otpTitle,
      subtitle: '${t.otpSubtitle}\n${widget.destination}',
      showBackButton: true,
      logoSize: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          OtpInput(
            controller: _codeController,
            onCompleted: (_) => _verify(),
            enabled: !auth.isBusy,
          ),

          const SizedBox(height: 24),

          AuthButton(
            label: auth.isBusy ? t.verifying : t.verify,
            loading: auth.isBusy,
            icon: Icons.check_circle_outline_rounded,
            onPressed: _codeController.text.length == 6 ? _verify : null,
          ),

          const SizedBox(height: 20),

          // Resend area
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                t.didNotReceive,
                style: const TextStyle(
                  color: Color(0xFF607D8B),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              if (_canResend)
                GestureDetector(
                  onTap: auth.isBusy ? null : _resend,
                  child: Text(
                    t.resendCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Text(
                  t.resendIn(_secondsLeft),
                  style: const TextStyle(
                    color: Color(0xFF607D8B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}