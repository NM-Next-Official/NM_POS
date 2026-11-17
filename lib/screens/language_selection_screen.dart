import 'dart:async';

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
  late final FixedExtentScrollController _languageController =
      FixedExtentScrollController();
  late final List<String> _codes = AppLocale.supportedLanguages.keys.toList();
  late final List<String> _names = AppLocale.supportedLanguages.values.toList();
  int _selectedIndex = 0;
  Timer? _languageSaveDebounce;
  bool _openingAuth = false;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final code = await AppLocale.load();
    final index = _codes.indexOf(code);
    if (!mounted || index < 0) return;
    setState(() => _selectedIndex = index);
    _languageController.animateToItem(
      index,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
    );
  }

  void _onLanguageChanged(int index) {
    setState(() => _selectedIndex = index);
    _languageSaveDebounce?.cancel();
    _languageSaveDebounce = Timer(const Duration(milliseconds: 180), () {
      if (mounted) MyApp.of(context).setLanguage(_codes[_selectedIndex]);
    });
  }

  Future<void> _openAuthForSelectedLanguage() async {
    if (_openingAuth) return;
    setState(() => _openingAuth = true);
    _languageSaveDebounce?.cancel();
    await MyApp.of(context).setLanguage(_codes[_selectedIndex]);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  @override
  void dispose() {
    _languageSaveDebounce?.cancel();
    _languageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF030D19),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: constraints.maxHeight * .04),
                    const LogoHeader(size: 280),
                    const SizedBox(height: 16),
                    Text(
                      _chooseLanguageLabel,
                      style: TextStyle(
                        color: Color(0xFFB9C6D2),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 204,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1A29),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: const Color(0xFF304358)),
                      ),
                      child: ListWheelScrollView.useDelegate(
                        controller: _languageController,
                        itemExtent: 58,
                        diameterRatio: 1.8,
                        perspective: 0.002,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: _onLanguageChanged,
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: _names.length,
                          builder: (context, index) {
                            final selected = index == _selectedIndex;
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (selected) {
                                  _openAuthForSelectedLanguage();
                                } else {
                                  _languageController.animateToItem(
                                    index,
                                    duration: const Duration(milliseconds: 340),
                                    curve: Curves.easeOutCubic,
                                  );
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFFE4EAF2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                alignment: Alignment.center,
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 180),
                                  style: TextStyle(
                                    color: selected
                                        ? const Color(0xFF06111E)
                                        : const Color(0xFF9AABBB),
                                    fontSize: selected ? 24 : 21,
                                    fontWeight: selected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    letterSpacing: .2,
                                  ),
                                  child: Text(_names[index]),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      _tapToContinueLabel,
                      style: const TextStyle(
                        color: Color(0xFF8194A8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight * .04),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  String get _chooseLanguageLabel {
    switch (_codes[_selectedIndex]) {
      case 'bn':
        return 'আপনার ভাষা নির্বাচন করুন';
      case 'hi':
        return 'अपनी भाषा चुनें';
      default:
        return 'Choose your language';
    }
  }

  String get _tapToContinueLabel {
    switch (_codes[_selectedIndex]) {
      case 'bn':
        return 'এগিয়ে যেতে নির্বাচিত ভাষায় ট্যাপ করুন';
      case 'hi':
        return 'आगे बढ़ने के लिए चुनी गई भाषा पर टैप करें';
      default:
        return 'Tap the selected language to continue';
    }
  }
}
