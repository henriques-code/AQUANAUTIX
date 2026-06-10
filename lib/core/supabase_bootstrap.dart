import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _resetRedirectUrl = String.fromEnvironment(
  'SUPABASE_RESET_REDIRECT',
  defaultValue: 'aquanautix://reset-password',
);

bool get isSupabaseConfigured =>
    _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;

bool _supabaseInitialized = false;

bool get isSupabaseReady => _supabaseInitialized;

SupabaseClient? get supabaseClientOrNull =>
    isSupabaseReady ? Supabase.instance.client : null;

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
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  _supabaseInitialized = true;
}

