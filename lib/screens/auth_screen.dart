import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../languages/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth/auth_button.dart';
import '../widgets/auth/auth_scaffold.dart';
import '../widgets/auth/auth_text_field.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'role_selection_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isEmail(String value) =>
      RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(value);

  bool _isPhone(String value) =>
      value.replaceAll(RegExp(r'\D'), '').length >= 8;

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    final success = _isEmail(identifier)
        ? await auth.loginWithEmail(identifier, password)
        : await auth.loginWithPhone(identifier, password);

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      final t = AppLocalizations.of(context);
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
      title: t.welcomeBack,
      subtitle: t.emailOrPhone,
      showBackButton: true,
      logoSize: 220,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              controller: _identifierController,
              hint: t.emailOrPhone,
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return t.enterYourEmail;
                final val = v.trim();
                if (!_isEmail(val) && !_isPhone(val)) {
                  return t.enterYourEmail;
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            AuthTextField(
              controller: _passwordController,
              hint: t.passwordHint,
              icon: Icons.shield_rounded,
              isPassword: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(),
              validator: (v) {
                if (v == null || v.isEmpty) return t.pleaseEnterPassword;
                if (v.length < 6) return t.passwordTooShort;
                return null;
              },
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen(),
                  ),
                ),
                child: Text(
                  t.forgotPasswordLink,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),

            const SizedBox(height: 8),

            AuthButton(
              label: auth.isBusy ? t.signingIn : t.signIn,
              loading: auth.isBusy,
              icon: Icons.login_rounded,
              onPressed: _handleLogin,
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  t.noAccountYet,
                  style: const TextStyle(
                    color: Color(0xFF607D8B),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RoleSelectionScreen(),
                    ),
                  ),
                  child: Text(
                    t.signUp,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}