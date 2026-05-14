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
}
