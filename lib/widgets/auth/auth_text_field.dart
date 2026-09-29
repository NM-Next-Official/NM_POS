import 'package:flutter/material.dart';

/// A themed text field for all authentication screens.
///
/// Supports:
///   • prefix icon
///   • password toggle
///   • phone-specific keyboard
///   • custom validator
///   • inline error text
class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final bool enabled;
  final FocusNode? focusNode;
  final Widget? suffixWidget;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.focusNode,
    this.suffixWidget,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: widget.isPassword ? _obscured : false,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      enabled: widget.enabled,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      cursorColor: const Color(0xFFE5ECF4),
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(
          color: Color(0xFFB0BEC5),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: widget.icon != null
            ? Icon(widget.icon, color: Colors.black87, size: 22)
            : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscured
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: Colors.white70,
                  size: 22,
                ),
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : widget.suffixWidget,
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
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(27),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(27),
          borderSide: const BorderSide(
            color: Color(0xFFE5ECF4),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(27),
          borderSide: const BorderSide(
            color: Color(0xFFFF8A80),
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(27),
          borderSide: const BorderSide(
            color: Color(0xFFFF8A80),
            width: 1.5,
          ),
        ),
        errorStyle: const TextStyle(
          color: Color(0xFFFF8A80),
          fontSize: 12,
        ),
      ),
    );
  }
}