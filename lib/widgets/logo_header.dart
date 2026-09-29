import 'package:flutter/material.dart';

class LogoHeader extends StatelessWidget {
  final double size;

  const LogoHeader({super.key, this.size = 400});

  @override
  Widget build(BuildContext context) {
    final posFontSize = (size * 0.04).clamp(8.0, 16.0);

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.storefront_rounded,
                  size: size * 0.25,
                  color: Colors.white,
                );
              },
            ),
            Positioned(
              top: size * 0.25,
              right: size * 0.235,
              child: Text(
                'POS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: posFontSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}