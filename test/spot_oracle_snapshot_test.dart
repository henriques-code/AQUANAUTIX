import 'package:aquanautix/core/l10n/aqx_l10n.dart';
import 'package:aquanautix/core/tides/marine_bundle.dart';
import 'package:aquanautix/core/tides/oracle_data_service.dart';
import 'package:aquanautix/core/tides/spot_oracle_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

List<MarineHourPoint> _syntheticMarineDay(DateTime day) {
  final base = DateTime(day.year, day.month, day.day);
  return List.generate(24, (h) {
    final t = base.add(Duration(hours: h));
    // Maré sinusoidal ~0.4 m amplitude
    final tide = 0.6 + 0.4 * (h / 12.0);
    return MarineHourPoint(
      time: t,
      seaLevelMslM: tide,
      temperatureC: 16 + (h - 12).abs() * 0.1,
      pressureHpa: 1015 + (h % 3) * 0.2,
    );
  });
}

void main() {
  test('SpotOracleSnapshot.cacheKey arredonda coordenadas', () {
    final k1 = SpotOracleSnapshot.cacheKey(
      lat: 38.44444,
      lon: -9.10111,
      lang: 'pt',
      isRiver: false,
    );
    final k2 = SpotOracleSnapshot.cacheKey(
      lat: 38.444,
      lon: -9.101,
      lang: 'pt',
      isRiver: false,
    );
    expect(k1, k2);
    expect(k1, contains('marine'));
  });

  test('buildMarineSpotOracleSnapshot produz score 0–100', () {
    final now = DateTime(2026, 7, 3, 10);
    final series = _syntheticMarineDay(now);
    final t = AqxL10n('pt');

    final snap = buildMarineSpotOracleSnapshot(
      lat: 38.444,
      lon: -9.101,
      series: series,
      species: 'ROBALO',
      t: t,
      fetchedAt: now,
    );

    expect(snap.score, inInclusiveRange(0, 100));
    expect(snap.statusLabel, isNotEmpty);
    expect(snap.windowHours, isNotEmpty);
    expect(snap.tideHeightM, isNotNull);
    expect(snap.isRiver, isFalse);
  });

  test('buildRiverSpotOracleSnapshot produz score 0–100', () {
    final now = DateTime(2026, 7, 3, 10);
    final base = DateTime(now.year, now.month, now.day);
    final series = List.generate(24, (h) {
      return ForecastWeatherHour(
        time: base.add(Duration(hours: h)),
        temperatureC: 22.0,
        pressureHpa: 1012,
        cloudCoverPct: 30,
        precipitationMm: 0,
      );
    });
    final t = AqxL10n('pt');

    final snap = buildRiverSpotOracleSnapshot(
      lat: 39.466,
      lon: -8.198,
      series: series,
      species: 'ACHIGA',
      t: t,
      fetchedAt: now,
    );

    expect(snap.score, inInclusiveRange(0, 100));
    expect(snap.isRiver, isTrue);
    expect(snap.tempC, isNotNull);
  });

  test('invalidateCache limpa cache de spots', () async {
    final svc = OracleDataService.instance;
    svc.invalidateCache();
    // Sem rede no CI: só validamos que invalidate não rebenta.
    expect(svc.lastBundle, isNull);
  });
}
