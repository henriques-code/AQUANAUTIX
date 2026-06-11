import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/revenue_cat_service.dart';
import '../state/subscription_store.dart';
import '../supabase_bootstrap.dart';

/// Liga auth Supabase ↔ RevenueCat (logIn/logOut + sync entitlements).
class SubscriptionAuthBridge {
  SubscriptionAuthBridge._();

  static StreamSubscription<AuthState>? _sub;

  static void init() {
    if (!isSupabaseReady || !RevenueCatService.instance.isSdkReady) return;

    _sub?.cancel();
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen(_onAuth);

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      unawaited(_identify(userId));
    }
  }

  static Future<void> _onAuth(AuthState data) async {
    if (!RevenueCatService.instance.isSdkReady) return;

    switch (data.event) {
      case AuthChangeEvent.signedIn:
        final id = data.session?.user.id;
        if (id != null) await _identify(id);
        break;
      case AuthChangeEvent.signedOut:
        await signOut();
        break;
      default:
        break;
    }
  }

  static Future<void> _identify(String userId) async {
    try {
      await RevenueCatService.instance.logIn(userId);
      await SubscriptionStore.instance.syncFromRevenueCat();
    } catch (_) {
      // Rede/RC indisponível — prefs locais mantêm-se.
    }
  }

  /// Chamado no logout do Perfil — não forçar plano FREE localmente.
  static Future<void> signOut() async {
    if (!RevenueCatService.instance.isSdkReady) {
      await SubscriptionStore.instance.setPlan(SubscriptionPlan.free);
      return;
    }
    try {
      await RevenueCatService.instance.logOut();
      await SubscriptionStore.instance.syncFromRevenueCat();
    } catch (_) {
      await SubscriptionStore.instance.setPlan(SubscriptionPlan.free);
    }
  }

  static void dispose() => _sub?.cancel();
}
