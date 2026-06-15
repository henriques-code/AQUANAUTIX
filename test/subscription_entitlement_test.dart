import 'package:aquanautix/core/monetization/subscription_gate.dart';
import 'package:aquanautix/core/services/revenue_cat_service.dart';
import 'package:aquanautix/core/state/subscription_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hasProEntitlement: trial activo em FREE', () {
    final started = DateTime.now().subtract(const Duration(days: 1));
    const s = SubscriptionState(
      plan: SubscriptionPlan.free,
      trialStartedAt: null,
    );
    expect(s.hasProEntitlement, false);

    final t = SubscriptionState(
      plan: SubscriptionPlan.free,
      trialStartedAt: started,
    );
    expect(t.trialDaysLeft, greaterThan(0));
    expect(t.hasProEntitlement, true);
  });

  test('hasProEntitlement: PRO e ELITE', () {
    expect(
      const SubscriptionState(plan: SubscriptionPlan.pro).hasProEntitlement,
      true,
    );
    expect(
      const SubscriptionState(plan: SubscriptionPlan.elite).hasProEntitlement,
      true,
    );
  });

  test('packageIdForPlanKey: defaults alinhados com offering RC', () {
    expect(RevenueCatService.packageIdForPlanKey('pro_monthly'), 'pro_monthly');
    expect(RevenueCatService.packageIdForPlanKey('pro_annual'), 'pro_annual');
    expect(RevenueCatService.packageIdForPlanKey('elite_annual'), 'elite_annual');
    expect(RevenueCatService.packageIdForPlanKey('unknown'), '');
  });

  test('SubscriptionGate: spots PRO e ELITE', () {
    const free = SubscriptionState(plan: SubscriptionPlan.free);
    const pro = SubscriptionState(plan: SubscriptionPlan.pro);
    const elite = SubscriptionState(plan: SubscriptionPlan.elite);

    expect(
      SubscriptionGate.isSpotLocked(tier: 'FREE', elite: false, sub: free),
      false,
    );
    expect(
      SubscriptionGate.isSpotLocked(tier: 'PRO', elite: false, sub: free),
      true,
    );
    expect(
      SubscriptionGate.isSpotLocked(tier: 'PRO', elite: false, sub: pro),
      false,
    );
    expect(
      SubscriptionGate.isSpotLocked(tier: 'ELITE', elite: true, sub: pro),
      true,
    );
    expect(
      SubscriptionGate.isSpotLocked(tier: 'ELITE', elite: true, sub: elite),
      false,
    );
  });
}
