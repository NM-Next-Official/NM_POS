import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config/db_config.dart';
import 'languages/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth/postgres_auth_service.dart';
import 'services/db/postgres_db.dart';
import 'utils/app_locale.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late final AuthProvider _authProvider;
  Locale _locale = const Locale('en');
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // ⚠️ Change: MockAuthService → PostgresAuthService
    _authProvider = AuthProvider(PostgresAuthService());
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // ─── Test PostgreSQL connection ───
    try {
      await PostgresDb.instance.init();
      // ignore: avoid_print
      print('✅ PostgreSQL connected');
      // ignore: avoid_print
      print('   → ${DbConfig.database}@${DbConfig.host}:${DbConfig.port}');
      // ignore: avoid_print
      print('   → user: ${DbConfig.username}');
    } catch (e) {
      // ignore: avoid_print
      print('❌ PostgreSQL init failed: $e');
      // ignore: avoid_print
      print('   Host: ${DbConfig.host}');
      // ignore: avoid_print
      print('   Port: ${DbConfig.port}');
      // ignore: avoid_print
      print('   DB:   ${DbConfig.database}');
      // ignore: avoid_print
      print('   User: ${DbConfig.username}');
    }

    // ─── Restore language + session ───
    final code = await AppLocale.load();
    await _authProvider.bootstrap();

    if (!mounted) return;
    setState(() {
      _locale = AppLocale.toLocale(code);
      _ready = true;
    });
  }

  Future<void> setLanguage(String code) async {
    await AppLocale.save(code);
    if (!mounted) return;
    setState(() => _locale = AppLocale.toLocale(code));
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF030D19),
          body: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return ChangeNotifierProvider<AuthProvider>.value(
      value: _authProvider,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'NM POS',
        theme: ThemeData.light().copyWith(
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          colorScheme: ThemeData.light().colorScheme.copyWith(
                primary: const Color(0xFF182535),
                secondary: const Color(0xFF2E67A0),
              ),
        ),
        locale: _locale,
        supportedLocales: AppLocale.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) => auth.status == AuthStatus.authenticated
              ? const HomeScreen()
              : const WelcomeScreen(),
        ),
      ),
    );
  }
}
