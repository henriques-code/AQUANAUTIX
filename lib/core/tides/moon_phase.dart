import 'dart:math' as math;

import 'julian_day.dart';

/// Fase sinódica 0 = nova, 0.5 ≈ cheia (JD + referência IAU).
double moonPhase01(DateTime local) {
  final utc = local.toUtc();
  return synodicMoonPhase01(utc);
}

/// 0–1: maior perto de nova e cheia (elongação mínima/máxima → actividade típica).
double moonFishingFactor(DateTime local) {
  final p = moonPhase01(local);
  return math.sin(2 * math.pi * p).abs();
}
