// lib/core/widgets/aquanautix_pins.dart
//
// Pins custom AQUANAUTIX — designs aprovados (imagens do chat, 7 Mai 2026)
// Flutter puro · sem assets externos · escalam para qualquer Size.
//
// Uso: CustomPaint(size: Size(40, 47), painter: AqxPinFree())
//
// Exports:
//   AqxPinFree        FREE       ciano   barbatana + ondas
//   AqxPinPro         PRO        azul    crosshair / mira
//   AqxPinElite       ELITE      âmbar   rosa dos ventos 8 pontas
//   AqxPinSaved       SAVED      vermelho teardrop clássico
//   AqxPinBait        BAIT SHOP  verde   casa de pesca + cana
//   AqxPinCommunity   COMUNIDADE ciano   cristal hexagonal + fantasma

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ── Cores exportadas ─────────────────────────────────────
const Color aqxPinCyan  = Color(0xFF00F5FF);
const Color aqxPinBlue  = Color(0xFF007BFF);
const Color aqxPinAmber = Color(0xFFF3C64D);
const Color aqxPinRed   = Color(0xFFFF2A2A);
const Color aqxPinGreen = Color(0xFF00C853);
const Color aqxPinGold  = Color(0xFFFFD600);

// ═══════════════════════════════════════════════════════════
// PIN UNIFICADO v3 — gota única · cor por tipo · oráculo no badge
// ═══════════════════════════════════════════════════════════

/// Tipos de pin no mapa — mesma silhueta, cor e conteúdo interior distintos.
enum AqxPinKind {
  free(aqxPinCyan),
  pro(aqxPinBlue),
  elite(aqxPinAmber),
  saved(aqxPinRed),
  baitShop(aqxPinGreen),
  community(aqxPinGold);

  const AqxPinKind(this.color);
  final Color color;

  static AqxPinKind fromTier({
    required String tier,
    bool elite = false,
  }) {
    final t = tier.toUpperCase();
    if (elite || t == 'ELITE') return AqxPinKind.elite;
    if (t == 'PRO') return AqxPinKind.pro;
    return AqxPinKind.free;
  }

  IconData get fallbackIcon => switch (this) {
        AqxPinKind.free => Icons.waves_rounded,
        AqxPinKind.pro => Icons.gps_fixed_rounded,
        AqxPinKind.elite => Icons.auto_awesome_rounded,
        AqxPinKind.saved => Icons.bookmark_rounded,
        AqxPinKind.baitShop => Icons.storefront_outlined,
        AqxPinKind.community => Icons.groups_rounded,
      };
}

Path _pinPathForSize(Size size) {
  final path = _pin();
  final matrix = Matrix4.diagonal3Values(size.width / 96, size.height / 96, 1);
  return path.transform(matrix.storage);
}

/// Moldura gota (glow + borda) — conteúdo via [AqxUnifiedPin].
class AqxUnifiedPinFramePainter extends CustomPainter {
  const AqxUnifiedPinFramePainter({
    required this.color,
    this.livePulse = false,
  });

  final Color color;
  final bool livePulse;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 96, size.height / 96);

    if (livePulse) {
      canvas.drawPath(
        _pin(),
        Paint()
          ..color = color.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
    }

    _pinBase(canvas, color, const Color(0xFF020E15));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AqxUnifiedPinFramePainter old) =>
      old.color != color || old.livePulse != livePulse;
}

class _PinShapeClipper extends CustomClipper<Path> {
  const _PinShapeClipper(this.size);
  final Size size;

  @override
  Path getClip(Size size) => _pinPathForSize(this.size);

  @override
  bool shouldReclip(covariant _PinShapeClipper old) => old.size != size;
}

/// Pin AQUANAUTIX Drop — forma única, cor por [kind], foto/avatar no interior.
///
/// Critérios produto (Jul 2026):
/// - Oráculo visível no badge mesmo em spots PRO bloqueados (FOMO).
/// - Comunidade «a pescar»: [avatarUrl] ou [image] com [isLive].
/// - Loja isco: ícone casa no interior se sem foto.
class AqxUnifiedPin extends StatelessWidget {
  const AqxUnifiedPin({
    super.key,
    required this.kind,
    this.oracleScore,
    this.badgeLabel,
    this.image,
    this.avatarUrl,
    this.locked = false,
    this.isLive = false,
    this.size = const Size(40, 47),
    this.onTap,
  });

