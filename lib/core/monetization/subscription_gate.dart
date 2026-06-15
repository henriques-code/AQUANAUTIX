import '../state/subscription_store.dart';

/// Regras centralizadas FREE / PRO / ELITE — uma fonte para gates na app.
class SubscriptionGate {
  SubscriptionGate._();

  /// Spot PRO bloqueado sem entitlement PRO; spot ELITE bloqueado sem plano ELITE.
  static bool isSpotLocked({
    required String tier,
    required bool elite,
    required SubscriptionState sub,
  }) {
    if (elite || tier.toUpperCase() == 'ELITE') {
      return !sub.isElite;
    }
    if (tier.toUpperCase() == 'PRO') {
      return !sub.hasProEntitlement;
    }
    return false;
  }

  static bool canAccessProFeatures(SubscriptionState sub) => sub.hasProEntitlement;

  static bool canAccessEliteFeatures(SubscriptionState sub) => sub.isElite;
}
