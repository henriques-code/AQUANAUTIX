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

// ═══════════════════════════════════════════════════════════
// HELPERS INTERNOS — espaço de coordenadas 96×96
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
    this.isOwn = false,
    this.onTap,
  });

  final String photoUrl;
  final String? avatarUrl;
  final bool isOwn;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isOwn ? const Color(0xFFFF4444) : aqxPinCyan;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 56,
        height: 68,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF071428),
                      child: Icon(Icons.set_meal_outlined, color: aqxPinCyan, size: 24),
                    ),
                  ),
                ),
              ),
            ),
            if (avatarUrl != null && avatarUrl!.isNotEmpty)
              Positioned(
                bottom: 12,
                right: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF000814), width: 1.5),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const CircleAvatar(
                        backgroundColor: Color(0xFF071428),
                        child: Icon(Icons.person, color: aqxPinCyan, size: 12),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Center(
                child: CustomPaint(
                  size: const Size(12, 10),
                  painter: _PinTailPainter(color: borderColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  const _PinTailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter oldDelegate) => oldDelegate.color != color;
}