  final AqxPinKind kind;
  final int? oracleScore;
  final String? badgeLabel;
  final ImageProvider? image;
  final String? avatarUrl;
  final bool locked;
  final bool isLive;
  final Size size;
  final VoidCallback? onTap;

  Color _scoreAccent(int score) {
    if (score >= 75) return aqxPinGreen;
    if (score >= 50) return aqxPinAmber;
    return aqxPinRed;
  }

  Widget _innerContent() {
    final icon = kind.fallbackIcon;
    Widget core;

    if (image != null) {
      core = Image(
        image: image!,
        fit: BoxFit.cover,
        width: size.width,
        height: size.height,
        errorBuilder: (_, __, ___) => _iconFallback(icon),
      );
    } else if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      core = Image.network(
        avatarUrl!,
        fit: BoxFit.cover,
        width: size.width,
        height: size.height,
        errorBuilder: (_, __, ___) => _iconFallback(icon),
      );
    } else {
      core = _iconFallback(icon);
    }

    if (locked) {
      core = ImageFiltered(
        imageFilter: const ColorFilter.matrix([
          0.4, 0, 0, 0, 0,
          0, 0.4, 0, 0, 0,
          0, 0, 0.4, 0, 0,
          0, 0, 0, 0.65, 0,
        ]),
        child: Opacity(opacity: 0.7, child: core),
      );
    }

    return core;
  }

  Widget _iconFallback(IconData icon) {
    return Container(
      color: const Color(0xFF071428),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: kind.color.withValues(alpha: 0.9),
        size: size.width * 0.38,
      ),
    );
  }

  Widget? _oracleBadge() {
    final label = badgeLabel ?? (oracleScore != null ? '${oracleScore!}' : null);
    if (label == null || label.isEmpty) return null;

    final score = oracleScore;
    final accent = score != null ? _scoreAccent(score) : kind.color;

    return Positioned(
      right: size.width * 0.06,
      top: size.height * 0.20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xE6000814),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: size.width * 0.22,
            fontWeight: FontWeight.w800,
            color: accent,
            height: 1,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final frame = CustomPaint(
      size: size,
      painter: AqxUnifiedPinFramePainter(
        color: kind.color,
        livePulse: isLive,
      ),
      child: ClipPath(
        clipper: _PinShapeClipper(size),
        child: SizedBox(width: size.width, height: size.height, child: _innerContent()),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            frame,
            if (_oracleBadge() != null) _oracleBadge()!,
            if (locked)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF071428),
                    shape: BoxShape.circle,
                    border: Border.all(color: kind.color.withValues(alpha: 0.85)),
                  ),
                  child: Icon(Icons.lock_rounded, size: 10, color: kind.color),
                ),
              ),
            if (isLive)
              Positioned(
                left: -1,
                top: size.height * 0.14,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: aqxPinGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF000814), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: aqxPinGreen.withValues(alpha: 0.8),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Resolve foto de spot (asset local ou URL remota).
ImageProvider? aqxImageFromPhotoUrl(String? photoUrl) {
  if (photoUrl == null || photoUrl.isEmpty) return null;
  if (photoUrl.startsWith('assets/')) return AssetImage(photoUrl);
  return NetworkImage(photoUrl);
}

/// Pin de spot curado no mapa — gota única, oráculo sempre visível no badge.
Widget buildSpotMapPin({
  required String tier,
  bool elite = false,
  int? oracleScore,
  String? photoUrl,
  bool locked = false,
  Size size = const Size(40, 47),
  VoidCallback? onTap,
}) {
  return AqxUnifiedPin(
    kind: AqxPinKind.fromTier(tier: tier, elite: elite),
    oracleScore: oracleScore,
    image: aqxImageFromPhotoUrl(photoUrl),
    locked: locked,
    size: size,
    onTap: onTap,
  );
}

