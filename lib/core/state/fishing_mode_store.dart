import 'package:flutter/foundation.dart';

/// Estado partilhado COSTA/MAR ↔ RIO/BARRAGEM entre Oráculo e Mapa.
class FishingModeStore {
  FishingModeStore._();
  static final FishingModeStore instance = FishingModeStore._();

  /// `true` = Rio / Barragem · `false` = Costa / Mar (default).
  final ValueNotifier<bool> isRio = ValueNotifier<bool>(false);
}
