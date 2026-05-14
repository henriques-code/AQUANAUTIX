import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '_shared.dart';
import '../core/widgets/aquanautix_pins.dart';

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// ONBOARDING v2 — AQUANAUTIX · Apresentação Premium
// 6 slides: Hero · Mapa+Pins · Oráculo · AI · Scanner · CTA
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

const _kOnboardingDoneKey = 'onboarding_done_v2';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  static Future<bool> shouldShow() async {
    final p = await SharedPreferences.getInstance();
    return !(p.getBool(_kOnboardingDoneKey) ?? false);
  }

  static Future<void> markDone() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kOnboardingDoneKey, true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = PageController();
  int _page = 0;
  static const _total = 6;
  late final AnimationController _bgAnim;

  @override
  void initState() {
    super.initState();
    _bgAnim = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
  }

  @override
  void dispose() {
    _bgAnim.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_page < _total - 1) {
      _ctrl.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOutCubic);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    await OnboardingScreen.markDone();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background animado em todas as páginas ────
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (_, __) => CustomPaint(
              painter: _ObBgPainter(t: _bgAnim.value, page: _page),
              size: Size.infinite,
            ),
          ),

          // ── Slides ────────────────────────────────────
          PageView(
            controller: _ctrl,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              _Slide0Hero(onNext: _next),
              _Slide1Pins(onNext: _next),
              _Slide2Oracle(onNext: _next),
              _Slide3AI(onNext: _next),
              _Slide4Scanner(onNext: _next),
              _Slide5Cta(onDone: _finish),
            ],
          ),

          // ── Dots de progresso ─────────────────────────
          if (_page < _total - 1)
            Positioned(
              bottom: h * 0.038,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_total - 1, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 28 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? kCyan : kHint.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: active
                          ? [BoxShadow(color: kCyan.withValues(alpha: 0.6), blurRadius: 10)]
                          : null,
                    ),
                  );
                }),
              ),
            ),

          // ── Skip ──────────────────────────────────────
          if (_page < _total - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 20,
              child: GestureDetector(
                onTap: _finish,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: kCard.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kHint.withValues(alpha: 0.2)),
                  ),
                  child: Text('SKIP', style: mono(10, c: kHint, ls: 1.5)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// BACKGROUND PAINTER — ondas bioluminescentes eléctrizantes
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _ObBgPainter extends CustomPainter {
  const _ObBgPainter({required this.t, required this.page});
  final double t;
  final int page;

  static const _accents = [kCyan, kCyan, kAmber, kCyan, kCyan, kAmber];

  @override
  void paint(Canvas canvas, Size size) {
    final accent = _accents[page.clamp(0, _accents.length - 1)];
    final w = size.width;
    final h = size.height;
    final phase = t * math.pi * 2;

    // ── Gradiente base ────────────────────────────────────
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF071828), kBg, const Color(0xFF000308)],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Offset.zero & size),
    );

    // ── 3 ondas sinusoidais (bioluminescentes) ────────────
    final waveConfigs = [
      (yFrac: 0.22, amp: 18.0, freq: 2.8, phaseOff: 0.0,   alpha: 0.18, thick: 2.5),
      (yFrac: 0.50, amp: 24.0, freq: 2.2, phaseOff: 1.1,   alpha: 0.14, thick: 2.0),
      (yFrac: 0.77, amp: 16.0, freq: 3.1, phaseOff: 2.3,   alpha: 0.12, thick: 1.8),
    ];

    for (final cfg in waveConfigs) {
      final baseY = h * cfg.yFrac;

      // Halo difuso por baixo da onda
      final haloPath = Path();
      haloPath.moveTo(0, baseY + 40);
      for (double x = 0; x <= w; x += 2) {
        final y = baseY + cfg.amp * math.sin(cfg.freq * (x / w) * math.pi * 2 + phase + cfg.phaseOff);
        haloPath.lineTo(x, y + 30);
      }
      haloPath.lineTo(w, h); haloPath.lineTo(0, h); haloPath.close();
      canvas.drawPath(
        haloPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [accent.withValues(alpha: cfg.alpha * 0.35), Colors.transparent],
          ).createShader(Rect.fromLTWH(0, baseY, w, 60)),
      );

      // Linha principal da onda (glow duplo)
      final wavePath = Path();
      bool first = true;
      for (double x = 0; x <= w; x += 1.5) {
        final y = baseY + cfg.amp * math.sin(cfg.freq * (x / w) * math.pi * 2 + phase + cfg.phaseOff);
        if (first) { wavePath.moveTo(x, y); first = false; } else { wavePath.lineTo(x, y); }
      }
      // Halo externo (blur suave)
      canvas.drawPath(wavePath, Paint()
        ..color = accent.withValues(alpha: cfg.alpha * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cfg.thick + 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..strokeCap = StrokeCap.round);
      // Linha central brilhante
      canvas.drawPath(wavePath, Paint()
        ..color = accent.withValues(alpha: cfg.alpha * 1.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cfg.thick
        ..strokeCap = StrokeCap.round);

      // Nós eléctricos nos picos da onda
      for (int n = 0; n < 5; n++) {
        final nx = (n / 4) * w;
        final ny = baseY + cfg.amp * math.sin(cfg.freq * (nx / w) * math.pi * 2 + phase + cfg.phaseOff);
        final pulse = 0.5 + 0.5 * math.sin(phase * 3 + n * 1.2);
        final nodeAlpha = cfg.alpha * 0.6 + pulse * cfg.alpha * 0.8;
        canvas.drawCircle(Offset(nx, ny), 2.5 + pulse * 1.5,
            Paint()..color = accent.withValues(alpha: nodeAlpha.clamp(0, 1))..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        canvas.drawCircle(Offset(nx, ny), 1.2,
            Paint()..color = Colors.white.withValues(alpha: (pulse * 0.6).clamp(0, 1)));
      }
    }

    // ── Partículas flutuantes ─────────────────────────────
    final rnd = math.Random(42);
    for (int i = 0; i < 22; i++) {
      final bx = rnd.nextDouble() * w;
      final by = rnd.nextDouble() * h;
      final drift = math.sin(phase + i * 0.9) * 6;
      final rise = -((t + i * 0.055) % 1.0) * h * 0.10;
      final px = (bx + drift + w) % w;
      final py = (by + rise + h) % h;
      final alpha = 0.04 + rnd.nextDouble() * 0.10;
      final r = 0.7 + rnd.nextDouble() * 1.2;
      canvas.drawCircle(Offset(px, py), r,
          Paint()..color = accent.withValues(alpha: alpha)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
    }

    // ── Glow central radial ───────────────────────────────
    canvas.drawCircle(
      Offset(w / 2, h * 0.40), w * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [accent.withValues(alpha: 0.05), Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(w / 2, h * 0.40), radius: w * 0.55)),
    );
  }

  @override
  bool shouldRepaint(_ObBgPainter old) => old.t != t || old.page != page;
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// SLIDE 0 — HERO AQUANAUTIX
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _Slide0Hero extends StatelessWidget {
  const _Slide0Hero({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // Logo
            CustomPaint(size: const Size(160, 160), painter: const _ObLogoPainter())
                .animate()
                .scale(begin: const Offset(0.1, 0.1), end: const Offset(1, 1), duration: 900.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 28),

            // Nome
            Text('AQUANAUTIX', style: orb(36, c: kCyan, fw: FontWeight.w900, ls: 5))
                .animate(delay: 350.ms)
                .slideY(begin: 0.6, end: 0, duration: 600.ms, curve: Curves.easeOutCubic)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 10),

            // Linha divisória glowing
            Container(
              height: 1,
              width: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, kCyan, Colors.transparent],
                ),
                boxShadow: [BoxShadow(color: kCyan.withValues(alpha: 0.5), blurRadius: 8)],
              ),
            ).animate(delay: 500.ms).scaleX(begin: 0, end: 1, duration: 500.ms, curve: Curves.easeOut),

            const SizedBox(height: 14),

            // Tagline
            Text(
              'O INSTRUMENTO QUE\nMUDA TUDO',
              style: orb(18, c: Colors.white, fw: FontWeight.w700, ls: 1),
              textAlign: TextAlign.center,
            ).animate(delay: 550.ms).slideY(begin: 0.4, end: 0, duration: 500.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: 14),

            Text(
              'Oráculo · IA · Vision · Spots Secretos',
              style: mono(11, c: kHint, ls: 1.2),
              textAlign: TextAlign.center,
            ).animate(delay: 750.ms).fadeIn(duration: 600.ms),

            const Spacer(flex: 2),

            // Badges PT/ES
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['🇵🇹 PT', '🇪🇸 ES', '🇬🇧 EN'].map((l) =>
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: kCyan.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kCyan.withValues(alpha: 0.25)),
                  ),
                  child: Text(l, style: mono(10, c: kCyan)),
                ),
              ).toList(),
            ).animate(delay: 900.ms).fadeIn(duration: 500.ms),

            const Spacer(),

            _ObNextBtn(label: 'DESCOBRIR  →', onTap: onNext, filled: true)
                .animate(delay: 1100.ms)
                .slideY(begin: 1.2, end: 0, duration: 600.ms, curve: Curves.easeOutCubic)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 72),
          ],
        ),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// SLIDE 1 — MAPA + PINS TEARDROP (os aprovados)
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _Slide1Pins extends StatelessWidget {
  const _Slide1Pins({required this.onNext});
  final VoidCallback onNext;

  static const _pinData = [
    (painter: AqxPinFree(), label: 'FREE', sub: 'Spots abertos', color: aqxPinCyan),
    (painter: AqxPinPro(), label: 'PRO', sub: 'Spots curados', color: aqxPinBlue),
    (painter: AqxPinElite(), label: 'ELITE', sub: 'Spots secretos', color: aqxPinAmber),
    (painter: AqxPinSaved(), label: 'SAVED', sub: 'Os teus spots', color: aqxPinRed),
    (painter: AqxPinBait(), label: 'LOJA', sub: 'Iscos perto', color: aqxPinGreen),
    (painter: AqxPinCommunity(), label: 'COMUNIDADE', sub: 'Ghost Mode · anónimo', color: aqxPinCyan),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Header
          _ObTag(label: 'MAPA INTELIGENTE', color: kCyan),
          const SizedBox(height: 10),
          Text('OS MELHORES SPOTS\nGUARDADOS POR NÓS',
            style: orb(22, fw: FontWeight.w800, ls: 0.5), textAlign: TextAlign.center,
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: 4),
          Text('Portugal + Espanha · Costa + Rios',
            style: mono(11, c: kHint), textAlign: TextAlign.center,
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          // Pins em grelha 2-1-2-1
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  // Linha 1: FREE + PRO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PinWithLabel(data: _pinData[0], delay: 0),
                      const SizedBox(width: 28),
                      _PinWithLabel(data: _pinData[1], delay: 150),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Linha 2: ELITE (centro, destaque)
                  _PinWithLabel(data: _pinData[2], delay: 300),
                  const SizedBox(height: 14),
                  // Linha 3: SAVED + BAIT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PinWithLabel(data: _pinData[3], delay: 450),
                      const SizedBox(width: 28),
                      _PinWithLabel(data: _pinData[4], delay: 600),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Linha 4: COMUNIDADE (centro, slot foto do pescador)
                  _PinWithLabel(data: _pinData[5], delay: 750),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 72),
            child: _ObNextBtn(label: 'PRÓXIMO  →', onTap: onNext),
          ),
        ],
      ),
    );
  }
}

