import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _resetRedirectUrl = String.fromEnvironment(
  'SUPABASE_RESET_REDIRECT',
  defaultValue: 'aquanautix://reset-password',
);

bool get isSupabaseConfigured =>
    _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;

SupabaseClient? get supabaseClientOrNull =>
    isSupabaseConfigured ? Supabase.instance.client : null;

String get resetRedirectUrl => _resetRedirectUrl;

bool get isSupabaseAuthenticated {
  if (!isSupabaseConfigured) return false;
  return Supabase.instance.client.auth.currentSession != null;
}

String? get supabaseCurrentUserEmail {
  if (!isSupabaseConfigured) return null;
  return Supabase.instance.client.auth.currentUser?.email;
}

Future<void> initSupabaseIfConfigured() async {
  if (!isSupabaseConfigured) return;
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
}

