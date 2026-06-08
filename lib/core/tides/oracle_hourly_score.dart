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
