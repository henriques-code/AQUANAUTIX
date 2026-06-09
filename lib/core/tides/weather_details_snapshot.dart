import 'dart:math' as math;

/// Dados agregados para a grelha «Detalhes de meteorologia» no Oráculo.
class WeatherDetailsSnapshot {
  const WeatherDetailsSnapshot({
    required this.fetchedAt,
    this.airTempC,
    this.tempSparkline = const [],
    this.feelsLikeC,
    this.humidityPct,
    this.dewPointC,
    this.cloudPct,
    this.precipNext24hMm,
    this.windSpeedKmh,
    this.windGustKmh,
    this.windDirDeg,
    this.uvIndex,
    this.uvMaxTomorrow,
    this.aqi,
    this.pollenGrass,
    this.visibilityKm,
    this.pressureHpa,
    this.pressureSparkline = const [],
    this.sunrise,
    this.sunset,
    this.waveHeightM,
    this.tideHeightM,
    this.tideTrendPt = '',
    this.tideRangeM,
    this.tideSparkline = const [],
    this.tidePhasePt = '',
    this.windSparkline = const [],
    this.waveSparkline = const [],
    this.wavePeriodS,
    this.oceanCurrentMs,
    this.oceanCurrentDirDeg,
    this.currentSparkline = const [],
    this.moonPct = 0,
    this.moonPhaseLabel = '',
    this.humiditySparkline = const [],
  });

  final DateTime fetchedAt;
  final double? airTempC;
  final List<double> tempSparkline;
  final double? feelsLikeC;
  final double? humidityPct;
  final double? dewPointC;
  final double? cloudPct;
  final double? precipNext24hMm;
  final double? windSpeedKmh;
  final double? windGustKmh;
  final int? windDirDeg;
  final double? uvIndex;
  final double? uvMaxTomorrow;
  final int? aqi;
  final double? pollenGrass;
  final double? visibilityKm;
  final double? pressureHpa;
  final List<double> pressureSparkline;
  final DateTime? sunrise;
  final DateTime? sunset;
  final double? waveHeightM;
  final double? tideHeightM;
  final String tideTrendPt;
  final double? tideRangeM;
  final List<double> tideSparkline;
  final String tidePhasePt;
  final List<double> windSparkline;
  final List<double> waveSparkline;
  final double? wavePeriodS;
  final double? oceanCurrentMs;
  final int? oceanCurrentDirDeg;
  final List<double> currentSparkline;
  final int moonPct;
  final String moonPhaseLabel;
  final List<double> humiditySparkline;

  static String windCardinalPt(int? deg) {
    if (deg == null) return '—';
    const dirs = [
      'N', 'NNO', 'NO', 'ONO', 'O', 'OSO', 'SO', 'SSO',
      'S', 'SSE', 'SE', 'ESE', 'E', 'ENE', 'NE', 'NNE',
    ];
    final idx = ((deg + 11.25) / 22.5).floor() % 16;
    return dirs[idx];
  }

  static ({int force, String label}) beaufortPt(double? kmh) {
    if (kmh == null) return (force: 0, label: '—');
    final v = kmh;
    if (v < 1) return (force: 0, label: 'Calma');
    if (v < 6) return (force: 1, label: 'Brisa fraca');
    if (v < 12) return (force: 2, label: 'Brisa ligeira');
    if (v < 20) return (force: 3, label: 'Brisa moderada');
    if (v < 29) return (force: 4, label: 'Brisa fresca');
    if (v < 39) return (force: 5, label: 'Vento fresco');
    if (v < 50) return (force: 6, label: 'Vento forte');
    return (force: 7, label: 'Vento muito forte');
  }

  static String uvLabelPt(double? uv) {
    if (uv == null) return '—';
    if (uv < 3) return 'Baixo';
    if (uv < 6) return 'Moderado';
    if (uv < 8) return 'Elevado';
    if (uv < 11) return 'Muito elevado';
    return 'Extremo';
  }

