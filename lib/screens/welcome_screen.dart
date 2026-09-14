import 'package:flutter/material.dart';
import '../widgets/logo_header.dart';
import 'language_selection_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030D19),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),

            // Exact identical Logo placement
            const LogoHeader(),

            const Spacer(),

            // Start Button
            Padding(
              padding: const EdgeInsets.only(bottom: 60.0),
              child: SizedBox(
                width: 220,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LanguageSelectionScreen(),
                      ),
                    );
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
                  child: const Text(
                    'START',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
