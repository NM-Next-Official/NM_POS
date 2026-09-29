import 'package:flutter/material.dart';

import '../languages/app_localizations.dart';
import '../widgets/glass_button.dart';
import '../widgets/logo_header.dart';
import 'language_selection_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF030D19),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const LogoHeader(),
            const Spacer(flex: 3),
            GlassButton(
              label: t.start,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LanguageSelectionScreen(),
                  ),
                );
              },
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}