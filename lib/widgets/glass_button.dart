import 'dart:ui';

import 'package:flutter/material.dart';

/// Premium glass-effect button with:
///   • Backdrop blur
///   • Layered gradient (glass sheen)
///   • Ambient pulsing glow
///   • Press-scale animation
///   • Inner light border
class GlassButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final double width;
  final double height;

  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width = 250,
    this.height = 60,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _glow;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _glow = Tween<double>(begin: 0.18, end: 0.42).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: AnimatedBuilder(
          animation: _glow,
          builder: (context, _) {
            return Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.height / 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE5ECF4)
                        .withValues(alpha: _glow.value),
                    blurRadius: 36,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.height / 2),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.35),
                          Colors.white.withValues(alpha: 0.10),
                          Colors.white.withValues(alpha: 0.22),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.3,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 1,
                          left: 20,
                          right: 20,
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: 0.75),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            widget.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4.0,
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 10,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
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