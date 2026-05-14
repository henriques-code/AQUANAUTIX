import 'dart:convert';

import 'package:http/http.dart' as http;

import 'marine_bundle.dart';

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
}