class _PinWithLabel extends StatelessWidget {
  const _PinWithLabel({required this.data, required this.delay});
  final ({CustomPainter painter, String label, String sub, Color color}) data;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomPaint(size: const Size(80, 95), painter: data.painter)
            .animate(delay: Duration(milliseconds: delay))
            .slideY(begin: -3, end: 0, duration: 700.ms, curve: Curves.elasticOut)
            .fadeIn(duration: 300.ms),
        const SizedBox(height: 6),
        Text(data.label, style: mono(10, c: data.color, ls: 1))
            .animate(delay: Duration(milliseconds: delay + 200))
            .fadeIn(duration: 300.ms),
        Text(data.sub, style: ibm(9, c: kHint))
            .animate(delay: Duration(milliseconds: delay + 300))
            .fadeIn(duration: 300.ms),
      ],
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// SLIDE 2 — ORÁCULO
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _Slide2Oracle extends StatelessWidget {
  const _Slide2Oracle({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _ObFeatureSlide(
      tag: 'ORÁCULO DE PESCA',
      tagColor: kAmber,
      title: 'SABE EXACTAMENTE\nQUANDO PESCAR',
      subtitle: 'Score 0–100 · Marés · Solunar · GPS',
      painter: const _ObOracleDisk(),
      iconSize: 190,
      lines: const [
        '⏱  Janela de Ouro — a hora certa, ao minuto',
        '🌊  Modo COSTA + RIO com dados reais',
        '🎣  Isco + cana + técnica por espécie e spot',
      ],
      accentColor: kAmber,
      onNext: onNext,
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// SLIDE 3 — AQUANAUTIX AI
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _Slide3AI extends StatelessWidget {
  const _Slide3AI({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _ObFeatureSlide(
      tag: 'AQUANAUTIX AI',
      tagColor: kCyan,
      title: 'PERGUNTA TUDO.\nELE RESPONDE.',
      subtitle: 'Contexto total. Sem precedentes na pesca.',
      painter: const _ObAIHex(),
      iconSize: 180,
      lines: const [
        '🤖  "Que isco uso agora?" — resposta em 2s',
        '📸  Analisa foto da captura e dá feedback',
        '🎙  Modo voz — funciona sem tirar as luvas',
      ],
      accentColor: kCyan,
      onNext: onNext,
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// SLIDE 4 — VISION SCANNER (foto real: mãos do pescador)
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _Slide4Scanner extends StatelessWidget {
  const _Slide4Scanner({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                children: [
                  _ObTag(label: 'VISION SCANNER', color: kCyan),
                  const SizedBox(height: 14),

                  // Viewfinder com foto real
                  _ScannerWithPhoto(),

                  const SizedBox(height: 18),

                  // Espécie + métricas
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Robalo · Dicentrarchus labrax',
                      style: GoogleFonts.orbitron(fontSize: 18, color: kCyan, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                      textAlign: TextAlign.center,
                    ),
                  ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: 6),

                  Text('≈ 3.1 kg  ·  58 cm',
                    style: GoogleFonts.shareTechMono(fontSize: 16, color: kAmber, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                  ).animate(delay: 400.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00C853).withValues(alpha: 0.55)),
                    ),
                    child: Text('✅  LEGAL PT · Min 36cm',
                      style: GoogleFonts.shareTechMono(fontSize: 10, color: const Color(0xFF00C853), letterSpacing: 0.5)),
                  ).animate(delay: 500.ms).fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),

                  const SizedBox(height: 18),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('APONTA. IDENTIFICA. REGISTA.',
                      style: GoogleFonts.orbitron(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                      textAlign: TextAlign.center,
                    ),
                  ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 16),

                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.transparent, kCyan, Colors.transparent]),
                    ),
                  ).animate(delay: 450.ms).scaleX(begin: 0, end: 1, duration: 400.ms),

                  const SizedBox(height: 16),

                  ...[
                    'Identificação instantânea com IA avançada',
                    'Regras e tamanhos sempre actualizados',
                    'Regista e acompanha as tuas capturas',
                  ].asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5, right: 10),
                        width: 5, height: 5,
                        decoration: BoxDecoration(color: kCyan, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: kCyan.withValues(alpha: 0.6), blurRadius: 6)]),
                      ),
                      Expanded(child: Text(e.value,
                        style: GoogleFonts.ibmPlexSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.85)))),
                    ]),
                  ).animate(delay: Duration(milliseconds: 550 + e.key * 120))
                    .slideX(begin: -0.25, end: 0, duration: 400.ms, curve: Curves.easeOut)
                    .fadeIn(duration: 300.ms)),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 68),
            child: _ObNextBtn(label: 'PRÓXIMO  →', onTap: onNext),
          ),
        ],
      ),
    );
  }
}

