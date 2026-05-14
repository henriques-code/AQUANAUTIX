/// Ponto horário só meteorologia (modo rio / interior — sem maré).
class ForecastWeatherHour {
  const ForecastWeatherHour({
    required this.time,
    this.temperatureC,
    this.pressureHpa,
    this.cloudCoverPct,
    this.precipitationMm,
  });

  final DateTime time;
  final double? temperatureC;
  final double? pressureHpa;
  /// Cobertura nuvens 0–100 (%).
  final double? cloudCoverPct;
  /// Precipitação por hora (mm).
  final double? precipitationMm;
}

/// Ponto horário alinhado maré + tempo (quando disponível).
class MarineHourPoint {
  const MarineHourPoint({
    required this.time,
    required this.seaLevelMslM,
    this.temperatureC,
    this.pressureHpa,
  });

  final DateTime time;
  final double seaLevelMslM;
  final double? temperatureC;
  final double? pressureHpa;
}

/// Preia-mar / baixa-mar detectados na série horária.
class TideExtremum {
  const TideExtremum({
    required this.time,
    required this.heightM,
    required this.isHigh,
  });

  final DateTime time;
  final double heightM;
  final bool isHigh;

  String get labelPt => isHigh ? 'Preia-mar' : 'Baixa-mar';
}

class TideDayCurve {
  const TideDayCurve({
    required this.date,
    required this.points,
    required this.extrema,
  });

  final DateTime date;
  final List<MarineHourPoint> points;
  final List<TideExtremum> extrema;
}
