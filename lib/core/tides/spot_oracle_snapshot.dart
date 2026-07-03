/// Oráculo compacto para um spot fixo (coordenadas) — badge e sheets.
class SpotOracleSnapshot {
  const SpotOracleSnapshot({
    required this.lat,
    required this.lon,
    required this.score,
    required this.statusLabel,
    required this.statusDesc,
    required this.windowHours,
    required this.moonPct,
    required this.fetchedAt,
    this.isRiver = false,
    this.tideHeightM,
    this.tempC,
    this.pressureHpa,
    this.tideTrendPt = '',
    this.pressureTrendPt = '',
    this.moonPhaseShortPt = '',
    this.tempTrendPt = '',
  });

  final double lat;
  final double lon;
  final int score;
  final String statusLabel;
  final String statusDesc;
  final String windowHours;
  final int moonPct;
  final DateTime fetchedAt;
  final bool isRiver;
  final double? tideHeightM;
  final double? tempC;
  final double? pressureHpa;
  final String tideTrendPt;
  final String pressureTrendPt;
  final String moonPhaseShortPt;
  final String tempTrendPt;

  /// Chave estável para cache (3 casas decimais ≈ 100 m).
  static String cacheKey({
    required double lat,
    required double lon,
    required String lang,
    required bool isRiver,
  }) =>
      '$lang|${isRiver ? 'river' : 'marine'}|'
      '${lat.toStringAsFixed(3)},${lon.toStringAsFixed(3)}';
}