class _ScannerWithPhoto extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          // Foto real com clip arredondado
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/robalo_scanner.png',
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // Overlay escuro nas bordas
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, kBg.withValues(alpha: 0.35)],
                ),
              ),
            ),
          ),

          // Viewfinder overlay (cantos + barra lateral)
          CustomPaint(
            size: const Size(double.infinity, 220),
            painter: _ScanOverlayPainter(),
          ),

          // Linha de scan animada (loop vertical)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.transparent, kCyan, Colors.transparent]),
                      boxShadow: [BoxShadow(color: kCyan.withValues(alpha: 0.7), blurRadius: 14, spreadRadius: 1)],
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: 12, end: 196, duration: 2400.ms, curve: Curves.easeInOut),
                ),
              ),
            ),
          ),

          // Percentagem + mini equalizer no canto superior direito
          Positioned(
            top: 10, right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('92%',
                  style: GoogleFonts.shareTechMono(fontSize: 18, color: kCyan, fontWeight: FontWeight.w700,
                    shadows: [Shadow(color: kCyan.withValues(alpha: 0.85), blurRadius: 10)])),
                const SizedBox(height: 4),
                _ConfidenceEqualizer(),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.3, end: 0, duration: 700.ms, curve: Curves.easeOutCubic);
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final cP = Paint()..color = kCyan..strokeWidth = 3.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    const p = 16.0; const cl = 22.0;
    // Cantos
    canvas.drawLine(Offset(p, p + cl), Offset(p, p), cP); canvas.drawLine(Offset(p, p), Offset(p + cl, p), cP);
    canvas.drawLine(Offset(w - p - cl, p), Offset(w - p, p), cP); canvas.drawLine(Offset(w - p, p), Offset(w - p, p + cl), cP);
    canvas.drawLine(Offset(p, h - p - cl), Offset(p, h - p), cP); canvas.drawLine(Offset(p, h - p), Offset(p + cl, h - p), cP);
    canvas.drawLine(Offset(w - p - cl, h - p), Offset(w - p, h - p), cP); canvas.drawLine(Offset(w - p, h - p), Offset(w - p, h - p - cl), cP);
    // Barra de progresso lateral direita
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w - 10, p + 20, 3, h - p * 2 - 20), const Radius.circular(2)),
        Paint()..color = kCyan.withValues(alpha: 0.15));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w - 10, p + 20, 3, (h - p * 2 - 20) * 0.92), const Radius.circular(2)),
        Paint()..color = kCyan);
  }
  @override
  bool shouldRepaint(_) => false;
}

