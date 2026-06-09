import 'dart:convert';

import 'package:http/http.dart' as http;

import 'marine_bundle.dart';
import 'weather_details_snapshot.dart';

/// Par (temperatura °C, pressão hPa) interpolado linearmente no tempo.
(double?, double?) _interpolateWeather(
  List<({DateTime t, double? temp, double? pres})> rows,
  DateTime target,
) {
  if (rows.isEmpty) return (null, null);
  if (target.isBefore(rows.first.t)) return (rows.first.temp, rows.first.pres);
  if (!target.isBefore(rows.last.t)) return (rows.last.temp, rows.last.pres);

  var lo = 0;
  var hi = rows.length - 1;
  while (hi - lo > 1) {
    final mid = (lo + hi) ~/ 2;
    if (rows[mid].t.isAfter(target)) {
      hi = mid;
    } else {
      lo = mid;
    }
  }
  final a = rows[lo];
  final b = rows[hi];
  final dt = b.t.difference(a.t).inMicroseconds;
  if (dt <= 0) return (a.temp, a.pres);
  final u = target.difference(a.t).inMicroseconds / dt;
  double? lerpNum(double? x, double? y) {
    if (x == null && y == null) return null;
    if (x == null) return y;
    if (y == null) return x;
    return x + (y - x) * u;
  }

  return (lerpNum(a.temp, b.temp), lerpNum(a.pres, b.pres));
}

/// Dados marinhos + tempo via [Open-Meteo](https://open-meteo.com/) (modelo global;
/// não substitui tábuas náuticas oficiais IPMA/DHM — ver aviso no ecrã).
class OpenMeteoTidesRepository {
  OpenMeteoTidesRepository({http.Client? httpClient}) : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const _marineHost = 'marine-api.open-meteo.com';
  static const _weatherHost = 'api.open-meteo.com';

  Future<List<MarineHourPoint>> fetchSeries({
    required double latitude,
    required double longitude,
    required String timezone,
    int pastDays = 30,
    int forecastDays = 8,
  }) async {
    final common = <String, String>{
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'timezone': timezone,
      'past_days': pastDays.clamp(0, 92).toString(),
      'forecast_days': forecastDays.clamp(0, 8).toString(),
    };

    final marineUri = Uri.https(_marineHost, '/v1/marine', {
      ...common,
      'hourly': 'sea_level_height_msl',
    });
    final weatherUri = Uri.https(_weatherHost, '/v1/forecast', {
      ...common,
      'hourly': 'temperature_2m,surface_pressure',
    });

    final marineRes = await _client.get(marineUri);
    final weatherRes = await _client.get(weatherUri);
    if (marineRes.statusCode != 200) {
      throw Exception('Marine API ${marineRes.statusCode}');
    }
    if (weatherRes.statusCode != 200) {
      throw Exception('Weather API ${weatherRes.statusCode}');
    }

    final m = jsonDecode(marineRes.body) as Map<String, dynamic>;
    final w = jsonDecode(weatherRes.body) as Map<String, dynamic>;
    final mh = m['hourly'] as Map<String, dynamic>?;
    final wh = w['hourly'] as Map<String, dynamic>?;
    if (mh == null || wh == null) throw Exception('Resposta hourly em falta');

    final wt = (wh['time'] as List<dynamic>).cast<String>();
    final temp = (wh['temperature_2m'] as List<dynamic>?)
            ?.map((e) => e as num?)
            .toList() ??
        List<num?>.filled(wt.length, null);
    final pres = (wh['surface_pressure'] as List<dynamic>?)
            ?.map((e) => e as num?)
            .toList() ??
        List<num?>.filled(wt.length, null);

    final weatherRows = <({DateTime t, double? temp, double? pres})>[];
    for (var i = 0; i < wt.length; i++) {
      weatherRows.add((
        t: DateTime.parse(wt[i]),
        temp: temp[i]?.toDouble(),
        pres: pres[i]?.toDouble(),
      ));
    }
    weatherRows.sort((a, b) => a.t.compareTo(b.t));

    final times = (mh['time'] as List<dynamic>).cast<String>();
    final sea = (mh['sea_level_height_msl'] as List<dynamic>).map((e) => e as num?).toList();

    final out = <MarineHourPoint>[];
    for (var i = 0; i < times.length; i++) {
      final seaV = sea[i];
      if (seaV == null) continue;
      final t = DateTime.parse(times[i]);
      final wx = _interpolateWeather(weatherRows, t);
      out.add(MarineHourPoint(
        time: t,
        seaLevelMslM: seaV.toDouble(),
        temperatureC: wx.$1,
        pressureHpa: wx.$2,
      ));
    }
    out.sort((a, b) => a.time.compareTo(b.time));
    return out;
  }

