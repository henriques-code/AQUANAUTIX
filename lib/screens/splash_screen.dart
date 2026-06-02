import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'login_module.dart';
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

  // Título emerge das profundezas
  late final AnimationController _emerge;

  /// Barra de progresso 0 → 100% (3 s); ao terminar navega.
  late final AnimationController _progress;

  late final Animation<double> _titleScale;   // 0.02 → 1.0
  late final Animation<double> _titleY;       // 380 → 0  (slide de baixo para cima)
  late final Animation<double> _titleOpacity; // 0 → 1
  late final Animation<double> _glowRadius;   // 0 → 40
  late final Animation<double> _taglineOp;    // 0 → 1  (após título)

  VideoPlayerController? _video;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _emerge = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _progress = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _navigateNext();
        }
      });

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

    unawaited(_initVideo());

    // Inicia animação de emersão e barra de progresso com pequeno delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _emerge.forward();
      _progress.forward();
    });
  }

  Future<void> _initVideo() async {
    final c = VideoPlayerController.asset('assets/video_bg.mp4');
    _video = c;
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
    } catch (_) {
      // Mantém fundo sólido do Scaffold se o asset falhar
    }
    if (mounted) setState(() {});
  }

  Future<void> _navigateNext() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    final showOnboarding = await OnboardingScreen.shouldShow();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => showOnboarding
            ? OnboardingScreen(
                onDone: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const LoginModuleScreen(),
                  ),
                ),
              )
            : const LoginModuleScreen(),
        transitionDuration: const Duration(milliseconds: 700),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _video?.dispose();
    _emerge.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = _video;
    final videoReady = v != null && v.value.isInitialized;

    return Scaffold(
      backgroundColor: const Color(0xFF000814),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (videoReady)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: v.value.size.width,
                  height: v.value.size.height,
                  child: VideoPlayer(v),
                ),
              ),
            ),
          if (videoReady)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(color: Colors.black.withValues(alpha: 0.45)),
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

          // ── Barra de progresso (inferior) ───────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: AnimatedBuilder(
              animation: _progress,
              builder: (context, _) {
                final w = MediaQuery.sizeOf(context).width * 0.7;
                final p = _progress.value.clamp(0.0, 1.0);
                final fillW = w * p;
                const barH = 3.0;
                const glowD = 8.0;
                const cyan = Color(0xFF00F5FF);
                return Center(
                  child: SizedBox(
                    width: w,
                    height: glowD,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.centerLeft,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: w,
                            height: barH,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(1.5),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ColoredBox(
                                    color: cyan.withValues(alpha: 0.15),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: SizedBox(
                                      width: fillW,
                                      height: barH,
                                      child: const ColoredBox(color: cyan),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (p > 0.001)
                          Positioned(
                            left: fillW - glowD / 2,
                            top: 0,
                            child: IgnorePointer(
                              child: Container(
                                width: glowD,
                                height: glowD,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: cyan.withValues(alpha: 0.9),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cyan.withValues(alpha: 0.55),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
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
}
