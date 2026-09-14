import 'package:flutter/material.dart';
import 'utils/dynamic_translator.dart';
import 'screens/welcome_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Store active language code ('en', 'bn', 'hi')
  String _currentLanguageCode = 'en';

  String get currentLanguageCode => _currentLanguageCode;

  void setLanguage(String language) {
    setState(() {
      // Sync with DynamicTranslator
      DynamicTranslator.setLanguage(language);
      _currentLanguageCode = DynamicTranslator.activeLanguageCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NM POS',
      theme: ThemeData.dark(),
      home: const WelcomeScreen(),
    );
  }
}
