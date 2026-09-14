import 'package:flutter/material.dart';

class LogoHeader extends StatelessWidget {
  const LogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 400,
        height: 400,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 400,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.storefront_rounded,
                  size: 100,
                  color: Colors.white,
                );
              },
            ),
            const Positioned(
              top: 100,
              right: 94,
              child: Text(
                'POS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
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