  /// Condições actuais pontuais: vento + ondas + código WMO (para Home dashboard).
  ///
  /// Faz dois pedidos paralelos com timeout de 8 s cada; falhas individuais
  /// retornam null nos campos correspondentes — nunca lança excepção.
  Future<
      ({
        double? tempC,
        double? windSpeedKmh,
        int? windDirDeg,
        double? waveHeightM,
        int? weatherCode,
      })> fetchCurrentConditions({
    required double latitude,
    required double longitude,
  }) async {
    final forecastUri = Uri.https(_weatherHost, '/v1/forecast', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current':
          'temperature_2m,wind_speed_10m,wind_direction_10m,weather_code',
      'wind_speed_unit': 'kmh',
    });
    final marineUri = Uri.https(_marineHost, '/v1/marine', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current': 'wave_height',
    });

    double? tempC, windSpeedKmh, waveHeightM;
    int? windDirDeg, weatherCode;

    try {
      final (wRes, mRes) = await (
        _client.get(forecastUri).timeout(const Duration(seconds: 8)),
        _client.get(marineUri).timeout(const Duration(seconds: 8)),
      ).wait;

      if (wRes.statusCode == 200) {
        final w = jsonDecode(wRes.body) as Map<String, dynamic>;
        final c = w['current'] as Map<String, dynamic>?;
        tempC = (c?['temperature_2m'] as num?)?.toDouble();
        windSpeedKmh = (c?['wind_speed_10m'] as num?)?.toDouble();
        windDirDeg = (c?['wind_direction_10m'] as num?)?.toInt();
        weatherCode = (c?['weather_code'] as num?)?.toInt();
      }
      if (mRes.statusCode == 200) {
        final m = jsonDecode(mRes.body) as Map<String, dynamic>;
        final c = m['current'] as Map<String, dynamic>?;
        waveHeightM = (c?['wave_height'] as num?)?.toDouble();
      }
    } catch (_) {
      // best-effort — caller usa fallbacks
    }

    return (
      tempC: tempC,
      windSpeedKmh: windSpeedKmh,
      windDirDeg: windDirDeg,
      waveHeightM: waveHeightM,
      weatherCode: weatherCode,
    );
  }

  /// Série horária só tempo (interior / rio — sem API marine).
  Future<List<ForecastWeatherHour>> fetchForecastWeatherSeries({
    required double latitude,
    required double longitude,
    required String timezone,
    int pastDays = 1,
    int forecastDays = 5,
  }) async {
    final uri = Uri.https(_weatherHost, '/v1/forecast', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'timezone': timezone,
      'past_days': pastDays.clamp(0, 92).toString(),
      'forecast_days': forecastDays.clamp(0, 16).toString(),
      'hourly':
          'temperature_2m,surface_pressure,cloud_cover,precipitation',
    });

    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Forecast API ${res.statusCode}');
    }
    final w = jsonDecode(res.body) as Map<String, dynamic>;
    final wh = w['hourly'] as Map<String, dynamic>?;
    if (wh == null) throw Exception('Resposta hourly em falta');

    final wt = (wh['time'] as List<dynamic>).cast<String>();
    num? at(List<dynamic>? list, int i) =>
        list != null && i < list.length ? list[i] as num? : null;

    final temp = wh['temperature_2m'] as List<dynamic>?;
    final pres = wh['surface_pressure'] as List<dynamic>?;
    final cloud = wh['cloud_cover'] as List<dynamic>?;
    final precip = wh['precipitation'] as List<dynamic>?;

    final out = <ForecastWeatherHour>[];
    for (var i = 0; i < wt.length; i++) {
      out.add(ForecastWeatherHour(
        time: DateTime.parse(wt[i]),
        temperatureC: at(temp, i)?.toDouble(),
        pressureHpa: at(pres, i)?.toDouble(),
        cloudCoverPct: at(cloud, i)?.toDouble(),
        precipitationMm: at(precip, i)?.toDouble(),
      ));
    }
    out.sort((a, b) => a.time.compareTo(b.time));
    return out;
  }

  /// Snapshot completo para a grelha de meteorologia do Oráculo (best-effort).
  Future<WeatherDetailsSnapshot?> fetchWeatherDetails({
    required double latitude,
    required double longitude,
    required String timezone,
    double? tideHeightM,
    String tideTrendPt = '',
    double? tideRangeM,
    int moonPct = 0,
    String moonPhaseLabel = '',
  }) async {
    final forecastUri = Uri.https(_weatherHost, '/v1/forecast', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'timezone': timezone,
      'current':
          'temperature_2m,apparent_temperature,relative_humidity_2m,'
          'wind_speed_10m,wind_direction_10m,wind_gusts_10m,'
          'cloud_cover,precipitation,uv_index,surface_pressure',
      'hourly':
          'temperature_2m,surface_pressure,cloud_cover,precipitation,'
          'relative_humidity_2m,visibility,wind_speed_10m',
      'daily': 'sunrise,sunset,uv_index_max',
      'past_days': '1',
      'forecast_days': '2',
      'wind_speed_unit': 'kmh',
    });
    final marineUri = Uri.https(_marineHost, '/v1/marine', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'timezone': timezone,
      'current': 'wave_height,ocean_current_velocity,ocean_current_direction',
      'hourly': 'sea_level_height_msl,ocean_current_velocity,wave_height,wave_period',
      'forecast_days': '1',
    });
    final aqUri = Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'timezone': timezone,
      'current': 'european_aqi',
      'hourly': 'grass_pollen',
      'forecast_days': '2',
    });

    try {
      final (wRes, mRes, aqRes) = await (
        _client.get(forecastUri).timeout(const Duration(seconds: 10)),
        _client.get(marineUri).timeout(const Duration(seconds: 8)),
        _client.get(aqUri).timeout(const Duration(seconds: 8)),
      ).wait;

      if (wRes.statusCode != 200) return null;

      final w = jsonDecode(wRes.body) as Map<String, dynamic>;
      final c = w['current'] as Map<String, dynamic>?;
      final wh = w['hourly'] as Map<String, dynamic>?;
      final daily = w['daily'] as Map<String, dynamic>?;

      double? waveHeightM;
      double? oceanCurrentMs;
      int? oceanCurrentDirDeg;
      List<double> tideSpark = const [];
      List<double> currentSpark = const [];
      List<double> waveSpark = const [];
      double? wavePeriodS;
      double? computedTideRange = tideRangeM;

      if (mRes.statusCode == 200) {
        final m = jsonDecode(mRes.body) as Map<String, dynamic>;
        final mc = m['current'] as Map<String, dynamic>?;
        final mh = m['hourly'] as Map<String, dynamic>?;
        waveHeightM = (mc?['wave_height'] as num?)?.toDouble();
        oceanCurrentMs = (mc?['ocean_current_velocity'] as num?)?.toDouble();
        oceanCurrentDirDeg =
            (mc?['ocean_current_direction'] as num?)?.round();

        List<double> sparkFrom(List<dynamic>? list, {int take = 12}) {
          if (list == null || list.isEmpty) return const [];
          final start = (list.length - take).clamp(0, list.length - 1);
          final out = <double>[];
          for (var i = start; i < list.length; i++) {
            final v = list[i];
            if (v is num) out.add(v.toDouble());
          }
          return out;
        }

        tideSpark = sparkFrom(mh?['sea_level_height_msl'], take: 14);
        currentSpark = sparkFrom(mh?['ocean_current_velocity'], take: 10);
        waveSpark = sparkFrom(mh?['wave_height'], take: 10);
        final wp = mh?['wave_period'] as List<dynamic>?;
        if (wp != null && wp.isNotEmpty) {
          wavePeriodS = (wp.last as num?)?.toDouble();
        }

        if (tideSpark.length >= 2) {
          final minH = tideSpark.reduce((a, b) => a < b ? a : b);
          final maxH = tideSpark.reduce((a, b) => a > b ? a : b);
          computedTideRange ??= maxH - minH;
        }
      }

      int? aqi;
      double? pollenGrass;
      if (aqRes.statusCode == 200) {
        final aq = jsonDecode(aqRes.body) as Map<String, dynamic>;
        final ac = aq['current'] as Map<String, dynamic>?;
        aqi = (ac?['european_aqi'] as num?)?.round();
        final ah = aq['hourly'] as Map<String, dynamic>?;
        final pollen = ah?['grass_pollen'] as List<dynamic>?;
        if (pollen != null && pollen.isNotEmpty) {
          pollenGrass = (pollen.first as num?)?.toDouble();
        }
      }

      final now = DateTime.now();
      List<double> spark(List<dynamic>? list, {int take = 10}) {
        if (list == null || list.isEmpty) return const [];
        final start = (list.length - take).clamp(0, list.length - 1);
        final out = <double>[];
        for (var i = start; i < list.length; i++) {
          final v = list[i];
          if (v is num) out.add(v.toDouble());
        }
        return out;
      }

      double precip24 = 0;
      if (wh != null) {
        final times = (wh['time'] as List<dynamic>?)?.cast<String>() ?? [];
        final precip = wh['precipitation'] as List<dynamic>?;
        final end = now.add(const Duration(hours: 24));
        for (var i = 0; i < times.length; i++) {
          final t = DateTime.parse(times[i]);
          if (t.isBefore(now) || t.isAfter(end)) continue;
          precip24 += (precip != null && i < precip.length
                  ? (precip[i] as num?)?.toDouble()
                  : null) ??
              0;
        }
      }

      double? visibilityKm;
      if (wh != null) {
        final vis = wh['visibility'] as List<dynamic>?;
        if (vis != null && vis.isNotEmpty) {
          final v = vis.last as num?;
          if (v != null) visibilityKm = v.toDouble() / 1000.0;
        }
      }

      DateTime? sunrise;
      DateTime? sunset;
      double? uvMaxTomorrow;
      if (daily != null) {
        final sr = (daily['sunrise'] as List<dynamic>?)?.cast<String>();
        final ss = (daily['sunset'] as List<dynamic>?)?.cast<String>();
        final uvMax = daily['uv_index_max'] as List<dynamic>?;
        if (sr != null && sr.isNotEmpty) sunrise = DateTime.parse(sr.first);
        if (ss != null && ss.isNotEmpty) sunset = DateTime.parse(ss.first);
        if (uvMax != null && uvMax.length > 1) {
          uvMaxTomorrow = (uvMax[1] as num?)?.toDouble();
        }
      }

      final airTemp = (c?['temperature_2m'] as num?)?.toDouble();
      final rh = (c?['relative_humidity_2m'] as num?)?.toDouble();
      final dew = WeatherDetailsSnapshot.estimateDewPoint(airTemp, rh) ??
          (c?['apparent_temperature'] as num?)?.toDouble();

      return WeatherDetailsSnapshot(
        fetchedAt: now,
        airTempC: airTemp,
        tempSparkline: spark(wh?['temperature_2m']),
        feelsLikeC: (c?['apparent_temperature'] as num?)?.toDouble(),
        humidityPct: rh,
        dewPointC: dew,
        cloudPct: (c?['cloud_cover'] as num?)?.toDouble(),
        precipNext24hMm: precip24,
        windSpeedKmh: (c?['wind_speed_10m'] as num?)?.toDouble(),
        windGustKmh: (c?['wind_gusts_10m'] as num?)?.toDouble(),
        windDirDeg: (c?['wind_direction_10m'] as num?)?.round(),
        uvIndex: (c?['uv_index'] as num?)?.toDouble(),
        uvMaxTomorrow: uvMaxTomorrow,
        aqi: aqi,
        pollenGrass: pollenGrass,
        visibilityKm: visibilityKm,
        pressureHpa: (c?['surface_pressure'] as num?)?.toDouble(),
        pressureSparkline: spark(wh?['surface_pressure']),
        sunrise: sunrise,
        sunset: sunset,
        waveHeightM: waveHeightM,
        tideHeightM: tideHeightM,
        tideTrendPt: tideTrendPt,
        tideRangeM: computedTideRange,
        tideSparkline: tideSpark,
        tidePhasePt: WeatherDetailsSnapshot.tidePhaseFromTrend(
          tideTrendPt,
          tideSpark,
        ),
        windSparkline: spark(wh?['wind_speed_10m']),
        waveSparkline: waveSpark,
        wavePeriodS: wavePeriodS,
        oceanCurrentMs: oceanCurrentMs,
        oceanCurrentDirDeg: oceanCurrentDirDeg,
        currentSparkline: currentSpark,
        moonPct: moonPct,
        moonPhaseLabel: moonPhaseLabel,
        humiditySparkline: spark(wh?['relative_humidity_2m']),
      );
    } catch (_) {
      return null;
    }
  }
}
