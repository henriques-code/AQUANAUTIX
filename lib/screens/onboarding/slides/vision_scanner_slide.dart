import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Design tokens (Midnight Deep Sea) ─────────────────────────
const _kBg    = Color(0xFF000814);
const _kBg3   = Color(0xFF031126);
const _kCyan  = Color(0xFF00F5FF);
const _kAmber = Color(0xFFF3C64D);
const _kGreen = Color(0xFF22C55E);
const _kHint  = Color(0xFF8AADBE);

// ══════════════════════════════════════════════════════════════
// VisionScannerSlide — ecrã estático de apresentação do scanner
// Sem botão PRÓXIMO. Sem dots de paginação.
// ══════════════════════════════════════════════════════════════
class VisionScannerSlide extends StatefulWidget {
  const VisionScannerSlide({super.key});

  @override
  State<VisionScannerSlide> createState() => _VisionScannerSlideState();
}

class _VisionScannerSlideState extends State<VisionScannerSlide>
    with TickerProviderStateMixin {
  late final AnimationController _scanCtrl;
  late final AnimationController _eqCtrl;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _eqCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _eqCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final scale = (mq.size.width / 390).clamp(0.85, 1.0);

    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Gradiente de fundo ─────────────────────────────
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.6, 1],
                colors: [_kBg, _kBg3, _kBg],
              ),
            ),
          ),

          // ── Ondas decorativas no rodapé ───────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            height: mq.size.height * 0.4,
            child: CustomPaint(painter: _BottomWavesPainter()),
          ),

          // ── Conteúdo scrollable ───────────────────────────
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24 * scale, 0, 24 * scale, 0),
            child: Column(
              children: [
                SizedBox(height: 80 * scale),

                // 1. Badge "VISION SCANNER"
                _VisionBadge(scale: scale)
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.3, end: 0, duration: 600.ms, curve: Curves.easeOut),

                SizedBox(height: 24 * scale),

                // 2. Viewfinder + Gauge (Row: frame | gauge)
                _ViewfinderRow(scanCtrl: _scanCtrl, eqCtrl: _eqCtrl, scale: scale)
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 700.ms)
                    .scale(
                      begin: const Offset(0.92, 0.92),
                      end: const Offset(1, 1),
                      duration: 700.ms,
                    ),

                SizedBox(height: 28 * scale),

                // 3. Bloco de identificação
                _IdentificationBlock(scale: scale)
                    .animate(delay: 900.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.25, end: 0, duration: 600.ms),

                SizedBox(height: 36 * scale),

                // 4. Headline
                Text(
                  'APONTA. IDENTIFICA. REGISTA.',
                  style: GoogleFonts.orbitron(
                    fontSize: 26 * scale,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.6,
                    height: 1.15,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate(delay: 1100.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.25, end: 0, duration: 600.ms),

                SizedBox(height: 20 * scale),

                // 5. Bullets
                ..._buildBullets(scale),

                SizedBox(height: 48 * scale),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBullets(double scale) {
    const items = [
      'Identificação instantânea com IA avançada',
      'Regras e tamanhos sempre actualizados',
      'Regista e acompanha as tuas capturas',
    ];
    return items.asMap().entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 8 * scale,
                height: 8 * scale,
                decoration: BoxDecoration(
                  color: _kCyan,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _kCyan.withValues(alpha: 0.45),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Text(
                entry.value,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 14 * scale,
                  color: const Color(0xFFC8DEEA),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: 1300 + entry.key * 120))
          .fadeIn(duration: 400.ms)
          .slideX(begin: -0.2, end: 0, duration: 400.ms, curve: Curves.easeOut);
    }).toList();
  }
}

// ── Badge pill "VISION SCANNER" ───────────────────────────────
class _VisionBadge extends StatelessWidget {
  const _VisionBadge({required this.scale});
  final double scale;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: 24 * scale,
          vertical: 10 * scale,
        ),
        decoration: BoxDecoration(
          color: _kCyan.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kCyan, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _kCyan.withValues(alpha: 0.35),
              blurRadius: 16,
            ),
          ],
        ),
        child: Text(
          'VISION SCANNER',
          style: GoogleFonts.orbitron(
            fontSize: 13 * scale,
            fontWeight: FontWeight.w700,
            color: _kCyan,
            letterSpacing: 3.5,
          ),
        ),
      );
}

// ── Viewfinder + Gauge em Row ─────────────────────────────────
class _ViewfinderRow extends StatelessWidget {
  const _ViewfinderRow({
    required this.scanCtrl,
    required this.eqCtrl,
    required this.scale,
  });
  final AnimationController scanCtrl;
  final AnimationController eqCtrl;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Frame do viewfinder
        Expanded(
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              children: [
                // Imagem do robalo
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/onboarding/vision_robalo.jpg',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF071428), Color(0xFF020D1A)],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: _kHint,
                          size: 48 * scale,
                        ),
                      ),
                    ),
                  ),
                ),

                // 4 cantos L-shape
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ViewfinderCornersPainter(),
                  ),
                ),

                // Linha de scan animada
                Positioned.fill(
                  child: _ScanLine(controller: scanCtrl),
                ),
              ],
            ),
          ),
        ),

        // Gauge 92% (fora do frame, lado direito)
        Padding(
          padding: EdgeInsets.only(left: 10 * scale),
          child: _ConfidenceGauge(eqCtrl: eqCtrl, scale: scale),
        ),
      ],
    );
  }
}

