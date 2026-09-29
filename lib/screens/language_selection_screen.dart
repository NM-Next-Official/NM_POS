import 'package:flutter/material.dart';
import '../main.dart';
import '../utils/app_locale.dart';
import '../widgets/logo_header.dart';
import 'auth_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedCode = 'en';

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final code = await AppLocale.load();
    if (mounted) setState(() => _selectedCode = code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030D19),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            const LogoHeader(),
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24.0),
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: AppLocale.supportedLanguages.entries.map((entry) {
                    final code = entry.key;
                    final label = entry.value;
                    final isSelected = code == _selectedCode;

                    return GestureDetector(
                      onTap: () async {
                        setState(() => _selectedCode = code);
                        await MyApp.of(context).setLanguage(code);

                        await Future.delayed(
                          const Duration(milliseconds: 200),
                        );
                        if (!context.mounted) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AuthScreen(),
                          ),
                        );
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
                                : Colors.white.withValues(alpha: 0.45),
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