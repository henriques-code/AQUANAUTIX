import 'dart:async';

import '../supabase_bootstrap.dart';

/// Sincroniza `user_profiles.tier` no Supabase após entitlements RevenueCat.
///
/// Chama a Edge Function `sync-subscription-tier`, que consulta a API RC
/// server-side e actualiza o tier com `service_role` (RLS fishing_spots).
class SubscriptionTierSyncService {
  SubscriptionTierSyncService._();

  /// Fire-and-forget — falhas silenciosas (webhook RC cobre renovações).
  static void scheduleSync() {
    if (!canUseSupabase) return;
    unawaited(syncNow());
  }

  static Future<void> syncNow() async {
    if (!canUseSupabase) return;
    final client = supabaseClientOrNull;
    if (client == null) return;

    try {
      await client.functions.invoke(
        'sync-subscription-tier',
        body: const <String, dynamic>{},
      );
    } catch (_) {
      // Rede / RC / perfil ainda inexistente — webhook ou retry posterior.
    }
  }
}
