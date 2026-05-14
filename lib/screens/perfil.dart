import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '_shared.dart';
import 'login_module.dart';
import 'mapa.dart';
import 'paywall.dart';
import '../core/supabase_bootstrap.dart';
import '../core/services/app_insights_service.dart';
import '../core/services/analytics_service.dart';
import '../core/state/fishing_context_store.dart';
import '../core/state/subscription_store.dart';
import '../core/l10n/aqx_l10n.dart';

// ══════════════════════════════════════════════════════════
// P6 — ECRÃ 05 · PERFIL + PLANOS (com ELITE)
// ══════════════════════════════════════════════════════════
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _logoutLoading = false;

  @override
  Widget build(BuildContext context) {
    final t = aqxL10nOf(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar + nome + badge ─────────────────────
          Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A2A4A),
                border: Border.all(color: kCyan.withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(Icons.person_rounded, color: kCyan, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  supabaseCurrentUserEmail ?? (aqxL10nOf(context).es ? 'Pescador' : 'Pescador'),
                  style: ibm(16, fw: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ValueListenableBuilder<SubscriptionState>(
                  valueListenable: SubscriptionStore.instance.value,
                  builder: (context, sub, _) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (sub.isElite ? kAmber : kCyan).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (sub.isElite ? kAmber : kCyan).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(_badgeText(sub), style: mono(9, c: sub.isElite ? kAmber : kCyan, ls: 0.8)),
                  ),
                ),
              ]),
            ),
          ]),

          const SizedBox(height: 14),

          // ── Alert trial — só visível durante trial activo ─
          ValueListenableBuilder<SubscriptionState>(
            valueListenable: SubscriptionStore.instance.value,
            builder: (context, sub, _) {
              if (sub.trialDaysLeft <= 0) return const SizedBox.shrink();
              return Column(children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kCyan.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kCyan.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded, color: kCyan, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.es
                            ? 'El trial termina en ${sub.trialDaysLeft} día(s).\nActiva PRO y no pierdas el Oráculo.'
                            : 'Trial a terminar em ${sub.trialDaysLeft} dia(s).\nGarante o PRO e não percas o Oráculo.',
                        style: ibm(11, c: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _openPaywall('perfil_trial_banner'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: kCyan,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: kCyan.withValues(alpha: 0.4), blurRadius: 8)],
                        ),
                        child: Text('PRO →', style: ibm(11, c: Colors.black, fw: FontWeight.w700)),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
              ]);
            },
          ),

          // ── Stats ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kCyan.withValues(alpha: 0.1)),
            ),
            child: Row(children: [
              _stat('23', t.es ? 'SESIONES' : 'SESSÕES'),
              Container(width: 1, height: 32, color: kCyan.withValues(alpha: 0.1)),
              _stat('41', 'CAPTURAS'),
              Container(width: 1, height: 32, color: kCyan.withValues(alpha: 0.1)),
              _stat('4.2kg', t.es ? 'MAYOR PB' : 'MAIOR PB'),
            ]),
          ),

          const SizedBox(height: 18),
          Text(t.es ? '// PLANES' : '// PLANOS', style: mono(10, ls: 1.2)),
          const SizedBox(height: 10),

          // ── FREE ─────────────────────────────────────
          _planCard(
            nome: 'FREE', preco: '€0', cor: kHint,
            features: const [
              _F(true,  '1 spot · previsão básica'),
              _F(false, 'Oráculo completo'),
              _F(false, 'Alertas push'),
              _F(false, 'IA Assistente'),
            ],
            btnLabel: t.es ? 'PLAN ACTUAL' : 'PLANO ACTUAL',
            btnFilled: false,
            onTap: () async => SubscriptionStore.instance.setPlan(SubscriptionPlan.free),
          ),

          const SizedBox(height: 10),

          // ── PRO ─────────────────────────────────────
          _planCard(
            nome: 'PRO', preco: '€4.99/mês', cor: kCyan,
            features: const [
              _F(true, 'Oráculo completo + dados reais'),
              _F(true, 'Alertas push — Janela de Ouro'),
              _F(true, '5 spots + Ghost Mode'),
              _F(true, 'IA Assistente (50 msg/dia)'),
            ],
            btnLabel: t.es ? 'ACTIVAR PRO' : 'ATIVAR PRO',
            btnFilled: true,
            destaque: t.es ? 'MÁS POPULAR' : 'MAIS POPULAR',
            onTap: () => _openPaywall('perfil_pro'),
          ),

          const SizedBox(height: 10),

          // ── ELITE — P6 âncora de preço ───────────────
          _planCard(
            nome: 'ELITE', preco: '€59.99/ano', cor: kAmber,
            features: const [
              _F(true, 'Tudo do PRO ilimitado'),
              _F(true, 'Spots ilimitados + todos GHOST'),
              _F(true, 'IA sem limites + modo voz'),
              _F(true, 'Exportação CSV · Badge ELITE'),
              _F(true, 'Suporte prioritário'),
            ],
            btnLabel: t.es ? 'ACTIVAR ELITE' : 'ATIVAR ELITE',
            btnFilled: true,
            destaque: '↓ €5.00/mês',
            onTap: () => _openPaywall('perfil_elite'),
          ),
          const SizedBox(height: 18),
          Text('// PAÍS ACTIVO', style: mono(10, ls: 1.2)),
          const SizedBox(height: 10),
          ValueListenableBuilder<FishingContext>(
            valueListenable: FishingContextStore.instance.value,
            builder: (context, fishingCtx, _) {
              final detected = FishingContextStore.instance.detectedCountry();
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kCyan.withValues(alpha: 0.16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.public_rounded, color: kCyan, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.es ? 'Reglas y bloques legales por mercado' : 'Regras e blocos legais por mercado',
                            style: ibm(11, c: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _countryChip(
                          code: 'AUTO',
                          label: 'AUTO',
                          selected: fishingCtx.country == detected,
                          onTap: FishingContextStore.instance.useDeviceCountry,
                        ),
                        const SizedBox(width: 6),
                        _countryChip(
                          code: 'PT',
                          label: '🇵🇹 PT',
                          selected: fishingCtx.country == 'PT',
                          onTap: () => FishingContextStore.instance.update(country: 'PT'),
                        ),
                        const SizedBox(width: 6),
                        _countryChip(
                          code: 'ES',
                          label: '🇪🇸 ES',
                          selected: fishingCtx.country == 'ES',
                          onTap: () => FishingContextStore.instance.update(country: 'ES'),
                        ),
                        const Spacer(),
                        Text('AUTO: $detected', style: mono(8, c: kHint)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Text(t.es ? '// CONFIANZA DE DATOS' : '// CONFIANÇA DE DADOS', style: mono(10, ls: 1.2)),
          const SizedBox(height: 10),
          ValueListenableBuilder<FishingContext>(
            valueListenable: FishingContextStore.instance.value,
            builder: (context, fishingCtx, _) => FutureBuilder<AppInsights>(
              future: AppInsightsService.instance.load(
                country: fishingCtx.country,
                region: fishingCtx.region,
                species: fishingCtx.species,
              ),
              builder: (context, snapshot) {
                final data = snapshot.data ?? AppInsightsService.fallbackData;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kCyan.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.verified_outlined, color: kCyan, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${t.es ? "ORÁCULO · CONFIANZA" : "ORÁCULO · CONFIANÇA"} ${data.confidenceScore}/100',
                          style: mono(10, c: kCyan, ls: 1.0),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Text(data.confidenceDetail, style: ibm(11, c: Colors.white70)),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Text('// MÓDULOS', style: mono(10, ls: 1.2)),
          const SizedBox(height: 10),
          _moduleCard(
            context: context,
            title: t.es ? 'LOGIN Y SINCRONIZACIÓN' : 'LOGIN & SINCRONIZAÇÃO',
            subtitle: t.es ? 'Entrar en la cuenta y sincronizar histórico y misiones' : 'Entrar na conta e sincronizar histórico e missões',
            icon: Icons.login_rounded,
            accent: kAmber,
            destination: const LoginModuleScreen(),
          ),
          const SizedBox(height: 10),
          _moduleCard(
            context: context,
            title: 'MAPA',
            subtitle: t.es
                ? 'Abrir mapa de spots, capas y tiendas cercanas'
                : 'Abrir mapa de spots, camadas e lojas próximas',
            icon: Icons.map_outlined,
            accent: kCyan,
            destination: const MapaModuleScreen(),
          ),
          if (isSupabaseAuthenticated) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _logoutLoading ? null : _logout,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.32)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.45)),
                      ),
                      child: const Icon(Icons.logout_rounded, size: 16, color: Colors.redAccent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.es ? 'CERRAR SESIÓN' : 'TERMINAR SESSÃO', style: orb(11, c: Colors.redAccent, ls: 1.1)),
                          const SizedBox(height: 2),
                          Text(
                            supabaseCurrentUserEmail ?? (t.es ? 'Cuenta autenticada' : 'Conta autenticada'),
                            style: ibm(11, c: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    if (_logoutLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
                        ),
                      )
                    else
                      const Icon(Icons.chevron_right_rounded, color: kHint),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(String val, String label) => Expanded(
        child: Column(children: [
          Text(val, style: orb(18, c: kCyan, fw: FontWeight.w900, ls: 0)),
          const SizedBox(height: 3),
          Text(label, style: mono(9)),
        ]),
      );

  Widget _planCard({
    required String nome, required String preco, required Color cor,
    required List<_F> features, required String btnLabel, required bool btnFilled,
    VoidCallback? onTap,
    String? destaque,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: btnFilled ? cor.withValues(alpha: 0.04) : kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cor.withValues(alpha: btnFilled ? 0.5 : 0.1),
            width: btnFilled ? 1.5 : 1,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(nome, style: orb(14, c: cor, ls: 1.5)),
            if (destaque != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cor.withValues(alpha: 0.4)),
                ),
                child: Text(destaque, style: mono(8, c: cor)),
              ),
            ],
            const Spacer(),
            Text(preco, style: orb(13, c: cor, fw: FontWeight.w900, ls: 0)),
          ]),
          const SizedBox(height: 10),
          ...features.map((f) => _planRow(f.check, f.text, cor)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: btnFilled ? 12 : 10),
              decoration: BoxDecoration(
                color: btnFilled ? cor : cor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                boxShadow: btnFilled
                    ? [BoxShadow(color: cor.withValues(alpha: 0.35), blurRadius: 10)]
                    : null,
                border: btnFilled ? null : Border.all(color: cor.withValues(alpha: 0.25)),
              ),
              child: Center(
                child: Text(
                  btnLabel,
                  style: orb(12, c: btnFilled ? Colors.black : cor, ls: 1.5),
                ),
              ),
            ),
          ),
        ]),
      );

  Widget _planRow(bool check, String text, Color accent) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Icon(
            check ? Icons.check_rounded : Icons.close_rounded,
            size: 14,
            color: check ? accent : kHint.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: ibm(12, c: check ? Colors.white70 : kHint.withValues(alpha: 0.5))),
          ),
        ]),
      );

  Widget _moduleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required Widget destination,
    VoidCallback? onTap,
  }) =>
      GestureDetector(
        onTap: onTap ??
            () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => destination),
              );
            },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.1),
                  border: Border.all(color: accent.withValues(alpha: 0.45)),
                ),
                child: Icon(icon, size: 16, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: orb(11, c: accent, ls: 1.1)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: ibm(11, c: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: kHint),
            ],
          ),
        ),
      );

  Widget _countryChip({
    required String code,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? kCyan.withValues(alpha: 0.12) : kBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? kCyan.withValues(alpha: 0.5) : kCyan.withValues(alpha: 0.16),
            ),
          ),
          child: Text(
            label,
            style: mono(9, c: selected ? kCyan : kHint),
          ),
        ),
      );

  Future<void> _logout() async {
    final t = aqxL10nOf(context);
    if (!isSupabaseConfigured) return;
    final client = supabaseClientOrNull;
    if (client == null) return;

    setState(() => _logoutLoading = true);
    try {
      await client.auth.signOut();
      await SubscriptionStore.instance.setPlan(SubscriptionPlan.free);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.es ? 'Sesión terminada.' : 'Sessão terminada.')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.es ? 'Error al cerrar sesión.' : 'Falha ao terminar sessão.')),
      );
    } finally {
      if (mounted) setState(() => _logoutLoading = false);
    }
  }

  String _badgeText(SubscriptionState sub) {
    final es = aqxL10nOf(context).es;
    if (sub.isElite) return 'ELITE — ACTIVO';
    if (sub.isPro) return 'PRO — ACTIVO';
    if (sub.trialDaysLeft > 0) {
      return es
          ? 'TRIAL — ${sub.trialDaysLeft} DÍAS RESTANTES'
          : 'TRIAL — ${sub.trialDaysLeft} DIAS RESTANTES';
    }
    return 'FREE — ACTIVO';
  }

  Future<void> _openPaywall(String source) async {
    await AnalyticsService.instance.track(
      AnalyticsEvents.moduleOpen,
      params: {'module': 'paywall', 'source': source},
    );
    if (!mounted) return;
    await PaywallScreen.open(context, source: source);
  }
}

class _F {
  final bool check;
  final String text;
  const _F(this.check, this.text);
}
