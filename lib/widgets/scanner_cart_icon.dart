import 'package:flutter/material.dart';

/// Composite icon: barcode scanner + shopping cart
/// Recreates the "scan & sell" concept from the design mockup.
class ScannerCartIcon extends StatelessWidget {
  final double size;
  final Color color;

  const ScannerCartIcon({
    super.key,
    this.size = 30,
    this.color = const Color(0xFF030D19),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Shopping cart — bottom base
          Positioned(
            bottom: -size * 0.05,
            left: 0,
            child: Icon(
              Icons.shopping_cart_rounded,
              size: size * 0.78,
              color: color,
            ),
          ),
          // Barcode scanner — angled top-right
          Positioned(
            top: -size * 0.15,
            right: -size * 0.05,
            child: Transform.rotate(
              angle: 0.4,
              child: Icon(
                Icons.qr_code_scanner_rounded,
                size: size * 0.65,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}