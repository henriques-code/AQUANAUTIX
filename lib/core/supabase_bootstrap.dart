import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _resetRedirectUrl = String.fromEnvironment(
  'SUPABASE_RESET_REDIRECT',
  defaultValue: 'https://aquanautix.vercel.app/reset-password',
);

/// Chaves presentes em compile-time (`--dart-define` / `run_dev.*`).
bool get isSupabaseConfigured =>
    _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;

bool _supabaseInitialized = false;
String? _supabaseInitError;

bool get isSupabaseReady => _supabaseInitialized;

/// Cliente disponível para chamadas runtime (auth, DB, storage).
bool get canUseSupabase => isSupabaseReady;

String? get supabaseInitError => _supabaseInitError;

SupabaseClient? get supabaseClientOrNull =>
    isSupabaseReady ? Supabase.instance.client : null;

/// Stream de auth — null se Supabase não inicializado (modo convidado / sem .env).
Stream<AuthState>? get supabaseAuthStateChangesOrNull =>
    supabaseClientOrNull?.auth.onAuthStateChange;

String get resetRedirectUrl => _resetRedirectUrl;

bool get isSupabaseAuthenticated {
  final client = supabaseClientOrNull;
  if (client == null) return false;
  return client.auth.currentSession != null;
}

String? get supabaseCurrentUserEmail {
  return supabaseClientOrNull?.auth.currentUser?.email;
}

Future<void> initSupabaseIfConfigured() async {
  if (!isSupabaseConfigured || _supabaseInitialized) return;
  try {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        detectSessionInUri: true,
      ),
    );
    _supabaseInitialized = true;
    _supabaseInitError = null;
  } catch (e, st) {
    _supabaseInitError = e.toString();
    if (kDebugMode) {
      debugPrint('[AQUANAUTIX][supabase] init falhou: $e\n$st');
    }
  }
}