class _ConfidenceEqualizer extends StatelessWidget {
  static const _bars = 12;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_bars, (i) {
        return Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Container(
            width: 2, height: 8,
            decoration: BoxDecoration(
              color: kCyan,
              borderRadius: BorderRadius.circular(1),
              boxShadow: [BoxShadow(color: kCyan.withValues(alpha: 0.5), blurRadius: 4)],
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true), delay: Duration(milliseconds: i * 90))
            .fadeIn(begin: 0.25, duration: 700.ms, curve: Curves.easeInOut),
        );
      }),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// SLIDE 5 — CTA PREMIUM
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _Slide5Cta extends StatelessWidget {
  const _Slide5Cta({required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: Column(
          children: [
            // Logo pequeno
            CustomPaint(size: const Size(60, 60), painter: const _ObLogoPainter())
                .animate().scale(begin: const Offset(0.3, 0.3), duration: 600.ms, curve: Curves.elasticOut),

            const SizedBox(height: 16),

            Text('PRONTO PARA\nPESCAR MELHOR?',
              style: orb(26, c: Colors.white, fw: FontWeight.w900, ls: 0), textAlign: TextAlign.center,
            ).animate(delay: 200.ms).slideY(begin: 0.4, end: 0, duration: 500.ms).fadeIn(),

            const SizedBox(height: 6),

            Text('3 dias PRO incluídos. Sem cartão de crédito.',
              style: ibm(13, c: kHint), textAlign: TextAlign.center,
            ).animate(delay: 350.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            // Cards FREE vs PRO
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _CtaPlanCard(
                  plan: 'FREE',
                  price: '€0',
                  color: kHint,
                  items: const ['Mapa básico', '3 dias PRO grátis', 'Scanner 5×/mês'],
                )),
                const SizedBox(width: 12),
                Expanded(child: _CtaPlanCard(
                  plan: 'PRO',
                  price: '€4.99/mês',
                  color: kCyan,
                  featured: true,
                  items: const ['Todos os spots', 'Oráculo ilimitado', 'AQUANAUTIX AI', 'Scanner ilimitado', 'Alertas push'],
                )),
              ],
            ).animate(delay: 450.ms).slideY(begin: 0.3, end: 0, duration: 500.ms).fadeIn(),

            const SizedBox(height: 26),

            // Linha glowing
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, kCyan, Colors.transparent]),
              ),
            ).animate(delay: 600.ms).scaleX(begin: 0, end: 1, duration: 500.ms),

            const SizedBox(height: 24),

            // Botão CTA principal
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: kCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: onDone,
                child: Text('COMEÇAR AGORA  →', style: orb(13, c: Colors.black, fw: FontWeight.w900, ls: 1.5)),
              ),
            ).animate(delay: 700.ms)
              .slideY(begin: 0.8, end: 0, duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 400.ms),

            const SizedBox(height: 12),

            GestureDetector(
              onTap: onDone,
              child: Text('Continuar com FREE por agora', style: ibm(12, c: kHint)),
            ).animate(delay: 950.ms).fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// COMPONENTES PARTILHADOS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _ObFeatureSlide extends StatelessWidget {
  const _ObFeatureSlide({
    required this.tag,
    required this.tagColor,
    required this.title,
    required this.subtitle,
    required this.painter,
    required this.iconSize,
    required this.lines,
    required this.accentColor,
    required this.onNext,
  });

  final String tag;
  final Color tagColor;
  final String title;
  final String subtitle;
  final CustomPainter painter;
  final double iconSize;
  final List<String> lines;
  final Color accentColor;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
              child: Column(
                children: [
                  _ObTag(label: tag, color: tagColor),
                  const SizedBox(height: 10),

                  // Ícone hero a cair do topo
                  CustomPaint(
                    size: Size(iconSize, iconSize),
                    painter: painter,
                  )
                      .animate()
                      .slideY(begin: -1.8, end: 0, duration: 800.ms, curve: Curves.elasticOut)
                      .fadeIn(duration: 350.ms),

                  const SizedBox(height: 22),

                  Text(title,
                    style: orb(24, fw: FontWeight.w800, ls: 0), textAlign: TextAlign.center,
                  ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 6),

                  Text(subtitle,
                    style: ibm(13, c: kHint), textAlign: TextAlign.center,
                  ).animate(delay: 350.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: 22),

                  // Linha divisória
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.transparent, accentColor.withValues(alpha: 0.4), Colors.transparent]),
                    ),
                  ).animate(delay: 400.ms).scaleX(begin: 0, end: 1, duration: 400.ms),

                  const SizedBox(height: 20),

                  // Linhas de copy impacto
                  ...lines.asMap().entries.map((e) {
                    final i = e.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 5, right: 10),
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.6), blurRadius: 6)],
                            ),
                          ),
                          Expanded(child: Text(e.value, style: ibm(13, c: Colors.white.withValues(alpha: 0.85)))),
                        ],
                      ),
                    ).animate(delay: Duration(milliseconds: 500 + i * 120))
                      .slideX(begin: -0.25, end: 0, duration: 400.ms, curve: Curves.easeOut)
                      .fadeIn(duration: 300.ms);
                  }),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 68),
            child: _ObNextBtn(label: 'PRÓXIMO  →', onTap: onNext),
          ),
        ],
      ),
    );
  }
}

