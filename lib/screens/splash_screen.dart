import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home.dart';
import 'onboarding.dart';

// ══════════════════════════════════════════════════════════
// ECRÃ INICIAL — AQUANAUTIX vem do fundo do mar
// ══════════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // Oceano ambiente — loop infinito
  late final AnimationController _ocean;

  // Título emerge das profundezas
  late final AnimationController _emerge;

  late final Animation<double> _titleScale;   // 0.02 → 1.0
  late final Animation<double> _titleY;       // 380 → 0  (slide de baixo para cima)
  late final Animation<double> _titleOpacity; // 0 → 1
  late final Animation<double> _glowRadius;   // 0 → 40
  late final Animation<double> _taglineOp;    // 0 → 1  (após título)
  late final Animation<double> _dotOp;        // 0 → 1  (loading dot)

  @override
  void initState() {
    super.initState();

    _ocean = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _emerge = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Título: sobe do fundo e cresce
    _titleScale = Tween<double>(begin: 0.04, end: 1.0).animate(
      CurvedAnimation(parent: _emerge,
          curve: const Interval(0.0, 0.72, curve: Curves.easeOutCubic)));

    _titleY = Tween<double>(begin: 380.0, end: 0.0).animate(
      CurvedAnimation(parent: _emerge,
          curve: const Interval(0.0, 0.72, curve: Curves.easeOutCubic)));

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _emerge,
          curve: const Interval(0.0, 0.35, curve: Curves.easeOut)));

    _glowRadius = Tween<double>(begin: 0.0, end: 42.0).animate(
      CurvedAnimation(parent: _emerge,
          curve: const Interval(0.2, 0.8, curve: Curves.easeOut)));

    _taglineOp = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _emerge,
          curve: const Interval(0.68, 0.92, curve: Curves.easeOut)));

    _dotOp = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _emerge,
          curve: const Interval(0.85, 1.0, curve: Curves.easeOut)));

    // Inicia animação de emersão com pequeno delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _emerge.forward();
    });

    // Navega para onboarding (1ª vez) ou home directamente após 3.8 s
    Future.delayed(const Duration(milliseconds: 3800), () async {
      if (!mounted) return;
      final showOnboarding = await OnboardingScreen.shouldShow();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => showOnboarding
              ? OnboardingScreen(onDone: () => Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const AquanautixHome(),
                      transitionDuration: const Duration(milliseconds: 500),
                      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
                    ),
                  ))
              : const AquanautixHome(),
          transitionDuration: const Duration(milliseconds: 700),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: child,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ocean.dispose();
    _emerge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000814),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Oceano animado ──────────────────────────
          AnimatedBuilder(
            animation: _ocean,
            builder: (_, __) => CustomPaint(
              painter: _OceanPainter(t: _ocean.value),
              size: Size.infinite,
            ),
          ),

          // ── Título + tagline ─────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: _emerge,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _titleY.value),
                child: Transform.scale(
                  scale: _titleScale.value,
                  child: Opacity(
                    opacity: _titleOpacity.value.clamp(0.0, 1.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Título com glow ciano
                        _buildTitle(),
                        const SizedBox(height: 12),
                        // Tagline
                        Opacity(
                          opacity: _taglineOp.value.clamp(0.0, 1.0),
                          child: Text(
                            'INSTRUMENTO DE PESCA DE ELITE',
                            style: GoogleFonts.shareTechMono(
                              fontSize: 11,
                              color: const Color(0xFF8AADBE),
                              letterSpacing: 2.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Opacity(
                          opacity: _taglineOp.value.clamp(0.0, 1.0),
                          child: Text(
                            'PT · EN · ES',
                            style: GoogleFonts.shareTechMono(
                              fontSize: 10,
                              color: const Color(0xFF00F5FF).withValues(alpha: 0.5),
                              letterSpacing: 3.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Indicador de carregamento (fundo) ────────
          Positioned(
            bottom: 60,
            left: 0, right: 0,
            child: AnimatedBuilder(
              animation: _emerge,
              builder: (_, __) => Opacity(
                opacity: _dotOp.value.clamp(0.0, 1.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) => _loadingDot(i)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _glowRadius,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          // Glow layer
          if (_glowRadius.value > 0)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F5FF)
                        .withValues(alpha: (_glowRadius.value / 42) * 0.35),
                    blurRadius: _glowRadius.value,
                    spreadRadius: _glowRadius.value * 0.3,
                  ),
                ],
              ),
              child: _titleText(),
            )
          else
            _titleText(),
        ],
      ),
    );
  }

  Widget _titleText() => Text(
        'AQUANAUTIX',
        style: GoogleFonts.orbitron(
          fontSize: 34,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF00F5FF),
          letterSpacing: 6.0,
          shadows: [
            Shadow(
              color: const Color(0xFF00F5FF).withValues(alpha: 0.8),
              blurRadius: 20,
            ),
            Shadow(
              color: const Color(0xFF00F5FF).withValues(alpha: 0.4),
              blurRadius: 40,
            ),
          ],
        ),
      );

  Widget _loadingDot(int i) {
    return AnimatedBuilder(
      animation: _ocean,
      builder: (_, __) {
        final phase = (_ocean.value + i * 0.33) % 1.0;
        final brightness = (math.sin(phase * math.pi * 2) * 0.5 + 0.5);
        return Container(
          width: 5, height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00F5FF).withValues(alpha: 0.2 + brightness * 0.6),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F5FF).withValues(alpha: brightness * 0.4),
                blurRadius: 6,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════
// PAINTER — Oceano com raios de luz e cáusticas
// ══════════════════════════════════════════════════════════
class _OceanPainter extends CustomPainter {
  final double t; // 0..1 animação ambiente

  const _OceanPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    _drawBackground(canvas, size);
    _drawRays(canvas, size);
    _drawCaustics(canvas, size);
    _drawParticles(canvas, size);
    _drawSurfaceGlow(canvas, size);
    _drawDepthFog(canvas, size);
  }

  // ── Fundo degradê subaquático ─────────────────────────
  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0A2A50), // perto da superfície — mais azul
          Color(0xFF041428), // meio
          Color(0xFF010610), // profundo
          Color(0xFF000814), // abissal
        ],
        stops: [0.0, 0.3, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  // ── Raios de luz da superfície ────────────────────────
  void _drawRays(Canvas canvas, Size size) {
    const rayCount = 7;
    for (int i = 0; i < rayCount; i++) {
      final baseX = size.width * (0.05 + i * 0.14);
      // Oscilação lenta da luz
      final shift = math.sin(t * math.pi * 2 + i * 0.8) * size.width * 0.04;
      final topX = baseX + shift;
      final spread = size.width * (0.04 + math.sin(i * 1.3) * 0.02);

      final path = Path()
        ..moveTo(topX - spread * 0.3, 0)
        ..lineTo(topX + spread * 0.3, 0)
        ..lineTo(topX + spread + shift * 0.5, size.height * 0.85)
        ..lineTo(topX - spread + shift * 0.5, size.height * 0.85)
        ..close();

      final intensity = 0.03 + math.sin(t * math.pi * 2 + i * 1.1) * 0.015;
      final rayPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF00F5FF).withValues(alpha: intensity * 2.2),
            const Color(0xFF4FC8FF).withValues(alpha: intensity),
            const Color(0xFF00F5FF).withValues(alpha: intensity * 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.2, 0.55, 1.0],
        ).createShader(Rect.fromLTWH(topX - spread, 0, spread * 2, size.height));

      canvas.drawPath(path, rayPaint);
    }
  }

  // ── Cáusticas (luz refractada no fundo) ──────────────
  void _drawCaustics(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    final rnd = math.Random(42);
    for (int i = 0; i < 18; i++) {
      final cx = size.width * (rnd.nextDouble() * 0.9 + 0.05);
      final cy = size.height * (0.72 + rnd.nextDouble() * 0.22);
      final rx = size.width * (0.04 + rnd.nextDouble() * 0.06);
      final ry = rx * 0.35;
      final phase = rnd.nextDouble() * math.pi * 2;
      final alpha = 0.03 + math.sin(t * math.pi * 2 + phase) * 0.025;
      paint.color = const Color(0xFF00F5FF).withValues(alpha: alpha.clamp(0.01, 0.07));
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2), paint);
    }
  }

  // ── Partículas flutuantes (plâncton) ─────────────────
  void _drawParticles(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final rnd = math.Random(17);
    final particlePaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 40; i++) {
      final baseX  = rnd.nextDouble() * size.width;
      final baseY  = rnd.nextDouble() * size.height;
      final driftX = math.sin(t * math.pi * 2 + i * 0.7) * 6;
      final driftY = -((t + i * 0.07) % 1.0) * size.height * 0.15;
      final x = (baseX + driftX) % size.width;
      final y = (baseY + driftY + size.height) % size.height;
      final alpha = 0.04 + rnd.nextDouble() * 0.12;
      final r = 0.6 + rnd.nextDouble() * 1.2;
      particlePaint.color = const Color(0xFF00F5FF).withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), r, particlePaint);
    }
  }

  // ── Brilho da superfície (topo) ───────────────────────
  void _drawSurfaceGlow(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1A8CFF).withValues(alpha: 0.18),
          const Color(0xFF00F5FF).withValues(alpha: 0.07),
          Colors.transparent,
        ],
        stops: const [0.0, 0.12, 0.35],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.4), glow);
  }

  // ── Névoa de profundidade (bordas e fundo) ────────────
  void _drawDepthFog(Canvas canvas, Size size) {
    // Laterais
    for (final isLeft in [true, false]) {
      final fog = Paint()
        ..shader = LinearGradient(
          begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          colors: [
            const Color(0xFF000814).withValues(alpha: 0.6),
            Colors.transparent,
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromLTWH(
            isLeft ? 0 : size.width * 0.6, 0, size.width * 0.4, size.height));
      canvas.drawRect(
          Rect.fromLTWH(isLeft ? 0 : size.width * 0.6, 0,
              size.width * 0.4, size.height),
          fog);
    }
    // Fundo (profundidade)
    final bottomFog = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFF000814).withValues(alpha: 0.85),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55],
      ).createShader(Rect.fromLTWH(0, size.height * 0.5, size.width, size.height * 0.5));
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.5, size.width, size.height * 0.5),
        bottomFog);
  }

  @override
  bool shouldRepaint(_OceanPainter old) => old.t != t;
}