  static String aqiLabelPt(int? aqi) {
    if (aqi == null) return '—';
    if (aqi <= 20) return 'Boa';
    if (aqi <= 40) return 'Razoável';
    if (aqi <= 60) return 'Moderada';
    if (aqi <= 80) return 'Fraca';
    if (aqi <= 100) return 'Má';
    return 'Muito má';
  }

  static String pollenLabelPt(double? v) {
    if (v == null) return '—';
    if (v < 30) return 'Baixo';
    if (v < 60) return 'Moderado';
    if (v < 80) return 'Elevado';
    return 'Muito elevado';
  }

  static String cloudLabelPt(double? pct) {
    if (pct == null) return '—';
    if (pct < 10) return 'Sol';
    if (pct < 40) return 'Poucas nuvens';
    if (pct < 70) return 'Parcialmente nublado';
    return 'Nublado';
  }

  static String tempTrendLabel(List<double> spark) {
    if (spark.length < 2) return 'Estável';
    final d = spark.last - spark.first;
    if (d > 1.5) return 'A subir';
    if (d < -1.5) return 'A descer';
    return 'Estável';
  }

  static String pressureTrendLabel(List<double> spark) {
    if (spark.length < 2) return 'Estável';
    final d = spark.last - spark.first;
    if (d > 2) return 'A subir';
    if (d < -2) return 'A cair lentamente';
    return 'Estável';
  }

  static String tidePhaseFromTrend(String trend, List<double> spark) {
    final t = trend.toLowerCase();
    if (t.contains('subir') || t.contains('↑') || t.contains('rising')) {
      return 'Enchente';
    }
    if (t.contains('descer') || t.contains('↓') || t.contains('falling')) {
      return 'Vazante';
    }
    if (spark.length >= 2) {
      final d = spark.last - spark.first;
      if (d > 0.03) return 'Enchente';
      if (d < -0.03) return 'Vazante';
    }
    return 'Vau-mar';
  }

  static String currentLabelPt(double? ms) {
    if (ms == null) return '—';
    if (ms < 0.15) return 'Fraca';
    if (ms < 0.4) return 'Moderada';
    if (ms < 0.8) return 'Forte';
    return 'Muito forte';
  }

  static double? currentKmh(double? ms) =>
      ms != null ? ms * 3.6 : null;

  static double? estimateDewPoint(double? tempC, double? rh) {
    if (tempC == null || rh == null || rh <= 0) return null;
    const a = 17.27;
    const b = 237.7;
    final alpha =
        (a * tempC) / (b + tempC) + math.log(rh.clamp(0.001, 100.0) / 100.0);
    return (b * alpha) / (a - alpha);
  }

  /// Fallback mínimo quando a API detalhada falha mas há bundle + condições actuais.
  factory WeatherDetailsSnapshot.fallback({
    required DateTime fetchedAt,
    double? airTempC,
    double? pressureHpa,
    double? windSpeedKmh,
    int? windDirDeg,
    double? waveHeightM,
    double? tideHeightM,
    String tideTrendPt = '',
    double? tideRangeM,
    String tidePhasePt = '',
    double? oceanCurrentMs,
    int? oceanCurrentDirDeg,
    int moonPct = 0,
    String moonPhaseLabel = '',
  }) {
    return WeatherDetailsSnapshot(
      fetchedAt: fetchedAt,
      airTempC: airTempC,
      feelsLikeC: airTempC,
      pressureHpa: pressureHpa,
      windSpeedKmh: windSpeedKmh,
      windDirDeg: windDirDeg,
      waveHeightM: waveHeightM,
      tideHeightM: tideHeightM,
      tideTrendPt: tideTrendPt,
      tideRangeM: tideRangeM,
      tidePhasePt: tidePhasePt.isNotEmpty
          ? tidePhasePt
          : tidePhaseFromTrend(tideTrendPt, const []),
      oceanCurrentMs: oceanCurrentMs,
      oceanCurrentDirDeg: oceanCurrentDirDeg,
      moonPct: moonPct,
      moonPhaseLabel: moonPhaseLabel,
      cloudPct: 20,
      humidityPct: 55,
      precipNext24hMm: 0,
      uvIndex: 3,
      visibilityKm: 10,
    );
  }
}
