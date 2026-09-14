import 'package:flutter/material.dart';
import '../utils/dynamic_translator.dart';
import '../widgets/logo_header.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessAddressController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

  // Reusable text field builder for single full-width fields
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    IconData? icon,
    bool obscureText = false,
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
            prefixIcon: icon != null
                ? Icon(
                    icon,
                    color: Colors.black87,
                    size: 24,
                  )
                : null,
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

                        // Subtitle text under Logo
                        _buildTranslatedText(
                          'Make Your Business Lite',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // First Name & Last Name Side-by-Side Fields
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                controller: _firstNameController,
                                hintText: 'First Name',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInputField(
                                controller: _lastNameController,
                                hintText: 'Last Name',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Your Business Name
                        _buildInputField(
                          controller: _businessNameController,
                          hintText: 'Your Business Name',
                          icon: Icons.storefront_rounded,
                        ),

                        const SizedBox(height: 14),

                        // Business Address
                        _buildInputField(
                          controller: _businessAddressController,
                          hintText: 'Business Address',
                          icon: Icons.smartphone_rounded,
                        ),

                        const SizedBox(height: 14),

                        // Enter your e-mail
                        _buildInputField(
                          controller: _emailController,
                          hintText: 'Enter your e-mail',
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 14),

                        // Password
                        _buildInputField(
                          controller: _passwordController,
                          hintText: 'Password',
                          icon: Icons.shield_rounded,
                          obscureText: true,
                        ),

                        const SizedBox(height: 14),

                        // Confirm Password (Fixed typo: 'Confrom' -> 'Confirm')
                        _buildInputField(
                          controller: _confirmPasswordController,
                          hintText: 'Confirm Password',
                          icon: Icons.shield_rounded,
                          obscureText: true,
                        ),

                        const SizedBox(height: 24),

                        // Submit Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HomeScreen(),
                                  ),
                                );
                              }
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
                              'Sign Up',
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
