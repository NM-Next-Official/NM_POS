import 'package:flutter/material.dart';

import '../logo_header.dart';

class AuthScaffold extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  final bool showBackButton;
  final bool showLogo;
  final bool dense;
  final double logoSize;

  const AuthScaffold({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
    this.footer,
    this.showBackButton = true,
    this.showLogo = true,
    this.dense = false,
    this.logoSize = 400,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030D19),
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 28.0,
                    vertical: dense ? 8 : 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showLogo) ...[
                            SizedBox(height: dense ? 0 : 10),
                            LogoHeader(size: logoSize),
                            SizedBox(height: dense ? 4 : 16),
                          ],
                          if (title != null) ...[
                            Text(
                              title!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: dense ? 20 : 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: dense ? 4 : 6),
                          ],
                          if (subtitle != null) ...[
                            Text(
                              subtitle!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFB0BEC5),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(height: dense ? 14 : 20),
                          ],
                          child,
                          const SizedBox(height: 16),
                          if (footer != null) footer!,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (showBackButton)
              Positioned(
                top: 4,
                left: 4,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}