// lib/core/widgets/map_legend_widget.dart
//
// Legenda do mapa AQUANAUTIX — pins unificados [AqxUnifiedPin]
// Toggle via ícone layers. Posição: canto inferior-esquerdo do mapa.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'aquanautix_pins.dart';

// ── Cores internas (alinhadas com Design System Midnight Deep Sea) ──
const _kBg     = Color(0xFF071428);
const _kCyan   = Color(0xFF00F5FF);

class MapLegendWidget extends StatefulWidget {
  final bool isRiver; // ajusta labels COSTA vs RIO

  const MapLegendWidget({super.key, this.isRiver = false});

  @override
  State<MapLegendWidget> createState() => _MapLegendWidgetState();
}

class _MapLegendWidgetState extends State<MapLegendWidget>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _ctrl.forward();
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<double>(begin: 8, end: 0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _ctrl.forward(from: 0);
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Botão toggle ──────────────────────────────────────
        GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kBg.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kCyan.withValues(alpha: 0.40)),
              boxShadow: [BoxShadow(color: _kCyan.withValues(alpha: 0.08), blurRadius: 8)],
            ),
            child: Icon(
              _expanded ? Icons.layers_rounded : Icons.layers_outlined,
              color: _kCyan,
              size: 18,
            ),
          ),
        ),

        // ── Painel da legenda (animado) ───────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: _expanded
              ? AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, child) => Opacity(
                    opacity: _fade.value,
                    child: Transform.translate(
                      offset: Offset(0, _slide.value),
                      child: child,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _kBg.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kCyan.withValues(alpha: 0.40)),
                        boxShadow: [BoxShadow(color: _kCyan.withValues(alpha: 0.06), blurRadius: 14)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LegendRow(
                            pin: const AqxUnifiedPin(
                              kind: AqxPinKind.free,
                              oracleScore: 58,
                              size: Size(22, 26),
                            ),
                            label: 'FREE',
                            sub: widget.isRiver ? 'Rios públicos' : 'Spots públicos',
                            color: aqxPinCyan,
                          ),
                          const SizedBox(height: 7),
                          _LegendRow(
                            pin: const AqxUnifiedPin(
                              kind: AqxPinKind.pro,
                              oracleScore: 72,
                              locked: true,
                              size: Size(22, 26),
                            ),
                            label: 'PRO',
                            sub: 'Spots verificados',
                            color: aqxPinBlue,
                          ),
                          const SizedBox(height: 7),
                          _LegendRow(
                            pin: const AqxUnifiedPin(
                              kind: AqxPinKind.elite,
                              oracleScore: 88,
                              locked: true,
                              size: Size(22, 26),
                            ),
                            label: 'ELITE',
                            sub: 'Spots premium',
                            color: aqxPinAmber,
                          ),
                          const SizedBox(height: 7),
                          _LegendRow(
                            pin: const AqxUnifiedPin(
                              kind: AqxPinKind.saved,
                              size: Size(22, 26),
                            ),
                            label: 'MEUS SPOTS',
                            sub: 'Os meus spots',
                            color: aqxPinRed,
                          ),
                          const SizedBox(height: 7),
                          _LegendRow(
                            pin: const AqxUnifiedPin(
                              kind: AqxPinKind.baitShop,
                              size: Size(22, 26),
                            ),
                            label: 'LOJA ISCO',
                            sub: 'Loja de isco',
                            color: aqxPinGreen,
                          ),
                          const SizedBox(height: 7),
                          _LegendRow(
                            pin: const AqxUnifiedPin(
                              kind: AqxPinKind.community,
                              isLive: true,
                              size: Size(22, 26),
                            ),
                            label: 'COMUNIDADE',
                            sub: 'Ghost Mode · anónimo',
                            color: aqxPinGold,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ── Linha individual da legenda ───────────────────────────
class _LegendRow extends StatelessWidget {
  final Widget pin;
  final String label;
  final String sub;
  final Color color;

  const _LegendRow({
    required this.pin,
    required this.label,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: FittedBox(fit: BoxFit.contain, child: pin),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.4,
                height: 1.1,
              ),
            ),
            Text(
              sub,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.55),
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
