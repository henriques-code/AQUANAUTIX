import 'package:flutter/material.dart';

import '../_shared.dart';

/// Cabeçalho do Oráculo — localização + coords + toggle COSTA/RIO (mockup).
class OracleMockupHeader extends StatelessWidget {
  const OracleMockupHeader({
    super.key,
    required this.placeLabel,
    required this.coordsLabel,
    required this.costaLabel,
    required this.rioLabel,
    required this.rioMode,
    required this.onCosta,
    required this.onRio,
    this.isRioIcon = false,
    this.locationFromGps = true,
  });

  final String placeLabel;
  final String coordsLabel;
  final String costaLabel;
  final String rioLabel;
  final bool rioMode;
  final VoidCallback onCosta;
  final VoidCallback onRio;
  final bool isRioIcon;
  final bool locationFromGps;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isRioIcon
              ? Icons.waves_rounded
              : (locationFromGps
                  ? Icons.location_on_rounded
                  : Icons.place_outlined),
          size: 22,
          color: kCyan,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                placeLabel,
                style: ibm(16, c: Colors.white, fw: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (coordsLabel.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  coordsLabel,
                  style: mono(10, c: kHint, ls: 0.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        _ModeToggle(
          costaLabel: costaLabel,
          rioLabel: rioLabel,
          rioMode: rioMode,
          onCosta: onCosta,
          onRio: onRio,
        ),
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.costaLabel,
    required this.rioLabel,
    required this.rioMode,
    required this.onCosta,
    required this.onRio,
  });

  final String costaLabel;
  final String rioLabel;
  final bool rioMode;
  final VoidCallback onCosta;
  final VoidCallback onRio;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kCyan.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pill(costaLabel, !rioMode, onCosta),
          _pill(rioLabel, rioMode, onRio),
        ],
      ),
    );
  }

  Widget _pill(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? kCyan.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: selected ? kCyan : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: mono(9, c: selected ? kCyan : kHint, ls: 0.5).copyWith(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Barra de pesquisa / fonte GPS — mockup «Posição GPS (ao vivo)».
class OracleGpsSearchPill extends StatelessWidget {
  const OracleGpsSearchPill({
    super.key,
    required this.label,
    required this.onTap,
    this.leadingIcon = Icons.search_rounded,
    this.trailing,
    this.highlight = false,
    this.warning = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData leadingIcon;
  final Widget? trailing;
  final bool highlight;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final accent = warning ? kAmber : (highlight ? kAmber : kHint);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1520),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: accent.withValues(alpha: highlight || warning ? 0.45 : 0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(leadingIcon, size: 18, color: accent.withValues(alpha: 0.85)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: ibm(13, c: highlight || warning ? accent : kHint),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
