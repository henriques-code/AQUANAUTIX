import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../_shared.dart';

/// Feedback táctil + som de click (Oráculo mix A+B).
class AqxTapFeedback {
  AqxTapFeedback._();

  static void click({bool primary = false}) {
    if (primary) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    SystemSound.play(SystemSoundType.click);
  }
}

/// Base — scale 3D ao premir.
class _AqxPressableShell extends StatefulWidget {
  const _AqxPressableShell({
    required this.onTap,
    required this.builder,
    this.primary = false,
  });

  final VoidCallback? onTap;
  final bool primary;
  final Widget Function(bool pressed) builder;

  @override
  State<_AqxPressableShell> createState() => _AqxPressableShellState();
}

class _AqxPressableShellState extends State<_AqxPressableShell> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: () {
        AqxTapFeedback.click(primary: widget.primary);
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: AnimatedSlide(
          offset: _pressed ? const Offset(0, 0.02) : Offset.zero,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: widget.builder(_pressed),
        ),
      ),
    );
  }
}

List<BoxShadow> _neonShadows({required bool pressed, required bool selected}) {
  final glow = selected || !pressed ? 0.42 : 0.22;
  final lift = pressed ? 2.0 : 6.0;
  return [
    BoxShadow(
      color: kCyan.withValues(alpha: glow),
      blurRadius: pressed ? 10 : 18,
      offset: Offset(0, lift),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.55),
      blurRadius: pressed ? 3 : 6,
      offset: Offset(0, pressed ? 1 : 3),
    ),
  ];
}

List<BoxShadow> _glassShadows({required bool pressed, required bool selected}) {
  return [
    BoxShadow(
      color: (selected ? kCyan : Colors.black).withValues(
        alpha: selected ? (pressed ? 0.25 : 0.35) : 0.4,
      ),
      blurRadius: pressed ? 6 : 12,
      offset: Offset(0, pressed ? 1 : 4),
    ),
  ];
}

/// Opção A — CTA primário neon 3D (ex.: REGISTAR CAPTURA).
class AqxNeonButton extends StatefulWidget {
  const AqxNeonButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.pulse = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool pulse;

  @override
  State<AqxNeonButton> createState() => _AqxNeonButtonState();
}

class _AqxNeonButtonState extends State<AqxNeonButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.pulse) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        final pulse = widget.pulse ? 0.88 + 0.12 * _pulseCtrl.value : 1.0;
        return Opacity(
          opacity: 0.92 + 0.08 * (widget.pulse ? _pulseCtrl.value : 1.0),
          child: Transform.scale(scale: pulse, child: child),
        );
      },
      child: _AqxPressableShell(
        onTap: widget.onTap,
        primary: true,
        builder: (pressed) => Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(kCyan, Colors.white, 0.22)!,
                kCyan,
                Color.lerp(kCyan, const Color(0xFF00B8C4), 0.35)!,
              ],
            ),
            boxShadow: _neonShadows(pressed: pressed, selected: true),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 17, color: Colors.black87),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  style: mono(9, c: Colors.black87, ls: 0.35),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opção B — CTA secundário glass 3D (ex.: VER NO MAPA).
class AqxGlassButton extends StatelessWidget {
  const AqxGlassButton({
    super.key,
    required this.label,
    this.icon,
    required this.onTap,
    this.expand = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final btn = _AqxPressableShell(
      onTap: onTap,
      builder: (pressed) => Container(
        padding: EdgeInsets.symmetric(
          vertical: icon != null ? 10 : 9,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.1),
              kCard.withValues(alpha: 0.92),
              Colors.black.withValues(alpha: 0.25),
            ],
          ),
          border: Border.all(
            color: kCyan.withValues(alpha: pressed ? 0.65 : 0.45),
            width: 1.2,
          ),
          boxShadow: _glassShadows(pressed: pressed, selected: false),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: kCyan),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                style: mono(9, c: kCyan, ls: 0.3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
    return expand ? btn : btn;
  }
}

/// Opção B — chip espécie / segmento (Barbo, COSTA, …).
class AqxGlassChip extends StatelessWidget {
  const AqxGlassChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _AqxPressableShell(
      onTap: onTap,
      builder: (pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 6 : 7,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 9 : 20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: selected
                ? [
                    kCyan.withValues(alpha: 0.28),
                    kCyan.withValues(alpha: 0.12),
                    kCard,
                  ]
                : [
                    Colors.white.withValues(alpha: 0.07),
                    kCard.withValues(alpha: 0.95),
                    Colors.black.withValues(alpha: 0.2),
                  ],
          ),
          border: Border.all(
            color: selected
                ? kCyan.withValues(alpha: pressed ? 1 : 0.85)
                : kCyan.withValues(alpha: 0.22),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? _neonShadows(pressed: pressed, selected: true)
              : _glassShadows(pressed: pressed, selected: false),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: compact ? 18 : 14,
                color: selected ? kCyan : kHint,
              ),
              SizedBox(width: compact ? 6 : 5),
            ],
            Text(
              label,
              style: compact
                  ? orb(
                      12,
                      c: selected ? kCyan : kHint,
                      fw: selected ? FontWeight.w700 : FontWeight.w400,
                      ls: 1.1,
                    )
                  : ibm(
                      12,
                      c: selected ? kCyan : kHint,
                      fw: selected ? FontWeight.w700 : FontWeight.w400,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Toggle COSTA / RIO — pill glass deslizante (Opção B).
class AqxGlassSegmentToggle extends StatelessWidget {
  const AqxGlassSegmentToggle({
    super.key,
    required this.leftIcon,
    required this.leftLabel,
    required this.rightIcon,
    required this.rightLabel,
    required this.rightSelected,
    required this.onLeft,
    required this.onRight,
    this.height = 34,
  });

  final IconData leftIcon;
  final String leftLabel;
  final IconData rightIcon;
  final String rightLabel;
  final bool rightSelected;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kCyan.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment:
                rightSelected ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        kCyan.withValues(alpha: 0.22),
                        kCyan.withValues(alpha: 0.08),
                      ],
                    ),
                    border: Border.all(color: kCyan.withValues(alpha: 0.55)),
                    boxShadow: _glassShadows(pressed: false, selected: true),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _SegmentTap(
                  icon: leftIcon,
                  label: leftLabel,
                  selected: !rightSelected,
                  onTap: onLeft,
                ),
              ),
              Expanded(
                child: _SegmentTap(
                  icon: rightIcon,
                  label: rightLabel,
                  selected: rightSelected,
                  onTap: onRight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentTap extends StatelessWidget {
  const _SegmentTap({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _AqxPressableShell(
      onTap: onTap,
      builder: (pressed) => SizedBox(
        height: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? kCyan : kHint.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: orb(
                12,
                c: selected ? kCyan : kHint,
                fw: selected ? FontWeight.w700 : FontWeight.w400,
                ls: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Neon primário compacto (ex.: PARTILHAR 👻).
class AqxNeonCompactButton extends StatelessWidget {
  const AqxNeonCompactButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _AqxPressableShell(
      onTap: onTap,
      primary: true,
      builder: (pressed) => Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [
              kCyan.withValues(alpha: 0.35),
              kCyan.withValues(alpha: 0.18),
            ],
          ),
          border: Border.all(color: kCyan.withValues(alpha: 0.7)),
          boxShadow: _neonShadows(pressed: pressed, selected: true),
        ),
        child: Center(
          child: Text(
            label,
            style: mono(9, c: kCyan, ls: 0.3),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
