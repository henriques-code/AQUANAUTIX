import 'dart:ui';

import 'package:flutter/material.dart';

import '../_shared.dart';
import '../paywall.dart';
import '../../core/state/subscription_store.dart';

/// Copy da linha de decisão (fold Oráculo).
class OracleDecisionCopy {
  OracleDecisionCopy._();

  static String? _windowEnd(String windowHours) {
    final parts = windowHours.split('→');
    if (parts.length < 2) return null;
    return parts.last.trim();
  }

  static String line({
    required bool es,
    required int score,
    required String windowHours,
    required int proScore,
    required bool loading,
    String nextHour = '07:00',
  }) {
    if (loading) return es ? 'A calcular condiciones…' : 'A calcular condições…';
    final end = _windowEnd(windowHours);
    if (score >= 65 && end != null) {
      return es
          ? 'Vale ir ahora — ventana cierra a las $end'
          : 'Vale ir pescar agora — janela fecha às $end';
    }
    if (proScore > score + 4) {
      return es
          ? 'Débil ahora — mejor mañana $nextHour (Score $proScore con PRO)'
          : 'Fraco agora — melhor amanhã $nextHour (Score $proScore com PRO)';
    }
    if (windowHours.isNotEmpty && windowHours != '—') {
      return es
          ? 'Condiciones moderadas — ventana $windowHours'
          : 'Condições moderadas — janela $windowHours';
    }
    return es ? 'Consulta el mapa y registra capturas.' : 'Consulta o mapa e regista capturas.';
  }
}

/// Frase única de decisão — abaixo do hero.
class OracleDecisionLine extends StatelessWidget {
  const OracleDecisionLine({
    super.key,
    required this.text,
    required this.loading,
  });

  final String text;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            loading ? Icons.hourglass_top_rounded : Icons.bolt_rounded,
            size: 18,
            color: kCyan,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: ibm(13, c: Colors.white, fw: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Faixa PRO compacta — visível antes dos chips de espécie.
class OracleProStickyStrip extends StatelessWidget {
  const OracleProStickyStrip({
    super.key,
    required this.summary,
    required this.onTap,
  });

  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SubscriptionState>(
      valueListenable: SubscriptionStore.instance.value,
      builder: (context, sub, _) {
        if (sub.hasProEntitlement) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Material(
            color: kCard,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kAmber.withValues(alpha: 0.45)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_rounded, size: 16, color: kAmber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        summary,
                        style: ibm(12, c: Colors.white, fw: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PRO →',
                      style: ibm(11, c: kAmber, fw: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Drawer FOMO — spot PRO + trial + paywall.
Future<void> showOracleProUnlockSheet(
  BuildContext context, {
  required String distanceLabel,
  required String scoreLine,
  required String speciesLabel,
  required String source,
  bool es = false,
}) async {
  final sub = SubscriptionStore.instance.value.value;
  if (sub.hasProEntitlement) return;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: kCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kHint.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                es ? 'Spot PRO bloqueado' : 'Spot PRO bloqueado',
                style: orb(16, c: kCyan, fw: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 100,
                      width: double.infinity,
                      color: kBg,
                      child: Icon(Icons.map_outlined,
                          size: 48, color: kHint.withValues(alpha: 0.25)),
                    ),
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(
                        height: 100,
                        color: kBg.withValues(alpha: 0.35),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, color: kAmber, size: 28),
                        const SizedBox(height: 4),
                        Text(
                          distanceLabel,
                          style: ibm(12, c: Colors.white, fw: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '$speciesLabel · $scoreLine',
                style: ibm(13, c: kHint),
              ),
              const SizedBox(height: 12),
              _benefit(es, es ? 'Alertas de ventana de oro' : 'Alertas de janela de ouro'),
              _benefit(es, es ? 'Spots PRO + mapa sin blur' : 'Spots PRO + mapa sem blur'),
              _benefit(es, es ? 'Comparar 3 sitios de pesca' : 'Comparar 3 sítios de pesca'),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    PaywallScreen.open(context, source: source);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: kAmber,
                    foregroundColor: kBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    es ? 'PRO 3 días gratis →' : 'PRO 3 dias grátis →',
                    style: ibm(14, c: kBg, fw: FontWeight.w800),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  es ? 'Ahora no' : 'Agora não',
                  style: ibm(13, c: kHint),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _benefit(bool es, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_outline, size: 16, color: kCyan),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: ibm(12, c: Colors.white))),
      ],
    ),
  );
}
