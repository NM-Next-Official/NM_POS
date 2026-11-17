import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../languages/app_localizations.dart';
import '../models/otp_request.dart';
import '../providers/auth_provider.dart';
import '../services/auth/auth_service.dart';
import '../widgets/auth/auth_button.dart';
import '../widgets/auth/auth_scaffold.dart';
import '../widgets/auth/auth_text_field.dart';
import 'otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  bool _isEmail(String value) =>
      RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(value);

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    final identifier = _identifierController.text.trim();

    const channel = OtpChannel.email;

    try {
      await auth.sendOtp(
        destination: identifier,
        channel: channel,
        purpose: OtpPurpose.passwordReset,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            destination: identifier,
            channel: channel,
            purpose: OtpPurpose.passwordReset,
          ),
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
      title: t.forgotPasswordTitle,
      subtitle: t.forgotPasswordSubtitle,
      showBackButton: true,
      logoSize: 180,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              controller: _identifierController,
              hint: t.enterYourEmail,
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _sendCode(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return t.enterYourEmail;
                final val = v.trim();
                if (!_isEmail(val)) {
                  return t.enterYourEmail;
                }
                return null;
              },
            ),

            const SizedBox(height: 26),

            AuthButton(
              label: auth.isBusy ? t.sendingCode : t.sendCode,
              loading: auth.isBusy,
              icon: Icons.send_rounded,
              onPressed: _sendCode,
            ),
          ],
        ),
      ),
    );
  }
}
