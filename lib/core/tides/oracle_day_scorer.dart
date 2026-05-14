import 'dart:math' as math;

import 'marine_bundle.dart';
import 'moon_phase.dart';
import 'tide_analysis.dart';

double _smooth01(double t) => t * t * (3 - 2 * t);

/// Índice diário rio (sem maré): lua + pressão estável + céu + penalização chuva.
int riverOracleDayScore({
  required List<ForecastWeatherHour> dayHours,
  required DateTime dayDate,
}) {
  if (dayHours.length < 4) return 48;
  final noonLocal = DateTime(dayDate.year, dayDate.month, dayDate.day, 12);
  final moonScore = moonFishingFactor(noonLocal) * 34;

  final pressures =
      dayHours.map((e) => e.pressureHpa).whereType<double>().toList();
  double pressureScore = 18;
  if (pressures.length >= 4) {
    final mean = pressures.reduce((a, b) => a + b) / pressures.length;
    if (mean.abs() > 1e-6) {
      var varSum = 0.0;
      for (final p in pressures) {
        varSum += (p - mean) * (p - mean);
      }
      final std = math.sqrt(varSum / pressures.length);
      final cv = (std / mean).abs();
      pressureScore = (1 - (cv / 0.012).clamp(0.0, 1.0)) * 28;
    }
  }

  final clouds =
      dayHours.map((e) => e.cloudCoverPct).whereType<double>().toList();
  double cloudScore = 22;
  if (clouds.isNotEmpty) {
    final avg = clouds.reduce((a, b) => a + b) / clouds.length;
    cloudScore = (1 - (avg / 100).clamp(0.0, 1.0)) * 30;
  }

  final precipSum =
      dayHours.map((e) => e.precipitationMm ?? 0).fold(0.0, (a, b) => a + b);
  final rainPenalty = (precipSum * 6).clamp(0.0, 28.0);

  final raw = moonScore + pressureScore + cloudScore - rainPenalty;
  return raw.round().clamp(0, 100);
}

Map<DateTime, int> buildRiverDayScoreMap(List<ForecastWeatherHour> all) {
  final days = <DateTime>{};
  for (final p in all) {
    days.add(dateOnly(p.time));
  }
  final map = <DateTime, int>{};
  for (final d in days) {
    final hrs = forecastHoursForDay(all, d);
    if (hrs.length < 2) continue;
    map[d] = riverOracleDayScore(dayHours: hrs, dayDate: d);
  }
  return map;
}

/// Melhor hora local para pesca em rio (menos nuvens + chuva leve).
int? bestHourForRiver(List<ForecastWeatherHour> day) {
  if (day.length < 4) return null;
  var bestH = day[1].time.hour;
  var bestV = double.negativeInfinity;
  for (var i = 1; i < day.length - 1; i++) {
    final c = day[i].cloudCoverPct;
    final r = day[i].precipitationMm ?? 0;
    if (c == null) continue;
    final h = day[i].time.hour;
    double dawnDusk = 1;
    if ((h >= 5 && h <= 9) || (h >= 17 && h <= 21)) dawnDusk = 1.08;
    final score = (100 - c) * dawnDusk / (1 + r * 8);
    if (score > bestV) {
      bestV = score;
      bestH = h;
    }
  }
  return bestH;
}

/// Normaliza [r] para 0–1 face à distribuição de amplitudes diárias na janela carregada.
double _rangePercentile(double r, List<double> sortedRanges) {
  if (sortedRanges.isEmpty) return 0.5;
  var less = 0;
  for (final x in sortedRanges) {
    if (x < r - 1e-9) less++;
  }
  return (less / sortedRanges.length).clamp(0.0, 1.0);
}

/// Score diário 0–100: amplitude de maré (vs janela local) + lua + pressão estável.
int oracleDayScoreForDay({
  required List<MarineHourPoint> dayHours,
  required DateTime dayDate,
  required List<double> sortedDailyRanges,
}) {
  if (dayHours.isEmpty) return 0;
  final heights = dayHours.map((e) => e.seaLevelMslM).toList();
  final range = heights.reduce(math.max) - heights.reduce(math.min);
  final pr = _rangePercentile(range, sortedDailyRanges);
  final rangeScore = 44 * _smooth01(pr);

  final noonLocal = DateTime(dayDate.year, dayDate.month, dayDate.day, 12);
  final moonScore = moonFishingFactor(noonLocal) * 28;

  final pressures = dayHours.map((e) => e.pressureHpa).whereType<double>().toList();
  double pressureScore = 18;
  if (pressures.length >= 4) {
    final mean = pressures.reduce((a, b) => a + b) / pressures.length;
    if (mean.abs() > 1e-6) {
      var varSum = 0.0;
      for (final p in pressures) {
        varSum += (p - mean) * (p - mean);
      }
      final std = math.sqrt(varSum / pressures.length);
      final cv = (std / mean).abs();
      pressureScore = (1 - (cv / 0.012).clamp(0.0, 1.0)) * 24;
    }
  }

  final raw = rangeScore + moonScore + pressureScore;
  return raw.round().clamp(0, 100);
}

Map<DateTime, int> buildDayScoreMap(List<MarineHourPoint> all) {
  final days = <DateTime>{};
  for (final p in all) {
    days.add(dateOnly(p.time));
  }

  final rangeByDay = <DateTime, double>{};
  for (final d in days) {
    final hrs = hoursForDay(all, d);
    if (hrs.isEmpty) continue;
    final heights = hrs.map((e) => e.seaLevelMslM).toList();
    rangeByDay[d] = heights.reduce(math.max) - heights.reduce(math.min);
  }

  final sortedRanges = rangeByDay.values.toList()..sort();

  final map = <DateTime, int>{};
  for (final d in days) {
    final hrs = hoursForDay(all, d);
    if (hrs.isEmpty) continue;
    map[d] = oracleDayScoreForDay(
      dayHours: hrs,
      dayDate: d,
      sortedDailyRanges: sortedRanges,
    );
  }
  return map;
}