class _ObTag extends StatelessWidget {
  const _ObTag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 12)],
      ),
      child: Text(label, style: mono(10, c: color, ls: 2)),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _ObNextBtn extends StatelessWidget {
  const _ObNextBtn({required this.label, required this.onTap, this.filled = false});
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: kCyan,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: onTap,
          child: Text(label, style: orb(12, c: Colors.black, fw: FontWeight.w900, ls: 1.5)),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: kCyan,
          side: BorderSide(color: kCyan.withValues(alpha: 0.45)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onTap,
        child: Text(label, style: orb(12, c: kCyan, ls: 1.5)),
      ),
    );
  }
}

class _CtaPlanCard extends StatelessWidget {
  const _CtaPlanCard({
    required this.plan, required this.price, required this.color,
    required this.items, this.featured = false,
  });
  final String plan;
  final String price;
  final Color color;
  final List<String> items;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: featured ? kCyan.withValues(alpha: 0.07) : kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: featured ? kCyan.withValues(alpha: 0.55) : kHint.withValues(alpha: 0.18), width: featured ? 1.5 : 1),
        boxShadow: featured ? [BoxShadow(color: kCyan.withValues(alpha: 0.12), blurRadius: 20)] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (featured)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: kCyan.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(4)),
              child: Text('POPULAR', style: mono(7, c: kCyan)),
            ),
          Text(plan, style: orb(15, c: color, fw: FontWeight.w900, ls: 0)),
          Text(price, style: ibm(11, c: color.withValues(alpha: 0.65))),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(children: [
              Icon(Icons.check_circle_rounded, size: 12, color: color.withValues(alpha: 0.7)),
              const SizedBox(width: 5),
              Expanded(child: Text(item, style: ibm(10, c: Colors.white60))),
            ]),
          )),
        ],
      ),
    );
  }
}

