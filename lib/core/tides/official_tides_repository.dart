import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../supabase_bootstrap.dart';
import 'marine_bundle.dart';

/// Resposta da Edge Function `oracle-tides` (marés oficiais PT/ES + fallback).
class OfficialTidesResult {
  const OfficialTidesResult({
    required this.source,
    required this.hourly,
    this.portId,
    this.portLabel,
  });

  /// `official_port_ref` | `fes_global` | `open_meteo_client`
  final String source;
  final String? portId;
  final String? portLabel;
  final List<({DateTime time, double seaLevelM})> hourly;
}

/// Cliente das marés agregadas no servidor (porto oficial → fallback FES global).
class OfficialTidesRepository {
  OfficialTidesRepository({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;

  /// Best-effort: null se Supabase indisponível ou pedido falhar.
  Future<OfficialTidesResult?> fetchHourly({
    required double latitude,
    required double longitude,
    required String timezone,
    int pastDays = 1,
    int forecastDays = 5,
  }) async {
    if (!canUseSupabase) return null;
    final client = supabaseClientOrNull;
    if (client == null) return null;

    try {
      final res = await client.functions.invoke(
        'oracle-tides',
        body: {
          'latitude': latitude,
          'longitude': longitude,
          'timezone': timezone,
          'past_days': pastDays,
          'forecast_days': forecastDays,
        },
      );
      if (res.status != 200 || res.data == null) return null;
      final j = res.data is String
          ? jsonDecode(res.data as String) as Map<String, dynamic>
          : Map<String, dynamic>.from(res.data as Map);
      final hourlyRaw = j['hourly'] as List<dynamic>? ?? [];
      final hourly = <({DateTime time, double seaLevelM})>[];
      for (final e in hourlyRaw) {
        final m = e as Map<String, dynamic>;
        final t = m['time'] as String?;
        final h = m['sea_level_m'] as num?;
        if (t == null || h == null) continue;
        hourly.add((time: DateTime.parse(t), seaLevelM: h.toDouble()));
      }
      if (hourly.isEmpty) return null;
      hourly.sort((a, b) => a.time.compareTo(b.time));
      return OfficialTidesResult(
        source: j['source'] as String? ?? 'fes_global',
        portId: j['portId'] as String?,
        portLabel: j['portLabel'] as String?,
        hourly: hourly,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[OfficialTides] edge falhou: $e');
      return null;
    }
  }

  /// Fallback directo Open-Meteo marine (modelo global — equivalente FES no cliente).
  Future<OfficialTidesResult?> fetchOpenMeteoFallback({
    required double latitude,
    required double longitude,
    required String timezone,
    int pastDays = 1,
    int forecastDays = 5,
  }) async {
    try {
      final uri = Uri.https('marine-api.open-meteo.com', '/v1/marine', {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'timezone': timezone,
        'past_days': pastDays.clamp(0, 92).toString(),
        'forecast_days': forecastDays.clamp(0, 8).toString(),
        'hourly': 'sea_level_height_msl',
      });
      final res = await _client
          .get(uri)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final m = jsonDecode(res.body) as Map<String, dynamic>;
      final mh = m['hourly'] as Map<String, dynamic>?;
      if (mh == null) return null;
      final times = (mh['time'] as List<dynamic>).cast<String>();
      final sea = (mh['sea_level_height_msl'] as List<dynamic>)
          .map((e) => e as num?)
          .toList();
      final hourly = <({DateTime time, double seaLevelM})>[];
      for (var i = 0; i < times.length; i++) {
        final v = sea[i];
        if (v == null) continue;
        hourly.add((time: DateTime.parse(times[i]), seaLevelM: v.toDouble()));
      }
      if (hourly.isEmpty) return null;
      return OfficialTidesResult(
        source: 'open_meteo_client',
        hourly: hourly,
      );
    } catch (_) {
      return null;
    }
  }

  /// Cruza maré (oficial ou fallback) com meteo Open-Meteo já obtida.
  List<MarineHourPoint> mergeSeaLevel({
    required List<MarineHourPoint> meteoSeries,
    required OfficialTidesResult tides,
  }) {
    if (tides.hourly.isEmpty) return meteoSeries;
    final byTime = <int, double>{};
    for (final p in tides.hourly) {
      byTime[p.time.millisecondsSinceEpoch ~/ 60000] = p.seaLevelM;
    }
    return meteoSeries
        .map((p) {
          final key = p.time.millisecondsSinceEpoch ~/ 60000;
          final sea = byTime[key];
          if (sea == null) return p;
          return MarineHourPoint(
            time: p.time,
            seaLevelMslM: sea,
            temperatureC: p.temperatureC,
            pressureHpa: p.pressureHpa,
          );
        })
        .toList();
  }
}
