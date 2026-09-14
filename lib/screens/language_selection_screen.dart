import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/logo_header.dart';
import 'auth_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  // Map display labels to standard language codes
  final List<Map<String, String>> languages = [
    {'label': 'English', 'code': 'en'},
    {'label': 'Bangla', 'code': 'bn'},
    {'label': 'Hindi', 'code': 'hi'},
  ];

  @override
  Widget build(BuildContext context) {
    final currentCode = MyApp.of(context).currentLanguageCode;

    return Scaffold(
      backgroundColor: const Color(0xFF030D19),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),

            // Logo Header Widget
            const LogoHeader(),

            const Spacer(flex: 3),

            // Language Selection Container
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24.0),
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: languages.map((langItem) {
                    final String label = langItem['label']!;
                    final String code = langItem['code']!;
                    final isSelected = code == currentCode;

                    return GestureDetector(
                      onTap: () {
                        // 1. Set global translation language
                        MyApp.of(context).setLanguage(code);

                        // 2. Navigate to AuthScreen
                        Future.delayed(const Duration(milliseconds: 200), () {
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AuthScreen(),
                              ),
                            );
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 6.0,
                        ),
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFE5ECF4)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: isSelected ? 24 : 22,
                            fontWeight:
                                isSelected ? FontWeight.w900 : FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF030D19)
                                : Colors.white.withOpacity(0.45),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