// Pins: AqxPinFree/Pro/Elite/Saved/Bait/Community → aquanautix_pins.dart


// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// FEATURE PAINTERS — Oráculo, AI, Scanner
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

// ── Logo mark (Hero + CTA) ───────────────────────────────
class _ObLogoPainter extends CustomPainter {
  const _ObLogoPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2;
    final r = size.width / 2 - 6;
    canvas.drawCircle(Offset(cx, cy), r + 10, Paint()..color = kCyan.withValues(alpha: 0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = kCyan..style = PaintingStyle.stroke..strokeWidth = 2.5);
    canvas.drawCircle(Offset(cx, cy), r * 0.72, Paint()..color = kCyan.withValues(alpha: 0.25)..style = PaintingStyle.stroke..strokeWidth = 1);
    final fin = Path()
      ..moveTo(cx - 24, cy + 18)..quadraticBezierTo(cx - 18, cy - 26, cx + 2, cy - 36)
      ..quadraticBezierTo(cx + 18, cy - 8, cx + 24, cy + 18)
      ..quadraticBezierTo(cx + 6, cy + 10, cx, cy + 14)..quadraticBezierTo(cx - 10, cy + 10, cx - 24, cy + 18)..close();
    canvas.drawPath(fin, Paint()..color = kCyan);
    final wP = Paint()..color = kCyan.withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(cx - 26, cy + 30)..quadraticBezierTo(cx - 12, cy + 24, cx, cy + 30)..quadraticBezierTo(cx + 12, cy + 36, cx + 26, cy + 30), wP);
    for (int i = 0; i < 12; i++) {
      final angle = (math.pi / 6) * i - math.pi / 2;
      final isMajor = i % 3 == 0;
      final inner = r * (isMajor ? 0.82 : 0.88);
      canvas.drawLine(
        Offset(cx + inner * math.cos(angle), cy + inner * math.sin(angle)),
        Offset(cx + r * 0.96 * math.cos(angle), cy + r * 0.96 * math.sin(angle)),
        Paint()..color = kCyan.withValues(alpha: isMajor ? 0.8 : 0.3)..strokeWidth = isMajor ? 2 : 1,
      );
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ── Disco do Oráculo ─────────────────────────────────────
class _ObOracleDisk extends CustomPainter {
  const _ObOracleDisk();
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2;
    final r = size.width / 2 - 8;
    canvas.drawCircle(Offset(cx, cy), r + 12, Paint()..color = kAmber.withValues(alpha: 0.22)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = const Color(0xFF1A0F00));
    canvas.drawCircle(Offset(cx, cy), r * 0.9, Paint()..color = kAmber.withValues(alpha: 0.12)..style = PaintingStyle.stroke..strokeWidth = 8);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.9), -math.pi / 2, 2 * math.pi * 0.84, false,
        Paint()..color = kAmber..style = PaintingStyle.stroke..strokeWidth = 8..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = kAmber.withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 2);
    for (int i = 0; i < 12; i++) {
      final angle = (math.pi / 6) * i - math.pi / 2;
      final isMajor = i % 3 == 0;
      final inner = r * (isMajor ? 0.82 : 0.88);
      canvas.drawLine(
        Offset(cx + inner * math.cos(angle), cy + inner * math.sin(angle)),
        Offset(cx + r * 0.97 * math.cos(angle), cy + r * 0.97 * math.sin(angle)),
        Paint()..color = kAmber.withValues(alpha: isMajor ? 0.7 : 0.3)..strokeWidth = isMajor ? 2 : 1,
      );
    }
    final tp = TextPainter(
      text: TextSpan(text: '84', style: GoogleFonts.orbitron(fontSize: size.width * 0.22, fontWeight: FontWeight.w900, color: kAmber, shadows: [Shadow(color: kAmber.withValues(alpha: 0.7), blurRadius: 16)])),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2 - size.height * 0.06));
    final tp2 = TextPainter(
      text: TextSpan(text: 'SCORE', style: GoogleFonts.shareTechMono(fontSize: size.width * 0.07, color: kAmber.withValues(alpha: 0.65), letterSpacing: 1.5)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, cy + size.height * 0.11));
    // Lua
    final mCx = cx + r * 0.52; final mCy = cy - r * 0.52;
    canvas.drawCircle(Offset(mCx, mCy), 11, Paint()..color = kAmber.withValues(alpha: 0.85));
    canvas.drawCircle(Offset(mCx + 5, mCy - 3), 9, Paint()..color = const Color(0xFF1A0F00));
    // Onda
    canvas.drawPath(
      Path()..moveTo(cx - r * 0.48, cy + r * 0.55)..quadraticBezierTo(cx - r * 0.12, cy + r * 0.42, cx, cy + r * 0.55)..quadraticBezierTo(cx + r * 0.12, cy + r * 0.68, cx + r * 0.48, cy + r * 0.55),
      Paint()..color = kAmber.withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeCap = StrokeCap.round,
    );
  }
  @override
  bool shouldRepaint(_) => false;
}

