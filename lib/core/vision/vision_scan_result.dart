import 'package:flutter/foundation.dart';

import '../species/species_models.dart';

/// Resultado estruturado do Vision (OpenAI ou fallback demo).
@immutable
class VisionScanResult {
  const VisionScanResult({
    this.matchedSpecies,
    this.rawScientific,
    this.lengthCm,
    this.weightKg,
    required this.confidence,
    required this.usedFallbackDemo,
    this.errorMessage,
  });

  final SpeciesRecord? matchedSpecies;
  final String? rawScientific;
  final double? lengthCm;
  final double? weightKg;
  final int confidence;
  final bool usedFallbackDemo;
  final String? errorMessage;

  double? get weightG => weightKg != null ? weightKg! * 1000 : null;

  factory VisionScanResult.demo(SpeciesRecord species) {
    return VisionScanResult(
      matchedSpecies: species,
      rawScientific: species.cientifico,
      lengthCm: 58.0,
      weightKg: 3.10,
      confidence: 92,
      usedFallbackDemo: true,
    );
  }

  factory VisionScanResult.withDemoFallback({
    required SpeciesRecord demoSpecies,
    required String errorMessage,
  }) {
    return VisionScanResult(
      matchedSpecies: demoSpecies,
      rawScientific: demoSpecies.cientifico,
      lengthCm: 58.0,
      weightKg: 3.10,
      confidence: 92,
      usedFallbackDemo: true,
      errorMessage: errorMessage,
    );
  }
}