// ═══════════════════════════════════════════════════════════
// LEGACY painters (Jul 2026) — preferir [AqxUnifiedPin]
// ═══════════════════════════════════════════════════════════

// Pin clássico: círculo-topo (centro 48,38 r≈30) + ponta (48,93)
Path _pin() => Path()
  ..moveTo(48, 5)
  ..cubicTo(72, 5, 82, 22, 82, 38)
  ..cubicTo(82, 58, 65, 74, 48, 93)
  ..cubicTo(31, 74, 14, 58, 14, 38)
  ..cubicTo(14, 22, 24, 5, 48, 5)
  ..close();

// Glow + fundo + borda neon do pin
void _pinBase(Canvas c, Color col, Color bg) {
  final path = _pin();
  c.drawPath(path, Paint()
    ..color = col.withValues(alpha: 0.28)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
  c.drawPath(path, Paint()..color = bg);
  c.drawPath(path, Paint()
    ..color = col
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.5);
}

// ═══════════════════════════════════════════════════════════
// 1. FREE — Barbatana de tubarão ciano (Opção A aprovada)
// ═══════════════════════════════════════════════════════════
class AqxPinFree extends CustomPainter {
  const AqxPinFree();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 96, size.height / 96);

    _pinBase(canvas, aqxPinCyan, const Color(0xFF020E15));

    canvas.save();
    canvas.clipPath(_pin());

    // Barbatana dorsal (larga, proeminente)
    final fin = Path()
      ..moveTo(29, 61)
      ..cubicTo(27, 43, 36, 19, 45, 13)   // aresta esq: subida íngreme
      ..cubicTo(52,  9, 62, 16, 64, 27)   // topo: pico curvo à direita
      ..cubicTo(67, 41, 67, 57, 67, 61)   // aresta dir: descida suave
      ..close();
    canvas.drawPath(fin, Paint()..color = aqxPinCyan.withValues(alpha: 0.92));
    // Highlight na aresta esquerda
    canvas.drawPath(
      Path()..moveTo(43, 15)..cubicTo(36, 28, 33, 44, 32, 55),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    // 2 ondas (sinusoidais)
    for (int i = 0; i < 2; i++) {
      final y = 68.0 + i * 8.0;
      canvas.drawPath(
        Path()
          ..moveTo(20, y)
          ..quadraticBezierTo(34, y - 7, 48, y)
          ..quadraticBezierTo(62, y + 7, 76, y),
        Paint()
          ..color = aqxPinCyan.withValues(alpha: 0.52 - i * 0.14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 - i * 0.4
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════
// 2. PRO — Crosshair / Mira azul (Opção A aprovada)
// ═══════════════════════════════════════════════════════════
class AqxPinPro extends CustomPainter {
  const AqxPinPro();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 96, size.height / 96);

    _pinBase(canvas, aqxPinBlue, const Color(0xFF020C1C));

    canvas.save();
    canvas.clipPath(_pin());

    const cx = 48.0;
    const cy = 38.0;
    final s = Paint()..color = aqxPinBlue..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;

    // Anel exterior
    canvas.drawCircle(const Offset(cx, cy), 22, s..strokeWidth = 2.2);
    // Anel intermédio ténue
    canvas.drawCircle(const Offset(cx, cy), 14,
        s..strokeWidth = 0.9..color = aqxPinBlue.withValues(alpha: 0.35));
    // Anel interior
    canvas.drawCircle(const Offset(cx, cy), 7, s..strokeWidth = 2.2..color = aqxPinBlue);

    // Linhas cruzadas (gap nos anéis: de r=7 a r=22)
    final lp = Paint()..color = aqxPinBlue..strokeWidth = 2.2..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(cx, cy - 22), const Offset(cx, cy - 7), lp);
    canvas.drawLine(const Offset(cx, cy + 7),  const Offset(cx, cy + 22), lp);
    canvas.drawLine(const Offset(cx - 22, cy), const Offset(cx - 7, cy), lp);
    canvas.drawLine(const Offset(cx + 7,  cy), const Offset(cx + 22, cy), lp);

    // Ponto central sólido
    canvas.drawCircle(const Offset(cx, cy), 2.8, Paint()..color = aqxPinBlue);

    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════
// 3. ELITE — Rosa dos Ventos 8 pontas âmbar (Opção A aprovada)
// ═══════════════════════════════════════════════════════════
class AqxPinElite extends CustomPainter {
  const AqxPinElite();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 96, size.height / 96);

    _pinBase(canvas, aqxPinAmber, const Color(0xFF160C00));

    canvas.save();
    canvas.clipPath(_pin());

    const cx = 48.0;
    const cy = 37.0;

    // Glow por baixo
    canvas.drawCircle(const Offset(cx, cy), 22,
        Paint()..color = aqxPinAmber.withValues(alpha: 0.20)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // 8 pétalas: cardinais (compridas) + intercardinais (curtas)
    final fill   = Paint()..color = aqxPinAmber;
    final stroke = Paint()..color = Colors.white.withValues(alpha: 0.10)..style = PaintingStyle.stroke..strokeWidth = 0.7;
    for (int i = 0; i < 8; i++) {
      final angle  = -math.pi / 2 + i * math.pi / 4;
      final isCard = i % 2 == 0;
      final len    = isCard ? 21.5 : 13.5;
      final halfW  = isCard ? 5.5  : 3.5;
      final tip    = Offset(cx + len * math.cos(angle), cy + len * math.sin(angle));
      final perp   = angle + math.pi / 2;
      final lp     = Offset(cx + halfW * math.cos(perp), cy + halfW * math.sin(perp));
      final rp     = Offset(cx - halfW * math.cos(perp), cy - halfW * math.sin(perp));
      final petal  = Path()..moveTo(lp.dx, lp.dy)..lineTo(tip.dx, tip.dy)..lineTo(rp.dx, rp.dy)..close();
      canvas.drawPath(petal, fill);
      canvas.drawPath(petal, stroke);
    }

    // Centro: disco escuro + anel + ponto
    canvas.drawCircle(const Offset(cx, cy), 5.5, Paint()..color = const Color(0xFF160C00));
    canvas.drawCircle(const Offset(cx, cy), 5.5,
        Paint()..color = aqxPinAmber..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawCircle(const Offset(cx, cy), 2.4, Paint()..color = aqxPinAmber);

    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════
// 4. SAVED — Teardrop vermelho clássico (Opção A aprovada)
// ═══════════════════════════════════════════════════════════
class AqxPinSaved extends CustomPainter {
  const AqxPinSaved();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 96, size.height / 96);

    // Glow
    canvas.drawPath(_pin(), Paint()
      ..color = aqxPinRed.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    // Pin preenchido vermelho
    canvas.drawPath(_pin(), Paint()..color = aqxPinRed);
    // Borda subtil
    canvas.drawPath(_pin(), Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);

    // Grande círculo escuro (Opção A: domina o círculo-topo)
    canvas.drawCircle(const Offset(48, 38), 20, Paint()..color = const Color(0xFF180000));
    canvas.drawCircle(const Offset(48, 38), 20, Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════
// 5. BAIT SHOP — Casa de pesca + cana (Imagem 1 aprovada)
// ═══════════════════════════════════════════════════════════
class AqxPinBait extends CustomPainter {
  const AqxPinBait();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 96, size.height / 96);

    _pinBase(canvas, aqxPinGreen, const Color(0xFF020E06));

    // ── Casa (clipped ao pin) ─────────────────────────────
    canvas.save();
    canvas.clipPath(_pin());

    final fill   = Paint()..color = aqxPinGreen.withValues(alpha: 0.50);
    final stroke = Paint()
      ..color = aqxPinGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Paredes
    canvas.drawRect(const Rect.fromLTWH(22, 46, 52, 28), fill);
    canvas.drawRect(const Rect.fromLTWH(22, 46, 52, 28), stroke);

    // Telhado triangular
    final roof = Path()..moveTo(18, 46)..lineTo(48, 22)..lineTo(78, 46)..close();
    canvas.drawPath(roof, fill);
    canvas.drawPath(roof, stroke..strokeWidth = 2.0);

    // Chaminé (esq do pico)
    canvas.drawRect(const Rect.fromLTWH(29, 24, 10, 20), fill);
    canvas.drawRect(const Rect.fromLTWH(29, 24, 10, 20), stroke..strokeWidth = 1.3);

    // Porta (centro, arco no topo)
    canvas.drawRRect(
      RRect.fromRectAndCorners(const Rect.fromLTWH(39, 58, 18, 16),
          topLeft: const Radius.circular(4), topRight: const Radius.circular(4)),
      Paint()..color = const Color(0xFF020E06),
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(const Rect.fromLTWH(39, 58, 18, 16),
          topLeft: const Radius.circular(4), topRight: const Radius.circular(4)),
      stroke..strokeWidth = 1.5,
    );
    // Maçaneta
    canvas.drawCircle(const Offset(53, 67), 1.6, Paint()..color = aqxPinGreen.withValues(alpha: 0.85));

    // Janela olho-de-boi (náutica)
    canvas.drawCircle(const Offset(63, 55), 7, Paint()..color = const Color(0xFF020E06));
    canvas.drawCircle(const Offset(63, 55), 7, stroke..strokeWidth = 1.7);
    canvas.drawCircle(const Offset(63, 55), 4,
        Paint()..color = aqxPinGreen.withValues(alpha: 0.20)..style = PaintingStyle.stroke..strokeWidth = 0.8);

    // Ondas (2 linhas na base)
    for (int i = 0; i < 2; i++) {
      final y = 79.0 + i * 7.0;
      canvas.drawPath(
        Path()
          ..moveTo(20, y)
          ..quadraticBezierTo(34, y - 5, 48, y)
          ..quadraticBezierTo(62, y + 5, 76, y),
        Paint()
          ..color = aqxPinGreen.withValues(alpha: 0.45 - i * 0.10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.restore(); // fim do clip

    // ── Cana de pesca (fora do clip — estende-se para além do pin) ──
    // Cana: (67, 35) → (88, 6)
    canvas.drawLine(
      const Offset(67, 35), const Offset(88, 6),
      Paint()..color = aqxPinGreen..strokeWidth = 2.6..strokeCap = StrokeCap.round,
    );
    // Linha de pesca (fio fino a descer)
    canvas.drawLine(
      const Offset(88, 6), const Offset(88, 22),
      Paint()..color = aqxPinGreen.withValues(alpha: 0.50)..strokeWidth = 1.2,
    );
    // Anzol
    canvas.drawPath(
      Path()..moveTo(88, 22)..quadraticBezierTo(93, 29, 87, 34),
      Paint()
        ..color = aqxPinGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.9
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════
// 6. COMUNIDADE — Cristal hexagonal + fantasma (Imagem 1 aprovada)
// ═══════════════════════════════════════════════════════════
class AqxPinCommunity extends CustomPainter {
  const AqxPinCommunity();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 96, size.height / 96);

    // Hexágono apontado (pointy-top), centro (48,48), raio 43
    const cx = 48.0;
    const cy = 48.0;
    const r  = 43.0;
    final v = List.generate(6, (i) {
      final a = -math.pi / 2 + i * math.pi / 3;
      return Offset(cx + r * math.cos(a), cy + r * math.sin(a));
    });
    // v[0]=top(48,5)  v[1]=top-right(85,27)  v[2]=bot-right(85,69)
    // v[3]=bot(48,91) v[4]=bot-left(11,69)   v[5]=top-left(11,27)

    final hexPath = Path()..moveTo(v[0].dx, v[0].dy);
    for (int i = 1; i < 6; i++) {
      hexPath.lineTo(v[i].dx, v[i].dy);
    }
    hexPath.close();

    // Glow externo
    canvas.drawPath(hexPath, Paint()
      ..color = aqxPinCyan.withValues(alpha: 0.40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));

    // Preenchimento escuro
    canvas.drawPath(hexPath, Paint()..color = const Color(0xFF030F1A));

    // Facetas triangulares (efeito cristal — alpha variável por triângulo)
    const alphas = [0.07, 0.13, 0.04, 0.10, 0.03, 0.08];
    for (int i = 0; i < 6; i++) {
      canvas.drawPath(
        Path()
          ..moveTo(cx, cy)
          ..lineTo(v[i].dx, v[i].dy)
          ..lineTo(v[(i + 1) % 6].dx, v[(i + 1) % 6].dy)
          ..close(),
        Paint()..color = aqxPinCyan.withValues(alpha: alphas[i]),
      );
    }

    // Linhas de aresta internas (gem / cristal)
    final fl = Paint()..color = aqxPinCyan.withValues(alpha: 0.28)..strokeWidth = 1.2;
    canvas.drawLine(v[0], v[2], fl); // topo → bot-dir
    canvas.drawLine(v[0], v[4], fl); // topo → bot-esq
    canvas.drawLine(v[3], v[1], fl); // bot  → top-dir
    canvas.drawLine(v[3], v[5], fl); // bot  → top-esq
    canvas.drawLine(v[5], v[2], fl); // cruzado
    canvas.drawLine(v[1], v[4], fl); // cruzado

    // Borda hexagonal: faint inner + neon outer
    canvas.drawPath(hexPath, Paint()
      ..color = aqxPinCyan.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
    canvas.drawPath(hexPath, Paint()
      ..color = aqxPinCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));

    // ── Fantasma (clipped ao hex) ─────────────────────────
    canvas.save();
    canvas.clipPath(hexPath);

    const gCx = 48.0;
    const gCy = 50.0;
    final ghostP = Paint()..color = aqxPinCyan.withValues(alpha: 0.82);
    final bgP    = Paint()..color = const Color(0xFF030F1A);

    // Cabeça
    canvas.drawCircle(const Offset(gCx, gCy - 9), 16, ghostP);

    // Corpo (trapézio arredondado)
    canvas.drawPath(
      Path()
        ..moveTo(gCx - 16, gCy - 9)
        ..cubicTo(gCx - 16, gCy + 16, gCx - 13, gCy + 21, gCx, gCy + 21)
        ..cubicTo(gCx + 13, gCy + 21, gCx + 16, gCy + 16, gCx + 16, gCy - 9)
        ..close(),
      ghostP,
    );

    // Fundo ondulado do fantasma (recorte)
    canvas.drawPath(
      Path()
        ..moveTo(gCx - 16, gCy + 15)
        ..quadraticBezierTo(gCx - 10, gCy + 25, gCx - 5, gCy + 20)
        ..quadraticBezierTo(gCx,      gCy + 28, gCx + 5, gCy + 20)
        ..quadraticBezierTo(gCx + 10, gCy + 25, gCx + 16, gCy + 15)
        ..lineTo(gCx + 16, gCy + 36)
        ..lineTo(gCx - 16, gCy + 36)
        ..close(),
      bgP,
    );

    // Buracos dos olhos
    canvas.drawOval(
        Rect.fromCenter(center: Offset(gCx - 5.5, gCy - 11), width: 7.5, height: 9.5), bgP);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(gCx + 5.5, gCy - 11), width: 7.5, height: 9.5), bgP);

    canvas.restore(); // fim clip hex
    canvas.restore(); // fim scale
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Pin de foto de captura (foto circular + avatar) ───────

class CatchPhotoPin extends StatelessWidget {
  const CatchPhotoPin({
    super.key,
    required this.photoUrl,
    this.avatarUrl,
    this.oracleScore,
    this.isOwn = false,
    this.isLive = false,
    this.onTap,
  });

  final String photoUrl;
  final String? avatarUrl;
  final int? oracleScore;
  final bool isOwn;
  final bool isLive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final useAvatarAsMain = isLive &&
        avatarUrl != null &&
        avatarUrl!.isNotEmpty;

    return AqxUnifiedPin(
      kind: isOwn ? AqxPinKind.saved : AqxPinKind.community,
      oracleScore: oracleScore,
      image: useAvatarAsMain ? null : NetworkImage(photoUrl),
      avatarUrl: useAvatarAsMain ? avatarUrl : null,
      isLive: isLive,
      size: const Size(44, 52),
      onTap: onTap,
    );
  }
}
