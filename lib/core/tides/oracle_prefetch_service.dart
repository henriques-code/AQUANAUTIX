import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../location/gps_access.dart';
import 'open_meteo_tides_repository.dart';
import 'oracle_cache_models.dart';
import 'oracle_cache_repository.dart';
import 'oracle_data_service.dart';
import 'region_presets.dart';
import '../state/app_locale_store.dart';
import '../state/fishing_context_store.dart';

/// Prefetch offline (72 h) — Oráculo COSTA para modo praia.
abstract final class OraclePrefetchService {
  static const _savedSpotsKey = 'map_saved_spot_pins_v1';
  static final _meteo = OpenMeteoTidesRepository();

  /// Arranque da app: limpa expirados e prefetch da última posição conhecida.
  static Future<void> onAppStart() async {
    await OracleCacheRepository.instance.purgeExpired();
    final fix = GpsAccess.cachedFixStale;
    if (fix != null) {
      unawaited(
        prefetchCostaZone(
          lat: fix.lat,
          lon: fix.lon,
          label: 'GPS',
          priority: 'normal',
        ),
      );
    }
    unawaited(prefetchSavedSpotPins());
  }

  /// Descarrega série + bundle COSTA para cache local.
  static Future<void> prefetchCostaZone({
    required double lat,
    required double lon,
    required String label,
    String priority = 'normal',
    String? tideSource,
  }) async {
    try {
      final ctx = FishingContextStore.instance.value.value;
      final tz = TideMapPreset.timezoneForCountry(ctx.country);
      final series = await _meteo.fetchSeries(
        latitude: lat,
        longitude: lon,
        timezone: tz,
        pastDays: 1,
        forecastDays: 5,
      );
      final now = DateTime.now();
      final bundle = OracleDataService.instance.buildBundleFromSeries(
        ctx: ctx,
        lat: lat,
        lon: lon,
        series: series,
        isPlanning: false,
        headline: label,
        subtitle: '${lat.toStringAsFixed(3)}°, ${lon.toStringAsFixed(3)}°',
        placeShort: label.split('·').first.trim(),
        fetchedAt: now,
      );
      final lang = AppLocaleStore.instance.locale.languageCode;
      final meta = OracleCacheMeta(
        lat: lat,
        lon: lon,
        lang: lang,
        isPlanning: false,
        label: label,
        fetchedAt: now,
        validUntil: now.add(OracleCacheRepository.cacheTtl),
        tideSource: tideSource ?? 'open_meteo',
        priority: priority,
      );
      await OracleDataService.instance.persistCostaCache(
        meta: meta,
        bundle: bundle,
        series: series,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[OraclePrefetch] falhou: $e');
    }
  }

  /// Spots com foto guardada no mapa (favoritos locais).
  static Future<void> prefetchSavedSpotPins() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_savedSpotsKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List<dynamic>;
      for (final e in list) {
        final m = e as Map<String, dynamic>;
        final lat = (m['lat'] as num?)?.toDouble();
        final lon = (m['lon'] as num?)?.toDouble();
        final name = m['name'] as String? ?? 'Spot';
        if (lat == null || lon == null) continue;
        unawaited(
          prefetchCostaZone(
            lat: lat,
            lon: lon,
            label: name,
            priority: 'favorite',
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[OraclePrefetch] spots falhou: $e');
    }
  }
}
