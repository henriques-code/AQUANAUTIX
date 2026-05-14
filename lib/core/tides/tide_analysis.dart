import 'dart:math' as math;

import 'marine_bundle.dart';

/// Máximos/mínimos locais com refinamento parabólico no tempo (~sub-horário).
List<TideExtremum> detectTideExtrema(List<MarineHourPoint> series) {
  if (series.length < 3) return [];
  const eps = 1e-6;
  final out = <TideExtremum>[];
  for (var i = 1; i < series.length - 1; i++) {
    final y0 = series[i - 1].seaLevelMslM;
    final y1 = series[i].seaLevelMslM;
    final y2 = series[i + 1].seaLevelMslM;
    final isHigh = y1 > y0 && y1 > y2;
    final isLow = y1 < y0 && y1 < y2;
    if (!isHigh && !isLow) continue;

    // h(x) = y(x)-y1 em x ∈ {-1,0,1} horas; h(x)=A x² + B x
    final a = 0.5 * (y0 + y2 - 2 * y1);
    final b = 0.5 * (y2 - y0);
    DateTime tOut = series[i].time;
    var hOut = y1;
    if (a.abs() > eps) {
      var xv = -b / (2 * a);
      xv = xv.clamp(-0.95, 0.95);
      final dh = a * xv * xv + b * xv;
      hOut = y1 + dh;
      tOut = series[i].time.add(Duration(microseconds: (xv * 3600 * 1e6).round()));
    }

    final yMin = math.min(y0, math.min(y1, y2));
    final yMax = math.max(y0, math.max(y1, y2));
    if (hOut < yMin - 0.08 || hOut > yMax + 0.08) {
      out.add(TideExtremum(time: series[i].time, heightM: y1, isHigh: isHigh));
    } else {
      out.add(TideExtremum(time: tOut, heightM: hOut, isHigh: isHigh));
    }
  }
  return out;
}

bool sameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

List<MarineHourPoint> hoursForDay(List<MarineHourPoint> all, DateTime day) {
  return all.where((p) => sameCalendarDay(p.time, day)).toList()
    ..sort((x, y) => x.time.compareTo(y.time));
}

List<ForecastWeatherHour> forecastHoursForDay(
    List<ForecastWeatherHour> all, DateTime day) {
  return all.where((p) => sameCalendarDay(p.time, day)).toList()
    ..sort((x, y) => x.time.compareTo(y.time));
}

DateTime dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);

String? tidePhaseBetween(TideExtremum prev, TideExtremum next) {
  if (next.heightM > prev.heightM) return 'Enchente';
  if (next.heightM < prev.heightM) return 'Vazante';
  return null;
}
