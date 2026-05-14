import 'species_models.dart';

/// Resultado de comparação comprimento vs mínimo legal (subset app).
enum SizeComplianceKind {
  legal,
  belowMinimum,
  indeterminate,
}

class SizeComplianceResult {
  const SizeComplianceResult({
    required this.kind,
    required this.message,
    this.minimumCm,
    this.minimumRule,
  });

  final SizeComplianceKind kind;
  final String message;
  final int? minimumCm;
  final String? minimumRule;

  bool get isLegal => kind == SizeComplianceKind.legal;
  bool get isIllegal => kind == SizeComplianceKind.belowMinimum;
}

abstract class SpeciesCompliance {
  /// Extrai mínimo em cm de strings tipo `36cm`, `32 cm`. Retorna null se não aplicável.
  static int? parseMinCm(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.isEmpty || s == '—' || s == '-') return null;
    if (s.contains('sem mínimo')) return null;
    final m = RegExp(r'(\d+)\s*cm').firstMatch(s);
    if (m == null) return null;
    return int.tryParse(m.group(1)!);
  }

  /// Extrai gramas mínimas (ex. polvo `750g`).
  static int? parseMinGrams(String raw) {
    final m = RegExp(r'(\d+)\s*g').firstMatch(raw.trim().toLowerCase());
    if (m == null) return null;
    return int.tryParse(m.group(1)!);
  }

  /// Compara [measuredLengthCm] com mínimo do país (`PT` / `ES`). Espécies só em peso → indeterminado sem [measuredWeightG].
  static SizeComplianceResult evaluateLength({
    required SpeciesRecord species,
    required String country,
    double? measuredLengthCm,
    double? measuredWeightG,
  }) {
    final cc = country.toUpperCase();
    final minRule = cc == 'ES' ? species.minES : species.minPT;

    final minCm = parseMinCm(minRule);
    final minG = parseMinGrams(minRule);

    if (minCm != null) {
      if (measuredLengthCm == null) {
        return SizeComplianceResult(
          kind: SizeComplianceKind.indeterminate,
          message: 'Mede o comprimento total para comparar com o mínimo ($minRule).',
          minimumCm: minCm,
          minimumRule: minRule,
        );
      }
      final len = measuredLengthCm.round();
      if (len < minCm) {
        return SizeComplianceResult(
          kind: SizeComplianceKind.belowMinimum,
          message: 'Abaixo do mínimo legal ($minRule) para ${cc == 'ES' ? 'Espanha' : 'Portugal'}. Devolução obrigatória.',
          minimumCm: minCm,
          minimumRule: minRule,
        );
      }
      return SizeComplianceResult(
        kind: SizeComplianceKind.legal,
        message: 'Comprimento estimado ≥ mínimo legal ($minRule) em ${cc == 'ES' ? 'Espanha' : 'Portugal'} (referência app).',
        minimumCm: minCm,
        minimumRule: minRule,
      );
    }

    if (minG != null) {
      if (measuredWeightG == null) {
        return SizeComplianceResult(
          kind: SizeComplianceKind.indeterminate,
          message: 'Mínimo em peso ($minRule). Indica o peso estimado para validação.',
          minimumRule: minRule,
        );
      }
      final w = measuredWeightG.round();
      if (w < minG) {
        return SizeComplianceResult(
          kind: SizeComplianceKind.belowMinimum,
          message: 'Abaixo do mínimo legal ($minRule) por peso.',
          minimumRule: minRule,
        );
      }
      return SizeComplianceResult(
        kind: SizeComplianceKind.legal,
        message: 'Peso estimado ≥ mínimo legal ($minRule) (referência app).',
        minimumRule: minRule,
      );
    }

    return SizeComplianceResult(
      kind: SizeComplianceKind.indeterminate,
      message: 'Sem mínimo comparável automático ($minRule). Verifica legislação oficial.',
      minimumRule: minRule,
    );
  }
}