// ── Hexágono AI ──────────────────────────────────────────
class _ObAIHex extends CustomPainter {
  const _ObAIHex();
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2;
    final r = size.width / 2 - 6;
    canvas.drawCircle(Offset(cx, cy), r + 12, Paint()..color = kCyan.withValues(alpha: 0.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
    final hex = Path();
    for (int i = 0; i < 6; i++) {
      final a = -math.pi / 2 + i * math.pi / 3;
      final x = cx + r * math.cos(a); final y = cy + r * math.sin(a);
      if (i == 0) { hex.moveTo(x, y); } else { hex.lineTo(x, y); }
    }
    hex.close();
    canvas.drawPath(hex, Paint()..color = const Color(0xFF051C2E));
    canvas.drawPath(hex, Paint()..color = kCyan..style = PaintingStyle.stroke..strokeWidth = 2.5);
    final nodeR = r * 0.45;
    final nodes = <Offset>[Offset(cx, cy)];
    for (int i = 0; i < 6; i++) {
      final a = -math.pi / 2 + i * math.pi / 3;
      nodes.add(Offset(cx + nodeR * math.cos(a), cy + nodeR * math.sin(a)));
    }
    final lineP = Paint()..strokeWidth = 1.2;
    for (int i = 1; i < nodes.length; i++) {
      lineP.color = kCyan.withValues(alpha: 0.3);
      canvas.drawLine(nodes[0], nodes[i], lineP);
    }
    for (int i = 1; i < nodes.length; i++) {
      lineP.color = kCyan.withValues(alpha: 0.15);
      canvas.drawLine(nodes[i], nodes[i % 6 + 1], lineP);
    }
    for (int i = 0; i < nodes.length; i++) {
      final dr = i == 0 ? 6.5 : 3.5;
      canvas.drawCircle(nodes[i], dr + 3, Paint()..color = kCyan.withValues(alpha: 0.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawCircle(nodes[i], dr, Paint()..color = kCyan);
    }
    final aiTp = TextPainter(
      text: TextSpan(text: 'AI', style: GoogleFonts.orbitron(fontSize: size.width * 0.16, fontWeight: FontWeight.w900, color: const Color(0xFF051C2E), letterSpacing: 3)),
      textDirection: TextDirection.ltr,
    )..layout();
    aiTp.paint(canvas, Offset(cx - aiTp.width / 2, cy - aiTp.height / 2));
    final innerHex = Path();
    for (int i = 0; i < 6; i++) {
      final a = -math.pi / 2 + i * math.pi / 3;
      final x = cx + r * 0.22 * math.cos(a); final y = cy + r * 0.22 * math.sin(a);
      if (i == 0) { innerHex.moveTo(x, y); } else { innerHex.lineTo(x, y); }
    }
    innerHex.close();
    canvas.drawPath(innerHex, Paint()..color = kCyan.withValues(alpha: 0.25)..style = PaintingStyle.stroke..strokeWidth = 1);
  }
  @override
  bool shouldRepaint(_) => false;
}

