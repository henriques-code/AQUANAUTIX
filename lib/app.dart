import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/reset_password_screen.dart';
import 'core/state/app_locale_store.dart';
import 'core/supabase_bootstrap.dart';

class AquanautixApp extends StatefulWidget {
  const AquanautixApp({super.key});

  @override
  State<AquanautixApp> createState() => _AquanautixAppState();
}

class _AquanautixAppState extends State<AquanautixApp> {
  final _navKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSub;
  bool _resetOpen = false;

  @override
  void initState() {
    super.initState();
    if (!isSupabaseConfigured) return;
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _openResetIfNeeded();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void _openResetIfNeeded() {
    if (_resetOpen) return;
    final ctx = _navKey.currentContext;
    if (ctx == null) return;
    _resetOpen = true;
    _navKey.currentState
        ?.push(MaterialPageRoute(builder: (_) => const ResetPasswordScreen()))
        .whenComplete(() => _resetOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocaleStore.instance,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: _navKey,
          title: 'AQUANAUTIX',
          debugShowCheckedModeBanner: false,
          locale: AppLocaleStore.instance.locale,
          supportedLocales: const [
            Locale('pt'),
            Locale('es'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData.dark(useMaterial3: true).copyWith(
            scaffoldBackgroundColor: const Color(0xFF000814),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00F5FF),
              surface: Color(0xFF071428),
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
