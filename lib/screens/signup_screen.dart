import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../languages/app_localizations.dart';
import '../models/otp_request.dart';
import '../models/user_role.dart';
import '../providers/auth_provider.dart';
import '../services/auth/auth_service.dart';
import '../widgets/auth/auth_button.dart';
import '../widgets/auth/auth_scaffold.dart';
import '../widgets/auth/auth_text_field.dart';
import 'otp_verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  final UserRole role;

  const SignUpScreen({super.key, required this.role});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool get _isOwner => widget.role == UserRole.owner;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isEmail(String value) =>
      RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(value);

  Future<void> _handleSignup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    final email = _identifierController.text.trim().toLowerCase();

    // 1. Verify email format
    if (!_isEmail(email)) {
      final t = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.enterYourEmail),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
      return;
    }

    // 2. Check if email is already taken
    final exists = await auth.emailExists(email);
    if (!mounted) return;
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This email is already registered. Please sign in instead.'),
          backgroundColor: Color(0xFFB71C1C),
        ),
      );
      return;
    }

    // 3. Send verification OTP email
    try {
      await auth.sendOtp(
        destination: email,
        channel: OtpChannel.email,
        purpose: OtpPurpose.signup,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
      return;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Could not send verification code.'),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
      return;
    }

    if (!mounted) return;

    final pendingData = PendingSignupData(
      role: widget.role,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: email,
      password: _passwordController.text,
      businessName: _isOwner ? _businessNameController.text.trim() : null,
      businessAddress: _isOwner ? _businessAddressController.text.trim() : null,
    );

    // 4. Navigate to OTP verification screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          destination: email,
          channel: OtpChannel.email,
          purpose: OtpPurpose.signup,
          signupData: pendingData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();

    return AuthScaffold(
      title: t.createAccount,
      subtitle: _isOwner ? t.businessOwner : t.personalBusiness,
      showBackButton: true,
      dense: true,
      logoSize: 140,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionLabel(t.personalDetails),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AuthTextField(
                    controller: _firstNameController,
                    hint: t.firstName,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? t.pleaseEnterFirstName
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AuthTextField(
                    controller: _lastNameController,
                    hint: t.lastName,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? t.pleaseEnterLastName
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_isOwner) ...[
              _sectionLabel(t.businessDetails),
              const SizedBox(height: 8),
              AuthTextField(
                controller: _businessNameController,
                hint: t.businessName,
                icon: Icons.storefront_rounded,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? t.pleaseEnterBusinessName
                    : null,
              ),
              const SizedBox(height: 10),
              AuthTextField(
                controller: _businessAddressController,
                hint: t.businessAddress,
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 14),
            ],
            _sectionLabel(t.accountDetails),
            const SizedBox(height: 8),
            AuthTextField(
              controller: _identifierController,
              hint: t.enterYourEmail,
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return t.enterYourEmail;
                final val = v.trim();
                if (!_isEmail(val)) {
                  return t.enterYourEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            AuthTextField(
              controller: _passwordController,
              hint: t.passwordHint,
              icon: Icons.shield_rounded,
              isPassword: true,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.isEmpty) return t.pleaseEnterPassword;
                if (v.length < 6) return t.passwordTooShort;
                return null;
              },
            ),
            const SizedBox(height: 10),
            AuthTextField(
              controller: _confirmPasswordController,
              hint: t.confirmPassword,
              icon: Icons.shield_rounded,
              isPassword: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleSignup(),
              validator: (v) {
                if (v == null || v.isEmpty) return t.pleaseEnterPassword;
                if (v != _passwordController.text) {
                  return t.passwordsDoNotMatch;
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            AuthButton(
              label: auth.isBusy ? t.creatingAccount : t.signUp,
              loading: auth.isBusy,
              icon: Icons.person_add_alt_1_rounded,
              onPressed: _handleSignup,
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  t.alreadyRegistered,
                  style: const TextStyle(
                    color: Color(0xFF607D8B),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    t.signIn,
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

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: Color(0xFFB0BEC5),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );
}
