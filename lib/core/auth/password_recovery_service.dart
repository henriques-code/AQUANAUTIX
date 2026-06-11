import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_bootstrap.dart';

/// Erro ao pedir link de recuperação de password.
class PasswordRecoveryException implements Exception {
  final String message;
  const PasswordRecoveryException(this.message);

  @override
  String toString() => message;
}

/// Pedido de reset via Supabase Auth (`/recover`).
class PasswordRecoveryService {
  PasswordRecoveryService._();
  static final PasswordRecoveryService instance = PasswordRecoveryService._();

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  String? validateEmail(String raw) {
    final email = raw.trim().toLowerCase();
    if (email.isEmpty) return 'Introduz o teu email.';
    if (!_emailPattern.hasMatch(email)) return 'Email inválido.';
    return null;
  }

  Future<void> sendResetLink(String rawEmail) async {
    final validation = validateEmail(rawEmail);
    if (validation != null) {
      throw PasswordRecoveryException(validation);
    }

    if (!isSupabaseReady) {
      throw const PasswordRecoveryException(
        'Supabase indisponível. Verifica ligação ou entra como convidado.',
      );
    }

    final client = supabaseClientOrNull;
    if (client == null) {
      throw const PasswordRecoveryException('Supabase indisponível.');
    }

    final email = rawEmail.trim().toLowerCase();
    try {
      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: resetRedirectUrl,
      );
    } on AuthException catch (e) {
      throw PasswordRecoveryException(_mapAuthError(e.message));
    }
  }

  String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('redirect') || lower.contains('url')) {
      return 'Redirect não autorizado no Supabase. Contacta suporte AQUANAUTIX.';
    }
    if (lower.contains('rate') || lower.contains('limit')) {
      return 'Limite de emails atingido. Tenta novamente dentro de 1 hora.';
    }
    return message;
  }
}
