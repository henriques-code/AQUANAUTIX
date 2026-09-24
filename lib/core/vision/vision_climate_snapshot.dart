import 'package:flutter/foundation.dart';

/// Condições meteorológicas compactas para o card CLIMA do Vision Scanner.
@immutable
class VisionClimateSnapshot {
  const VisionClimateSnapshot({
    required this.locationLabel,
    required this.usedGps,
    this.temperatureC,
    this.conditionText = '—',
    this.weatherCode,
    this.windKmh,
    this.waveHeightM,
    this.tideHeightM,
    this.tideRising = true,
  });

  final String locationLabel;
  final bool usedGps;
  final double? temperatureC;
  final String conditionText;
  final int? weatherCode;
  final double? windKmh;
  final double? waveHeightM;
  final double? tideHeightM;
  final bool tideRising;

  bool get hasLiveData => temperatureC != null;

  static const demo = VisionClimateSnapshot(
    locationLabel: 'Cascais, Portugal',
    usedGps: false,
    temperatureC: 18,
    conditionText: 'Céu limpo',
    weatherCode: 0,
    windKmh: 14,
    waveHeightM: 0.6,
    tideHeightM: 1.2,
    tideRising: true,
  );
}
