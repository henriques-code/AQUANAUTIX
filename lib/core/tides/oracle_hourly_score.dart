import 'moon_phase.dart';
import 'marine_bundle.dart';
import '../../features/home/domain/entities/hourly_condition.dart';

/// Score horário simplificado (solunar + nuvens + chuva) — partilhado Oráculo/Início.
int oracleHourlyScore(ForecastWeatherHour h) {
  final hour = h.time.hour;
  final cloud = h.cloudCoverPct ?? 30;
  final rain = h.precipitationMm ?? 0;

  var dawnDusk = 1.0;
  if ((hour >= 5 && hour <= 9) || (hour >= 17 && hour <= 21)) {
    dawnDusk = 1.12;
  }

  final moon = moonFishingFactor(h.time) * 25;
  final cloudScore = (1 - cloud / 100) * 35 * dawnDusk;
  final rainPenalty = (rain * 8).clamp(0.0, 25.0);

  return (moon + cloudScore - rainPenalty).round().clamp(0, 100);
}

List<HourlyCondition> mapOracleHourlyTimeline(
  List<ForecastWeatherHour> series,
  DateTime now, {
  int hours = 12,
}) {
  final upcoming = series.where((h) => h.time.isAfter(now)).take(hours).toList();
  if (upcoming.isEmpty) return fallbackOracleHourlyTimeline(now, hours: hours);

  var bestIdx = 0;
  var bestScore = oracleHourlyScore(upcoming.first);
  final items = <HourlyCondition>[];
  for (var i = 0; i < upcoming.length; i++) {
    final h = upcoming[i];
    final score = oracleHourlyScore(h);
    if (score > bestScore) {
      bestScore = score;
      bestIdx = i;
    }
    items.add(HourlyCondition(
      hour: '${h.time.hour.toString().padLeft(2, '0')}:00',
      oracleScore: score,
    ));
  }
  return [
    for (var i = 0; i < items.length; i++)
      HourlyCondition(
        hour: items[i].hour,
        oracleScore: items[i].oracleScore,
        isBestHour: i == bestIdx,
      ),
  ];
}

List<HourlyCondition> fallbackOracleHourlyTimeline(
  DateTime now, {
  int hours = 12,
}) {
  final items = List.generate(hours, (i) {
    final t = now.add(Duration(hours: i + 1));
    final fake = ForecastWeatherHour(
      time: t,
      cloudCoverPct: 20.0 + (i * 5.0),
      precipitationMm: 0,
    );
    return HourlyCondition(
      hour: '${t.hour.toString().padLeft(2, '0')}:00',
      oracleScore: oracleHourlyScore(fake),
    );
  });
  var bestIdx = 0;
  var best = items.first.oracleScore;
  for (var i = 1; i < items.length; i++) {
    if (items[i].oracleScore > best) {
      best = items[i].oracleScore;
      bestIdx = i;
    }
  }
  return [
    for (var i = 0; i < items.length; i++)
      HourlyCondition(
        hour: items[i].hour,
        oracleScore: items[i].oracleScore,
        isBestHour: i == bestIdx,
      ),
  ];
}

/// Parse «07:00 -> 09:30» → (7, 9) inclusive.
(int?, int?) parseOracleWindowHours(String? window) {
  if (window == null || window.trim().isEmpty || window == '—') {
    return (null, null);
  }
  final re = RegExp(r'(\d{1,2}):\d{2}');
  final matches = re.allMatches(window).toList();
  if (matches.isEmpty) return (null, null);
  final start = int.tryParse(matches.first.group(1)!);
  final end =
      matches.length > 1 ? int.tryParse(matches[1].group(1)!) : start;
  return (start, end);
}

int _hourLabelToInt(String label) {
  final h = label.split(':').first.replaceAll('h', '');
  return int.tryParse(h) ?? -1;
}

bool _hourInWindow(int hour, int start, int end) {
  if (hour < 0) return false;
  if (start <= end) return hour >= start && hour <= end;
  return hour >= start || hour <= end;
}

/// Marca hora actual e janela de ouro sobre a timeline já calculada.
List<HourlyCondition> applyTimelineHighlights(
  List<HourlyCondition> hours, {
  required DateTime now,
  String? goldenWindowHours,
}) {
  if (hours.isEmpty) return hours;
  final (startH, endH) = parseOracleWindowHours(goldenWindowHours);
  final currentH = now.hour;

  return [
    for (final h in hours)
      HourlyCondition(
        hour: h.hour,
        oracleScore: h.oracleScore,
        isBestHour: h.isBestHour,
        isCurrentHour: _hourLabelToInt(h.hour) == currentH,
        isGoldenWindow: startH != null &&
            endH != null &&
            _hourInWindow(_hourLabelToInt(h.hour), startH, endH),
      ),
  ];
}