// ── Bloco de identificação da espécie ─────────────────────────
class _IdentificationBlock extends StatelessWidget {
  const _IdentificationBlock({required this.scale});
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Nome: "Robalo ·" normal + "Dicentrarchus labrax" itálico
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Robalo · ',
                style: GoogleFonts.orbitron(
                  fontSize: 22 * scale,
                  fontWeight: FontWeight.w600,
                  color: _kCyan,
                  letterSpacing: 1.2,
                ),
              ),
              TextSpan(
                text: 'Dicentrarchus labrax',
                style: GoogleFonts.orbitron(
                  fontSize: 22 * scale,
                  fontWeight: FontWeight.w600,
                  color: _kCyan,
                  letterSpacing: 1.2,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 8 * scale),

        // Métricas: Share Tech Mono, âmbar
        Text(
          '≈ 3.1 kg · 58 cm',
          style: GoogleFonts.shareTechMono(
            fontSize: 18 * scale,
            color: _kAmber,
            letterSpacing: 2,
          ),
        ),

        SizedBox(height: 8 * scale),

        // Pill "LEGAL PT"
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12 * scale,
            vertical: 6 * scale,
          ),
          decoration: BoxDecoration(
            color: _kGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kGreen, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 16 * scale, color: _kGreen),
              SizedBox(width: 6 * scale),
              Text(
                'LEGAL PT · Min 36cm',
                style: GoogleFonts.shareTechMono(
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w600,
                  color: _kGreen,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Linha de scan animada (loop 2.4 s) ───────────────────────
class _ScanLine extends StatelessWidget {
  const _ScanLine({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ).value;
        return CustomPaint(painter: _ScanLinePainter(progress: t));
      },
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  const _ScanLinePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const margin = 16.0;
    final y = margin + (size.height - margin * 2) * progress;

    // Glow
    canvas.drawLine(
      Offset(margin, y),
      Offset(size.width - margin, y),
      Paint()
        ..color = _kCyan.withValues(alpha: 0.5)
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    // Linha gradient
    canvas.drawLine(
      Offset(margin, y),
      Offset(size.width - margin, y),
      Paint()
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..shader = LinearGradient(
          colors: [Colors.transparent, _kCyan, Colors.transparent],
        ).createShader(
          Rect.fromLTWH(margin, y - 1, size.width - margin * 2, 2),
        ),
    );
  }

  @override
  bool shouldRepaint(_ScanLinePainter old) => old.progress != progress;
}

// ── Indicador 92% + equalizer (loop 1.6 s) ──────────────────
class _ConfidenceGauge extends StatelessWidget {
  const _ConfidenceGauge({required this.eqCtrl, required this.scale});
  final AnimationController eqCtrl;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Contador 0 → 92 (1.4 s, uma vez)
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 92),
          duration: const Duration(milliseconds: 1400),
          builder: (_, val, __) => Text(
            '${val.toInt()}%',
            style: GoogleFonts.shareTechMono(
              fontSize: 28 * scale,
              fontWeight: FontWeight.w700,
              color: _kCyan,
              shadows: [
                Shadow(
                  color: _kCyan.withValues(alpha: 0.7),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 6),

        // 14 barras do equalizer com opacidade animada escalonada
        AnimatedBuilder(
          animation: eqCtrl,
          builder: (_, __) => Column(
            children: List.generate(14, (i) {
              final phase = (eqCtrl.value - i / 14) % 1.0;
              final opacity =
                  (math.sin(phase * math.pi * 2) * 0.4 + 0.6).clamp(0.2, 1.0);
              return Container(
                width: 14 * scale,
                height: 2,
                margin: const EdgeInsets.only(bottom: 3),
                decoration: BoxDecoration(
                  color: _kCyan.withValues(alpha: opacity),
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ── CustomPainter: 4 cantos L-shape do viewfinder ────────────
class _ViewfinderCornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const pad = 12.0;
    const arm = 28.0;
    final w = size.width;
    final h = size.height;

    final corners = <List<Offset>>[
      // Top-left
      [Offset(pad, pad + arm), Offset(pad, pad), Offset(pad + arm, pad)],
      // Top-right
      [
        Offset(w - pad - arm, pad),
        Offset(w - pad, pad),
        Offset(w - pad, pad + arm),
      ],
      // Bottom-left
      [
        Offset(pad, h - pad - arm),
        Offset(pad, h - pad),
        Offset(pad + arm, h - pad),
      ],
      // Bottom-right
      [
        Offset(w - pad - arm, h - pad),
        Offset(w - pad, h - pad),
        Offset(w - pad, h - pad - arm),
      ],
    ];

    for (final pts in corners) {
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (final o in pts.skip(1)) {
        path.lineTo(o.dx, o.dy);
      }
      // Glow exterior
      canvas.drawPath(
        path,
        Paint()
          ..color = _kCyan.withValues(alpha: 0.4)
          ..strokeWidth = 10
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.square
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12),
      );
      // Traço nítido
      canvas.drawPath(
        path,
        Paint()
          ..color = _kCyan
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.square,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── CustomPainter: 3 sine waves decorativas no rodapé ────────
class _BottomWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final waves = [
      (amp: 18.0, freq: 0.8, phase: 0.0, opacity: 0.18),
      (amp: 12.0, freq: 1.1, phase: 0.9, opacity: 0.12),
      (amp: 8.0,  freq: 1.5, phase: 1.8, opacity: 0.08),
    ];

    for (final wv in waves) {
      final path = Path();
      final baseY = size.height * 0.25;

      for (double x = 0; x <= size.width; x++) {
        final y = baseY +
            wv.amp *
                math.sin(
                  (x / size.width) * wv.freq * math.pi * 2 + wv.phase,
                );
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = _kCyan.withValues(alpha: wv.opacity)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
