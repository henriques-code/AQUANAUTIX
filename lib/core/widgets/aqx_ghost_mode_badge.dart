import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kCyan = Color(0xFF00F5FF);
const _kAmber = Color(0xFFF3C64D);

/// Badge Ghost Mode — hex ciano + pill «GHOST» âmbar (substitui 👻).
class AqxGhostModeBadge extends StatelessWidget {
  const AqxGhostModeBadge({
    super.key,
    this.size = 14,
    this.showHex = true,
    this.showPill = true,
  });

  final double size;
  final bool showHex;
  final bool showPill;

  /// Remove prefixo legacy 👻 de etiquetas de zona.
  static String stripLegacyPrefix(String label) =>
      label.replaceAll('👻 ', '').replaceAll('👻', '').trim();

  static bool isGhostZoneLabel(String label) {
    final t = label.trim();
    return t.startsWith('👻') ||
        (!t.startsWith('📍') && !t.startsWith('🔒'));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHex) ...[
          _GhostHexIcon(size: size),
          if (showPill) SizedBox(width: size * 0.35),
        ],
        if (showPill) _GhostPill(fontSize: size * 0.58),
      ],
    );
  }
}

/// Linha compacta: badge + texto de zona (sem emoji legacy).
class AqxGhostZoneLabel extends StatelessWidget {
  const AqxGhostZoneLabel({
    super.key,
    required this.label,
    this.style,
    this.badgeSize = 10,
    this.maxLines = 1,
  });

  final String label;
  final TextStyle? style;
  final double badgeSize;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final clean = AqxGhostModeBadge.stripLegacyPrefix(label);
    if (!AqxGhostModeBadge.isGhostZoneLabel(label)) {
      return Text(label, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AqxGhostModeBadge(size: badgeSize, showPill: false),
        SizedBox(width: badgeSize * 0.4),
        Flexible(
          child: Text(
            clean,
            style: style,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _GhostHexIcon extends StatelessWidget {
  const _GhostHexIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GhostHexPainter(),
    );
  }
}

class _GhostHexPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.44;

    final hex = Path();
    for (var i = 0; i < 6; i++) {
      final a = (math.pi / 3) * i - math.pi / 2;
      final x = cx + r * math.cos(a);
      final y = cy + r * math.sin(a);
      if (i == 0) {
        hex.moveTo(x, y);
      } else {
        hex.lineTo(x, y);
      }
    }
    hex.close();

    canvas.drawPath(hex, Paint()..color = const Color(0xFF030F1A));
    canvas.drawPath(
      hex,
      Paint()
        ..color = _kCyan.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.06,
    );
    canvas.drawPath(
      hex,
      Paint()
        ..color = _kCyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.09,
    );

    final ghost = Paint()..color = _kCyan.withValues(alpha: 0.88);
    canvas.drawCircle(Offset(cx, cy - size.height * 0.07), size.width * 0.17, ghost);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + size.height * 0.1),
        width: size.width * 0.34,
        height: size.height * 0.26,
      ),
      ghost,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GhostPill extends StatelessWidget {
  const _GhostPill({required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize * 0.75,
        vertical: fontSize * 0.25,
      ),
      decoration: BoxDecoration(
        color: _kAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _kAmber.withValues(alpha: 0.4)),
      ),
      child: Text(
        'GHOST',
        style: GoogleFonts.shareTechMono(
          fontSize: fontSize,
          color: _kAmber,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
