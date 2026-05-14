import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Paleta Midnight Deep Sea ───────────────────────────────
const kBg    = Color(0xFF000814);
const kCard  = Color(0xFF071428);
const kCyan  = Color(0xFF00F5FF);
const kAmber = Color(0xFFF3C64D);
const kHint  = Color(0xFF8AADBE);
const kGreen = Color(0xFF00D26A);
const kNav   = Color(0xFF020A14);
const kInact = Color(0xFF3A5068);

// ─── Helpers de tipografia ─────────────────────────────────
TextStyle orb(double sz, {FontWeight fw = FontWeight.w700, Color c = Colors.white, double ls = 1}) =>
    GoogleFonts.orbitron(fontSize: sz, fontWeight: fw, color: c, letterSpacing: ls);

TextStyle ibm(double sz, {FontWeight fw = FontWeight.w400, Color c = Colors.white, double ls = 0}) =>
    GoogleFonts.ibmPlexSans(fontSize: sz, fontWeight: fw, color: c, letterSpacing: ls);

TextStyle mono(double sz, {Color c = kHint, double ls = 0.6}) =>
    GoogleFonts.shareTechMono(fontSize: sz, color: c, letterSpacing: ls);

// Decoração padrão dos cards — igual em todos os ecrãs
BoxDecoration get cardBox => BoxDecoration(
  color: kCard,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: kCyan.withValues(alpha: 0.1)),
);

// ─── NetworkImage com fallback ──────────────────────────────
Widget netImg(
  String url, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  BorderRadius? radius,
}) =>
    ClipRRect(
      borderRadius: radius ?? BorderRadius.zero,
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                width: width,
                height: height,
                color: const Color(0xFF0A1F3A),
                child: const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Color(0xFF00F5FF),
                    ),
                  ),
                ),
              ),
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: const Color(0xFF0A1F3A),
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: Color(0xFF3A5068),
            size: 20,
          ),
        ),
      ),
    );

// ─── Widget foto de peixe (simulação premium) ───────────────
/// Usa [size] para thumbnail (60) ou grande (180).
/// [captured] = true → mostra foto "tirada"; false → botão para tirar.
Widget fishPhotoWidget({
  required double size,
  required bool captured,
  VoidCallback? onTap,
  String emoji = '🐟',
}) {
  return GestureDetector(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size < 80 ? 8 : 12),
      child: SizedBox(
        width: size, height: size,
        child: captured
            ? CustomPaint(painter: _FotoSimPainter(emoji: emoji))
            : Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF06101E),
                  borderRadius: BorderRadius.circular(size < 80 ? 8 : 12),
                  border: Border.all(color: kCyan.withValues(alpha: 0.2)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        size: size * 0.32, color: kHint.withValues(alpha: 0.6)),
                    if (size >= 80) ...[
                      const SizedBox(height: 6),
                      Text('FOTO', style: mono(9, c: kHint.withValues(alpha: 0.6))),
                    ],
                  ],
                ),
              ),
      ),
    ),
  );
}

class _FotoSimPainter extends CustomPainter {
  final String emoji;
  const _FotoSimPainter({this.emoji = '🐟'});

  @override
  void paint(Canvas canvas, Size size) {
    // Fundo subaquático
    final bg = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.2, -0.3),
        radius: 1.1,
        colors: [
          Color(0xFF0E2A40),
          Color(0xFF051520),
          Color(0xFF000814),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    // Raios de luz vindos de cima
    for (int i = 0; i < 3; i++) {
      final x = size.width * (0.25 + i * 0.25);
      final ray = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF00F5FF).withValues(alpha: 0.07),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(x - 8, 0, 16, size.height));
      canvas.drawRect(
        Rect.fromLTWH(x - 8, 0, 16, size.height * 0.7),
        ray,
      );
    }

    // Cáusticas subtis no fundo
    final caust = Paint()
      ..color = const Color(0xFF00F5FF).withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    for (int i = 0; i < 4; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * (0.3 + i * 0.15), size.height * 0.7),
          width: size.width * 0.18,
          height: size.width * 0.06,
        ),
        caust,
      );
    }

    // Texto emoji do peixe (o Flutter não renderiza emoji em CustomPainter facilmente,
    // por isso usamos um ícone via canvas — simulamos com um círculo subtil)
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      center,
      size.width * 0.22,
      Paint()..color = const Color(0xFF00F5FF).withValues(alpha: 0.08),
    );
    canvas.drawCircle(
      center,
      size.width * 0.22,
      Paint()
        ..color = const Color(0xFF00F5FF).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Borda scan — linha ciano horizontal no meio
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.52),
      Offset(size.width * 0.9, size.height * 0.52),
      Paint()
        ..color = const Color(0xFF00F5FF).withValues(alpha: 0.35)
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(_FotoSimPainter old) => old.emoji != emoji;
}
