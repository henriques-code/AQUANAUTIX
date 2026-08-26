import 'package:flutter/foundation.dart';

/// Dados para gerar imagem de partilha Vision (sem coordenadas exactas).
@immutable
class VisionSharePayload {
  const VisionSharePayload({
    required this.speciesEmoji,
    required this.speciesName,
    required this.confidence,
    required this.zoneLabel,
    this.photoBytes,
    this.weightLabel,
    this.lengthLabel,
    this.complianceLabel,
    this.captureDateLabel,
  });

  final Uint8List? photoBytes;
  final String speciesEmoji;
  final String speciesName;
  final int confidence;
  /// Zona fuzzy — nunca lat/lng exactos (Ghost Mode).
  final String zoneLabel;
  final String? weightLabel;
  final String? lengthLabel;
  final String? complianceLabel;
  final String? captureDateLabel;
}
