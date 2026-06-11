import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/revenue_cat_service.dart';

enum SubscriptionPlan { free, pro, elite }

@immutable
class SubscriptionState {
  final SubscriptionPlan plan;
  final DateTime? trialStartedAt;

  const SubscriptionState({
    this.plan = SubscriptionPlan.free,
    this.trialStartedAt,
  });

  bool get isPro => plan == SubscriptionPlan.pro || plan == SubscriptionPlan.elite;
  bool get isElite => plan == SubscriptionPlan.elite;
  bool get isFree => plan == SubscriptionPlan.free;

  /// Entitlement PRO (gates Vision/Log até RevenueCat): trial activo em FREE ou plano pago PRO/ELITE.
  bool get hasProEntitlement =>
      plan == SubscriptionPlan.pro ||
      plan == SubscriptionPlan.elite ||
      (trialStartedAt != null && trialDaysLeft > 0);

  int get trialDaysLeft {
    final started = trialStartedAt;
    if (started == null) return 0;
    const trialDays = 3;
    final elapsed = DateTime.now().difference(started).inDays;
    final left = trialDays - elapsed;
    return left < 0 ? 0 : left;
  }

  SubscriptionState copyWith({
    SubscriptionPlan? plan,
    DateTime? trialStartedAt,
    bool clearTrial = false,
  }) {
    return SubscriptionState(
      plan: plan ?? this.plan,
      trialStartedAt: clearTrial ? null : (trialStartedAt ?? this.trialStartedAt),
    );
  }
}

class SubscriptionStore {
  SubscriptionStore._();
  static final SubscriptionStore instance = SubscriptionStore._();

  static const _planKey = 'subscription_plan';
  static const _trialStartedAtKey = 'subscription_trial_started_at';

  final ValueNotifier<SubscriptionState> value =
      ValueNotifier<SubscriptionState>(const SubscriptionState());

  Future<void> init() async {
    await _loadFromPrefs();
    if (RevenueCatService.instance.isSdkReady) {
      RevenueCatService.instance.addCustomerInfoListener(_onCustomerInfoUpdated);
    }
    await syncFromRevenueCat();
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    unawaited(_applyCustomerInfo(info));
  }

  /// Recarrega entitlements do RevenueCat quando o SDK está pronto.
  /// Silencioso em falha de rede — mantém estado vindo de [_loadFromPrefs].
  Future<void> syncFromRevenueCat() async {
    if (!RevenueCatService.instance.isSdkReady) return;
    try {
      final info = await RevenueCatService.instance.getCustomerInfo();
      await _applyCustomerInfo(info);
    } catch (_) {
      // Fallback: prefs já aplicadas em init.
    }
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final rawPlan = prefs.getString(_planKey) ?? 'free';
    final rawTrialStartedAt = prefs.getString(_trialStartedAtKey);
    final state = SubscriptionState(
      plan: _parsePlan(rawPlan),
      trialStartedAt:
          rawTrialStartedAt == null ? null : DateTime.tryParse(rawTrialStartedAt),
    );
    value.value = state;
  }

  Future<void> _applyCustomerInfo(CustomerInfo info) async {
    final status = RevenueCatService.instance.entitlementStatus(info);
    final elite =
        status[RevenueCatService.entitlementElite] == true;
    final pro = status[RevenueCatService.entitlementPro] == true;

    final SubscriptionPlan remotePlan;
    if (elite) {
      remotePlan = SubscriptionPlan.elite;
    } else if (pro) {
      remotePlan = SubscriptionPlan.pro;
    } else {
      remotePlan = SubscriptionPlan.free;
    }

    final clearTrial = remotePlan != SubscriptionPlan.free;
    value.value = value.value.copyWith(
      plan: remotePlan,
      clearTrial: clearTrial,
    );
    await _persist();
  }

  Future<void> setPlan(SubscriptionPlan plan) async {
    value.value = value.value.copyWith(plan: plan);
    await _persist();
  }

  Future<void> startTrialIfNeeded() async {
    if (value.value.trialStartedAt != null) return;
    value.value = value.value.copyWith(trialStartedAt: DateTime.now());
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planKey, value.value.plan.name);
    final trial = value.value.trialStartedAt;
    if (trial == null) {
      await prefs.remove(_trialStartedAtKey);
    } else {
      await prefs.setString(_trialStartedAtKey, trial.toIso8601String());
    }
  }

  SubscriptionPlan _parsePlan(String value) {
    return SubscriptionPlan.values.firstWhere(
      (p) => p.name == value,
      orElse: () => SubscriptionPlan.free,
    );
  }
}
