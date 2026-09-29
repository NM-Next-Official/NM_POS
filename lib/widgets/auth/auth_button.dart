import 'package:flutter/material.dart';

/// Primary action button for all auth screens.
///
/// • Shows a spinner when [loading] is true
/// • Disables itself while loading
/// • Consistent styling across the app
class AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
  final double height;
  final double? width;

  const AuthButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.outlined = false,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.height = 52,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? const Color(0xFFE5ECF4);
    final fg = foregroundColor ?? const Color(0xFF030D19);

    if (outlined) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white54, width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
          ),
          child: _child(fg),
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.5),
          disabledForegroundColor: fg.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.5),
        ),
        child: _child(fg),
      ),
    );
  }

  Widget _child(Color fg) {
    if (loading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation<Color>(fg),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
    }

    return Text(
      label,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    );
  }
}