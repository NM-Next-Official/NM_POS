import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

/// A 6-digit OTP input built on top of `pinput`.
///
/// Styled to match the app's dark theme. Auto-submits when all 6 digits
/// are filled (via [onCompleted]).
class OtpInput extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String)? onCompleted;
  final void Function(String)? onChanged;
  final bool enabled;
  final int length;

  const OtpInput({
    super.key,
    required this.controller,
    this.onCompleted,
    this.onChanged,
    this.enabled = true,
    this.length = 6,
  });

  @override
  Widget build(BuildContext context) {
    final defaultTheme = PinTheme(
      width: 52,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF536273).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.transparent, width: 1.5),
      ),
    );

    final focusedTheme = defaultTheme.copyWith(
      decoration: defaultTheme.decoration!.copyWith(
        border: Border.all(color: const Color(0xFFE5ECF4), width: 1.8),
      ),
    );

    final errorTheme = defaultTheme.copyWith(
      decoration: defaultTheme.decoration!.copyWith(
        border: Border.all(color: const Color(0xFFFF8A80), width: 1.8),
      ),
    );

    final submittedTheme = defaultTheme.copyWith(
      decoration: defaultTheme.decoration!.copyWith(
        border: Border.all(color: const Color(0xFFE5ECF4), width: 1.4),
      ),
    );

    return Pinput(
      controller: controller,
      length: length,
      enabled: enabled,
      autofocus: true,
      keyboardType: TextInputType.number,
      defaultPinTheme: defaultTheme,
      focusedPinTheme: focusedTheme,
      errorPinTheme: errorTheme,
      submittedPinTheme: submittedTheme,
      onCompleted: onCompleted,
      onChanged: onChanged,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      separatorBuilder: (index) => const SizedBox(width: 6),
    );
  }
}