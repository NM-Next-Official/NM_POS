import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocale {
  AppLocale._();

  static const String _prefsKey = 'app_language_code';

  static const supportedLanguages = <String, String>{
    'en': 'English',
    'bn': 'Bangla',
    'hi': 'Hindi',
  };

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('bn'),
    Locale('hi'),
  ];

  /// Save user choice
  static Future<void> save(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
  }

  /// Load saved choice (default: 'en')
  static Future<String> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey) ?? 'en';
  }

  /// Get Locale from code
  static Locale toLocale(String code) {
    switch (code) {
      case 'bn':
        return const Locale('bn');
      case 'hi':
        return const Locale('hi');
      default:
        return const Locale('en');
    }
  }
}