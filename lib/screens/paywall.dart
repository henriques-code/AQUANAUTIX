import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/services/analytics_service.dart';
import '../core/services/revenue_cat_service.dart';
import '../core/state/subscription_store.dart';
import '../core/l10n/aqx_l10n.dart';
import '_shared.dart';

/// Paywall de teste / produção: PRO mensal, **PRO anual** (oferta), ELITE anual, trial 3d.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, required this.source});

  final String source;

  static Future<void> open(BuildContext context, {required String source}) async {
    await AnalyticsService.instance.track(
      AnalyticsEvents.paywallView,
      params: {'source': source},
    );
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => PaywallScreen(source: source)),
    );
  }

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _committed = false;
  bool _busy = false;
  Offerings? _offerings;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    if (!RevenueCatService.instance.isSdkReady) return;
    try {
      final offerings = await RevenueCatService.instance.getOfferings();
      if (mounted) setState(() => _offerings = offerings);
    } catch (_) {}
  }

  String _priceLabel(String planKey, String fallback) {
    final pkg = RevenueCatService.resolvePackage(_offerings, planKey: planKey);
    final storePrice = pkg?.storeProduct.priceString;
    if (storePrice == null || storePrice.isEmpty) return fallback;
    return switch (planKey) {
      'pro_monthly' => '$storePrice/mês',
      'pro_annual' || 'elite_annual' => '$storePrice/ano',
      _ => storePrice,
    };
  }

  Future<void> _trackPlanSelected(String planKey) async {
    await AnalyticsService.instance.track(
      AnalyticsEvents.paywallPlanSelected,
      params: {'source': widget.source, 'plan_key': planKey},
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: ibm(13))),
    );
  }

  /// Trial 3 dias — local (prefs), independente da compra na loja.
  Future<void> _startTrial() async {
    final t = aqxL10nOf(context);
    if (_busy) return;

    if (!RevenueCatService.instance.isSdkReady && !kDebugMode) {
      _snack(
        t.es
            ? 'Trial no disponible en este build.'
            : 'Trial indisponível neste build.',
      );
      return;
    }

    final sub = SubscriptionStore.instance.value.value;
    if (sub.trialStartedAt != null && sub.trialDaysLeft <= 0) {
      _snack(
        t.es
            ? 'Ya usaste el trial de 3 días.'
            : 'Já usaste o trial de 3 dias.',
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await SubscriptionStore.instance.startTrialIfNeeded();
      setState(() => _committed = true);
      await AnalyticsService.instance.track(
        AnalyticsEvents.trialStart,
        params: {'source': widget.source},
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restorePurchases() async {
    final t = aqxL10nOf(context);
    if (_busy) return;
    final rc = RevenueCatService.instance;
    if (!rc.isSdkReady) {
      _snack(t.es ? 'Restauración sólo con RevenueCat configurado.' : 'Restauro só com RevenueCat configurado.');
      return;
    }

    setState(() => _busy = true);
    try {
      try {
        await rc.restorePurchases();
      } on RevenueCatException catch (e) {
        _snack(e.message);
        return;
      }

      await SubscriptionStore.instance.syncFromRevenueCat();
      if (!SubscriptionStore.instance.value.value.hasProEntitlement) {
        _snack(t.es ? 'No se encontró ninguna compra.' : 'Nenhuma compra encontrada.');
        return;
      }

      setState(() => _committed = true);
      final plan = SubscriptionStore.instance.value.value.plan;
      await AnalyticsService.instance.track(
        AnalyticsEvents.purchaseSuccess,
        params: {'source': widget.source, 'plan': plan.name, 'plan_key': 'restore'},
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _activate(SubscriptionPlan plan, {required String planKey}) async {
    final t = aqxL10nOf(context);
    if (_busy) return;
    final rc = RevenueCatService.instance;
    if (!rc.isSdkReady) {
      if (kDebugMode) {
        await _activateLocal(plan, planKey);
      } else {
        _snack(
          t.es
              ? 'Compras no disponibles. Configura RevenueCat.'
              : 'Compras indisponíveis. Configura RevenueCat.',
        );
      }
      return;
    }

    setState(() => _busy = true);
    final before = SubscriptionStore.instance.value.value.plan.name;
    try {
      final offerings = _offerings ?? await rc.getOfferings();
      if (_offerings == null && mounted) setState(() => _offerings = offerings);

      final pkg = RevenueCatService.resolvePackage(offerings, planKey: planKey);
      if (pkg == null) {
        if (kDebugMode) {
          await _activateLocal(plan, planKey);
          return;
        }
        _snack(t.es
            ? 'Paquete no disponible. Configura offering en RevenueCat.'
            : 'Pacote indisponível. Configura offering no RevenueCat.');
        return;
      }

      try {
        await rc.purchasePackage(pkg);
      } on RevenueCatException catch (e) {
        if (e.isUserCancelled) return;
        _snack(e.message);
        return;
      }

      await SubscriptionStore.instance.syncFromRevenueCat();
      final newPlan = SubscriptionStore.instance.value.value.plan;

      setState(() => _committed = true);
      await _trackPlanSelected(planKey);
      await AnalyticsService.instance.track(
        AnalyticsEvents.purchaseSuccess,
        params: {
          'source': widget.source,
          'plan': newPlan.name,
          'plan_key': planKey,
        },
      );
      await AnalyticsService.instance.track(
        AnalyticsEvents.subscriptionChanged,
        params: {
          'from_plan': before,
          'to_plan': newPlan.name,
          'plan_key': planKey,
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _activateLocal(SubscriptionPlan plan, String planKey) async {
    setState(() => _committed = true);
    final before = SubscriptionStore.instance.value.value.plan.name;
    await _trackPlanSelected(planKey);
    await SubscriptionStore.instance.setPlan(plan);
    await AnalyticsService.instance.track(
      AnalyticsEvents.purchaseSuccess,
      params: {'source': widget.source, 'plan': plan.name, 'plan_key': planKey},
    );
    await AnalyticsService.instance.track(
      AnalyticsEvents.subscriptionChanged,
      params: {'from_plan': before, 'to_plan': plan.name, 'plan_key': planKey},
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = aqxL10nOf(context);
    return PopScope(
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop && !_committed) {
          await AnalyticsService.instance.track(
            AnalyticsEvents.paywallDismiss,
            params: {'source': widget.source},
          );
        }
      },
      child: Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kCard,
          elevation: 0,
          title: Text('AQUANAUTIX PRO', style: orb(13, c: kCyan, ls: 1.3)),
        ),
        body: AbsorbPointer(
          absorbing: _busy,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kCyan.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    t.es
                        ? 'Desbloquea decisiones de captura de alto nivel'
                        : 'Desbloqueia decisões de captura de alto nível',
                    style: ibm(12, fw: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kAmber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kAmber.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    t.es ? 'OFERTA ANUAL PRO — MEJOR PRECIO' : 'OFERTA ANUAL PRO — MELHOR PREÇO',
                    style: mono(9, c: kAmber, ls: 0.8),
                  ),
                ),
                const SizedBox(height: 10),
                _plan(
                  context,
                  title: 'PRO — ANUAL',
                  subtitle: t.es ? 'Equiv. ~€3.33/mes vs €4.99 mensual' : 'Equiv. ~€3.33/mês vs €4.99 mensual',
                  price: _priceLabel('pro_annual', '€39.99/ano'),
                  accent: kCyan,
                  highlight: true,
                  onTap: () => _activate(SubscriptionPlan.pro, planKey: 'pro_annual'),
                ),
                const SizedBox(height: 10),
                _plan(
                  context,
                  title: t.es ? 'PRO — MENSUAL' : 'PRO — MENSAL',
                  subtitle: t.es ? 'Flexible, cancela cuando quieras' : 'Flexível, cancela quando quiseres',
                  price: _priceLabel('pro_monthly', '€4.99/mês'),
                  accent: kCyan,
                  highlight: false,
                  onTap: () => _activate(SubscriptionPlan.pro, planKey: 'pro_monthly'),
                ),
                const SizedBox(height: 10),
                _plan(
                  context,
                  title: 'ELITE — ANUAL',
                  subtitle: t.es ? 'Todo ilimitado + ancla de precio' : 'Tudo ilimitado + âncora de preço',
                  price: _priceLabel('elite_annual', '€59.99/ano'),
                  accent: kAmber,
                  highlight: false,
                  onTap: () => _activate(SubscriptionPlan.elite, planKey: 'elite_annual'),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _startTrial,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: kCyan.withValues(alpha: 0.35)),
                      foregroundColor: kCyan,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      t.es ? 'Iniciar trial 3 días (PRO)' : 'Iniciar trial 3 dias (PRO)',
                      style: ibm(13, fw: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: _restorePurchases,
                    child: Text(
                      'Restaurar compras',
                      style: ibm(12, c: kHint),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _plan(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String price,
    required Color accent,
    required bool highlight,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlight ? kCyan : accent.withValues(alpha: 0.35),
            width: highlight ? 2 : 1,
          ),
          boxShadow: highlight
              ? [
                  BoxShadow(
                    color: kCyan.withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: orb(13, c: accent, ls: 1.1)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: ibm(11, c: kHint)),
                  const SizedBox(height: 4),
                  Text(price, style: ibm(13, c: Colors.white, fw: FontWeight.w700)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: kHint),
          ],
        ),
      ),
    );
  }
}
