import 'package:shared_preferences/shared_preferences.dart';

import '../supabase_bootstrap.dart';

/// Preferências «Manter sessão» + email guardado para preenchimento.
class LoginSessionStore {
  LoginSessionStore._();

  static const _rememberKey = 'login_remember_session';
  static const _emailKey = 'login_saved_email';

  static Future<bool> getRememberSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberKey) ?? true;
  }

  static Future<void> setRememberSession(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberKey, value);
  }

  static Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<void> setSavedEmail(String? email) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = email?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      await prefs.remove(_emailKey);
    } else {
      await prefs.setString(_emailKey, trimmed);
    }
  }

  /// Persiste escolha pós-login e email quando «manter sessão» activo.
  static Future<void> persistAfterLogin({
    required bool rememberSession,
    required String email,
  }) async {
    await setRememberSession(rememberSession);
    if (rememberSession) {
      await setSavedEmail(email);
    } else {
      await setSavedEmail(null);
    }
  }

  /// Sessão Supabase só sobrevive entre arranques se «manter sessão» estiver activo.
  static Future<void> applySessionPolicy() async {
    if (!isSupabaseReady) return;
    final client = supabaseClientOrNull;
    if (client == null) return;
    final remember = await getRememberSession();
    if (!remember && client.auth.currentSession != null) {
      await client.auth.signOut();
    }
  }
}
