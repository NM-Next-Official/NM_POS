import 'package:flutter/material.dart';
import '../utils/dynamic_translator.dart';
import '../widgets/logo_header.dart';
import 'auth_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isObscureNewPassword = true;
  bool _isObscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Dynamic text translator wrapper
  Widget _buildTranslatedText(
    String text, {
    TextStyle? style,
    TextAlign? textAlign,
  }) {
    return FutureBuilder<String>(
      future: DynamicTranslator.translate(text),
      builder: (context, snapshot) {
        return Text(
          snapshot.data ?? text,
          style: style,
          textAlign: textAlign,
        );
      },
    );
  }

  // Input Field with Icon
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    Widget? prefix,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return FutureBuilder<String>(
      future: DynamicTranslator.translate(hintText),
      builder: (context, snapshot) {
        return TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: snapshot.data ?? hintText,
            hintStyle: const TextStyle(
              color: Color(0xFFB0BEC5),
              fontSize: 16,
            ),
            prefixIcon: prefix != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: prefix,
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 50,
              minHeight: 24,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFF536273).withValues(alpha: 0.55),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(27),
              borderSide: BorderSide.none,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030D19),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Logo Header Component
                        const LogoHeader(),

                        const SizedBox(height: 10),

                        // Subtitle text under Logo
                        _buildTranslatedText(
                          'Reset Password',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Email Field
                        _buildInputField(
                          controller: _emailController,
                          hintText: 'Enter your e-mail',
                          prefix: const Icon(
                            Icons.email_rounded,
                            color: Colors.black87,
                            size: 24,
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 14),

                        // OTP Field
                        _buildInputField(
                          controller: _otpController,
                          hintText: 'Enter Your OTP',
                          prefix: const Text(
                            'OTP',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),

                        const SizedBox(height: 16),

                        // Send OTP Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: Trigger OTP delivery API
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('OTP sent to your email!'),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF030D19),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                              elevation: 4,
                              shadowColor: Colors.black.withValues(alpha: 0.5),
                            ),
                            child: _buildTranslatedText(
                              'Send OTP',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // New Password
                        _buildInputField(
                          controller: _newPasswordController,
                          hintText: 'New Password',
                          prefix: const Icon(
                            Icons.shield_rounded,
                            color: Colors.black87,
                            size: 24,
                          ),
                          obscureText: _isObscureNewPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscureNewPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _isObscureNewPassword = !_isObscureNewPassword;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Confirm New Password
                        _buildInputField(
                          controller: _confirmPasswordController,
                          hintText: 'Confirm New Password',
                          prefix: const Icon(
                            Icons.shield_rounded,
                            color: Colors.black87,
                            size: 24,
                          ),
                          obscureText: _isObscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscureConfirmPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _isObscureConfirmPassword =
                                    !_isObscureConfirmPassword;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Login / Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: Process password reset validation & API submit
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AuthScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE5ECF4),
                              foregroundColor: const Color(0xFF030D19),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                              elevation: 4,
                              shadowColor: Colors.black.withValues(alpha: 0.5),
                            ),
                            child: _buildTranslatedText(
                              'Login',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
