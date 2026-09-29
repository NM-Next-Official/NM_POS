import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../languages/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth/auth_button.dart';
import '../widgets/auth/auth_scaffold.dart';
import '../widgets/auth/auth_text_field.dart';
import 'auth_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String destination;
  final String verificationToken;

  const ResetPasswordScreen({
    super.key,
    required this.destination,
    required this.verificationToken,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String _strength = 'weak';

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _evaluateStrength(String value) {
    if (value.length < 6) {
      _strength = 'weak';
    } else if (value.length >= 10 &&
        RegExp(r'[A-Z]').hasMatch(value) &&
        RegExp(r'[0-9]').hasMatch(value) &&
        RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) {
      _strength = 'strong';
    } else if (value.length >= 8) {
      _strength = 'medium';
    } else {
      _strength = 'weak';
    }
    setState(() {});
  }

  Future<void> _reset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    final t = AppLocalizations.of(context);

    final ok = await auth.resetPassword(
      destination: widget.destination,
      verificationToken: widget.verificationToken,
      newPassword: _passwordController.text,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.resetSuccess),
          backgroundColor: const Color(0xFF1B5E20),
          duration: const Duration(seconds: 3),
        ),
      );

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? t.loginFailed),
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
      title: t.newPasswordTitle,
      subtitle: t.newPasswordSubtitle,
      showBackButton: false,
      logoSize: 160,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              controller: _passwordController,
              hint: t.passwordHint,
              icon: Icons.shield_rounded,
              isPassword: true,
              textInputAction: TextInputAction.next,
              onChanged: _evaluateStrength,
              validator: (v) {
                if (v == null || v.isEmpty) return t.pleaseEnterPassword;
                if (v.length < 6) return t.passwordTooShort;
                return null;
              },
            ),

            const SizedBox(height: 10),

            // Strength indicator
            _StrengthBar(strength: _strength, t: t),

            const SizedBox(height: 14),

            AuthTextField(
              controller: _confirmController,
              hint: t.confirmPassword,
              icon: Icons.shield_rounded,
              isPassword: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _reset(),
              validator: (v) {
                if (v == null || v.isEmpty) return t.pleaseEnterPassword;
                if (v != _passwordController.text) {
                  return t.passwordsDoNotMatch;
                }
                return null;
              },
            ),

            const SizedBox(height: 26),

            AuthButton(
              label: t.resetPassword,
              loading: auth.isBusy,
              icon: Icons.lock_reset_rounded,
              onPressed: _reset,
            ),

            const SizedBox(height: 16),

            Center(
              child: TextButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (_) => false,
                ),
                child: Text(
                  t.backToLogin,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StrengthBar extends StatelessWidget {
  final String strength;
  final AppLocalizations t;

  const _StrengthBar({required this.strength, required this.t});

  @override
  Widget build(BuildContext context) {
    final (color, label, filled) = switch (strength) {
      'strong' => (const Color(0xFF4CAF50), t.strong, 3),
      'medium' => (const Color(0xFFFFA726), t.medium, 2),
      _ => (const Color(0xFFE53935), t.weak, 1),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: i < filled
                      ? color
                      : Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          '${t.passwordStrength}: $label',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}