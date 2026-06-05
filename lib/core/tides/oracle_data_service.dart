import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../l10n/aqx_l10n.dart';
import '../state/app_locale_store.dart';
import '../state/fishing_context_store.dart';
import 'marine_bundle.dart';
import 'moon_phase.dart';
import 'open_meteo_tides_repository.dart';
import 'osm_place_search.dart';
import 'osm_reverse_geocode.dart';
import 'oracle_day_scorer.dart';
import 'region_presets.dart';
import 'river_discharge_repository.dart';
import 'species_tide_hints.dart';
import 'tide_analysis.dart';

/// Não há coordenadas do utilizador — o índice exige GPS para a zona real de pesca.
class OracleGpsRequiredException implements Exception {
  OracleGpsRequiredException(this.message);
  final String message;
  @override
  String toString() => message;
}

class OracleDayForecast {
  const OracleDayForecast({
    required this.dayLabel,
    required this.score,
    required this.icon,
  });

  final String dayLabel;
  final int score;
  final String icon;
}

class OracleBundle {
  const OracleBundle({
    required this.locationHeadline,
    required this.locationSubtitle,
    required this.usedGps,
    required this.score,
    required this.statusLabel,
    required this.statusDesc,
    required this.windowHours,
    required this.moonPct,
    required this.forecast,
    required this.janelaTexto,
    required this.fetchedAt,
    this.tideRangeM,
    this.tempC,
    this.pressureHpa,
    this.tideHeightM,
    this.tideTrendPt = '',
    this.pressureTrendPt = '',
    this.moonPhaseShortPt = '',
    this.tempTrendPt = '',
    this.gpsCountryIso2,
  });

  /// Texto principal da localização (label regional do contexto ou local pesquisado).
  final String locationHeadline;

  /// Subtítulo: coordenadas GPS ou indicação de modo planeamento.
  final String locationSubtitle;

  /// true = GPS ao vivo; false = posição de planeamento escolhida pelo utilizador.
  final bool usedGps;

  /// Compat: igual a [locationHeadline].
  String get localLabel => locationHeadline;

  final int score;
  final String statusLabel;
  final String statusDesc;
  final String windowHours;
  final int moonPct;
  final List<OracleDayForecast> forecast;
  final String janelaTexto;
  final DateTime fetchedAt;
  final double? tideRangeM;
  final double? tempC;
  final double? pressureHpa;

  /// Cota maré no instante mais próximo (MSL, metros).
  final double? tideHeightM;

  /// Ex.: «A descer ↓», «A subir ↑».
  final String tideTrendPt;

  /// Ex.: «↗ Estável».
  final String pressureTrendPt;

  /// Ex.: «Crescente», «Cheia».
  final String moonPhaseShortPt;

  /// Ex.: «A aquecer ↑» entre dois pontos horários consecutivos.
  final String tempTrendPt;

  /// País ISO2 do reverse Nominatim em modo GPS ao vivo (PT/ES); null em planeamento.
  final String? gpsCountryIso2;
}

/// Dados agregados modo **RIO** (meteorologia Open‑Meteo; caudal SNIRH em roadmap).
class RiverOracleBundle {
  const RiverOracleBundle({
    required this.locationHeadline,
    required this.locationSubtitle,
    required this.usedGps,
    required this.score,
    required this.statusLabel,
    required this.statusDesc,
    required this.windowHours,
    required this.forecast,
    required this.janelaTexto,
    required this.fetchedAt,
    required this.caudalValue,
    required this.caudalSub,
    required this.nivelValue,
    required this.nivelSub,
    this.tempC,
    this.tempTrendPt = '',
    required this.visibValue,
    required this.visibSub,
    this.gpsCountryIso2,
  });

  final String locationHeadline;
  final String locationSubtitle;

  /// true = GPS ao vivo; false = posição de planeamento escolhida pelo utilizador.
  final bool usedGps;
  final int score;
  final String statusLabel;
  final String statusDesc;
  final String windowHours;
  final List<OracleDayForecast> forecast;
  final String janelaTexto;
  final DateTime fetchedAt;
  final String caudalValue;
  final String caudalSub;
  final String nivelValue;
  final String nivelSub;
  final double? tempC;
  final String tempTrendPt;
  final String visibValue;
  final String visibSub;

  final String? gpsCountryIso2;
}

/// Agrega GPS ou coordenadas de planeamento + Open‑Meteo + scoring em `core/tides/`.
///
/// Modo **planeamento:** passar [planningPlace] para saltar `_requireGpsFix` e usar
/// as coordenadas escolhidas pelo utilizador na pesquisa Nominatim.
/// Modo **rio:** ver [fetchRiver]; hidrometria SNIRH em roadmap.
class OracleDataService {
  OracleDataService._();
  static final OracleDataService instance = OracleDataService._();

  final _repo = OpenMeteoTidesRepository();
  OracleBundle? _cache;
  String? _cacheKey;
  DateTime? _cacheTime;
  RiverOracleBundle? _riverCache;
  String? _riverCacheKey;
  DateTime? _riverCacheTime;

  static const _cacheTtl = Duration(minutes: 30);

  /// Bundle COSTA em cache (pode ser null se ainda não houve fetch).
  OracleBundle? get lastBundle => _cache;

  /// Últimas coordenadas usadas num fetch COSTA/RIO (para meteorologia detalhada).
  ({double lat, double lon})? _lastCoords;
  ({double lat, double lon})? get lastCoords => _lastCoords;

  /// Força novo fetch (pull-to-refresh no Oráculo).
  void invalidateCache() {
    _cache = null;
    _cacheKey = null;
    _cacheTime = null;
    _riverCache = null;
    _riverCacheKey = null;
    _riverCacheTime = null;
  }

  /// Posição actual obrigatória — sem GPS não há índice fiável para a zona de pesca.
  Future<({double lat, double lon})> _requireGpsFix(AqxL10n t) async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      throw OracleGpsRequiredException(t.gpsDenied);
    }
    if (perm == LocationPermission.deniedForever) {
      throw OracleGpsRequiredException(t.gpsBlocked);
    }
    final svcEnabled = await Geolocator.isLocationServiceEnabled();
    if (!svcEnabled) {
      throw OracleGpsRequiredException(t.gpsServiceOff);
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 18),
        ),
      );
      return (lat: pos.latitude, lon: pos.longitude);
    } catch (_) {
      throw OracleGpsRequiredException(t.gpsFixFailed);
    }
  }

  /// Fetch COSTA — GPS em modo ao vivo; [planningPlace] em modo planeamento (sem GPS).
  Future<OracleBundle> fetch({
    required FishingContext ctx,
    OsmPlace? planningPlace,
  }) async {
    final tz = TideMapPreset.timezoneForCountry(ctx.country);
    double lat;
    double lon;

    final tGps = AqxL10n(AppLocaleStore.instance.locale.languageCode);
    if (planningPlace != null) {
      lat = planningPlace.lat;
      lon = planningPlace.lon;
    } else {
      final fix = await _requireGpsFix(tGps);
      lat = fix.lat;
      lon = fix.lon;
    }
    _lastCoords = (lat: lat, lon: lon);

    final isPlanning = planningPlace != null;

    OsmReverseResult? geo;
    String? gpsCountryIso2;
    if (!isPlanning) {
      final langHead = AppLocaleStore.instance.locale.languageCode;
      geo = await reverseGeocodePlaceDetail(
        lat,
        lon,
        acceptLanguage: langHead == 'es' ? 'es' : 'pt',
      );
      AppLocaleStore.instance.applyGpsCountryIso2(geo?.countryIso2);
      if (AqxL10n(AppLocaleStore.instance.locale.languageCode).es &&
          langHead != 'es') {
        geo = await reverseGeocodePlaceDetail(lat, lon, acceptLanguage: 'es') ??
            geo;
      }
      gpsCountryIso2 = geo?.countryIso2;
    }

    final lang = AppLocaleStore.instance.locale.languageCode;
    final key = isPlanning
        ? '$lang|p:${lat.toStringAsFixed(3)},${lon.toStringAsFixed(3)}'
        : '$lang|${lat.toStringAsFixed(3)},${lon.toStringAsFixed(3)}';
    final now = DateTime.now();
    if (_cache != null &&
        _cacheKey == key &&
        _cacheTime != null &&
        now.difference(_cacheTime!) < _cacheTtl) {
      return _cache!;
    }

    final t = AqxL10n(lang);
    final series = await _repo.fetchSeries(
      latitude: lat,
      longitude: lon,
      timezone: tz,
      pastDays: 1,
      forecastDays: 5,
    );
    final placeLabel = geo?.label ?? '';

    final headline = isPlanning
        ? planningPlace.label
        : (placeLabel.isNotEmpty ? placeLabel : t.yourPosition);
    final subtitle = isPlanning
        ? t.planningSubtitle(lat, lon)
        : '${lat.toStringAsFixed(3)}°, ${lon.toStringAsFixed(3)}°';
    final placeShort = isPlanning
        ? planningPlace.label.split('·').first.trim()
        : 'ti';

    final today = dateOnly(now);
    final dayScores = buildDayScoreMap(series);
    final todayHours = hoursForDay(series, today);

    double? tideRange;
    if (todayHours.length >= 2) {
      final heights = todayHours.map((e) => e.seaLevelMslM).toList();
      tideRange = heights.reduce(math.max) - heights.reduce(math.min);
    }

    MarineHourPoint? closest;
    if (todayHours.isNotEmpty) {
      closest = todayHours.reduce((a, b) =>
          a.time.difference(now).abs() < b.time.difference(now).abs() ? a : b);
    }

    final tempC = closest?.temperatureC;
    final pressureHpa = closest?.pressureHpa;
    final moonPct = (moonFishingFactor(now) * 100).round().clamp(0, 100);

    final extrema = detectTideExtrema(todayHours);
    var phaseLabel = t.tideActive;
    if (extrema.length >= 2) {
      final phase = tidePhaseBetween(extrema[0], extrema[1]);
      phaseLabel = phase != null
          ? t.tideWithPhase(t.mapTidePhaseWord(phase))
          : t.slackWater;
    } else if (extrema.length == 1) {
      phaseLabel = extrema[0].isHigh ? t.highTide : t.lowTide;
    }

    final moonPhase = moonPhase01(now);
    final moonLabel = t.moonLong(moonPhase);
    final moonPhaseTile = t.moonTileShort(moonPhase);

    String tideTrendPt = '';
    String tempTrendPt = '';
    final sortedToday = [...todayHours]
      ..sort((a, b) => a.time.compareTo(b.time));
    if (closest != null && sortedToday.length >= 2) {
      var bestI = -1;
      var bestAbs = 999999999;
      for (var i = 0; i < sortedToday.length; i++) {
        final absMin =
            sortedToday[i].time.difference(closest.time).inMinutes.abs();
        if (absMin < bestAbs) {
          bestAbs = absMin;
          bestI = i;
        }
      }
      if (bestI >= 0 && bestI < sortedToday.length - 1) {
        tideTrendPt = _tideTrendLabel(
          sortedToday[bestI].seaLevelMslM,
          sortedToday[bestI + 1].seaLevelMslM,
          t,
        );
        tempTrendPt = _tempTrendLabel(
          sortedToday[bestI].temperatureC,
          sortedToday[bestI + 1].temperatureC,
          t,
        );
      }
    }

    final pressureTrendPt = _pressureTrendSubtitle(todayHours, t);
    final pressLabel = _pressureLabel(todayHours, t);
    final todayScore = dayScores[today] ?? 50;
    final statusLabel = t.scoreLabel(todayScore);
    final statusDesc = '$phaseLabel + $moonLabel\n+ $pressLabel';

    final bestHour = bestHourForSpecies(todayHours, ctx.species);
    final windowHours = _windowFromHour(bestHour);

    final forecastDays = <OracleDayForecast>[];
    for (var i = 0; i < 5; i++) {
      final d = today.add(Duration(days: i));
      final s = dayScores[d] ?? 0;
      forecastDays.add(OracleDayForecast(
        dayLabel: i == 0 ? t.todayShort : t.weekdayShort(d.weekday),
        score: s,
        icon: _scoreIcon(s),
      ));
    }

    var janelaTexto = t.janelaPro;
    if (forecastDays.length >= 2) {
      final tomorrowFC = forecastDays[1];
      final tomorrowHours =
          hoursForDay(series, today.add(const Duration(days: 1)));
      final tmrHour = bestHourForSpecies(tomorrowHours, ctx.species);
      janelaTexto = t.janelaLine(
        tomorrowFC.dayLabel,
        _windowFromHour(tmrHour),
        tomorrowFC.score,
        placeShort,
      );
    }

    final bundle = OracleBundle(
      locationHeadline: headline,
      locationSubtitle: subtitle,
      usedGps: !isPlanning,
      score: todayScore,
      statusLabel: statusLabel,
      statusDesc: statusDesc,
      windowHours: windowHours,
      moonPct: moonPct,
      tideRangeM: tideRange,
      tempC: tempC,
      pressureHpa: pressureHpa,
      tideHeightM: closest?.seaLevelMslM,
      tideTrendPt: tideTrendPt,
      pressureTrendPt: pressureTrendPt,
      moonPhaseShortPt: moonPhaseTile,
      tempTrendPt: tempTrendPt,
      forecast: forecastDays,
      janelaTexto: janelaTexto,
      fetchedAt: now,
      gpsCountryIso2: gpsCountryIso2,
    );

    _cache = bundle;
    _cacheKey = key;
    _cacheTime = now;
    return bundle;
  }

  /// Tempo na posição GPS ou de planeamento (sem caudal oficial SNIRH — roadmap).
  Future<RiverOracleBundle> fetchRiver({
    required FishingContext ctx,
    OsmPlace? planningPlace,
  }) async {
    final tz = TideMapPreset.timezoneForCountry(ctx.country);
    double lat;
    double lon;

    final tGps = AqxL10n(AppLocaleStore.instance.locale.languageCode);
    if (planningPlace != null) {
      lat = planningPlace.lat;
      lon = planningPlace.lon;
    } else {
      final fix = await _requireGpsFix(tGps);
      lat = fix.lat;
      lon = fix.lon;
    }
    _lastCoords = (lat: lat, lon: lon);

    final isPlanning = planningPlace != null;

    OsmReverseResult? geo;
    String? gpsCountryIso2;
    if (!isPlanning) {
      final langHead = AppLocaleStore.instance.locale.languageCode;
      geo = await reverseGeocodePlaceDetail(
        lat,
        lon,
        acceptLanguage: langHead == 'es' ? 'es' : 'pt',
      );
      AppLocaleStore.instance.applyGpsCountryIso2(geo?.countryIso2);
      if (AqxL10n(AppLocaleStore.instance.locale.languageCode).es &&
          langHead != 'es') {
        geo = await reverseGeocodePlaceDetail(lat, lon, acceptLanguage: 'es') ??
            geo;
      }
      gpsCountryIso2 = geo?.countryIso2;
    }

    final lang = AppLocaleStore.instance.locale.languageCode;
    final key = isPlanning
        ? '$lang|river|p:${lat.toStringAsFixed(3)},${lon.toStringAsFixed(3)}'
        : '$lang|river|${lat.toStringAsFixed(3)},${lon.toStringAsFixed(3)}';
    final now = DateTime.now();
    if (_riverCache != null &&
        _riverCacheKey == key &&
        _riverCacheTime != null &&
        now.difference(_riverCacheTime!) < _cacheTtl) {
      return _riverCache!;
    }

    final t = AqxL10n(lang);
    final (series, discharge) = await (
      _repo.fetchForecastWeatherSeries(
        latitude: lat,
        longitude: lon,
        timezone: tz,
        pastDays: 1,
        forecastDays: 5,
      ),
      RiverDischargeRepository().fetch(lat: lat, lon: lon),
    ).wait;
    final placeLabel = geo?.label ?? '';

    final headline = isPlanning
        ? planningPlace.label
        : (placeLabel.isNotEmpty ? placeLabel : t.yourPosition);
    final subtitle = isPlanning
        ? t.planningSubtitle(lat, lon)
        : '${lat.toStringAsFixed(3)}°, ${lon.toStringAsFixed(3)}°';
    final placeShort = isPlanning
        ? planningPlace.label.split('·').first.trim()
        : 'ti';

    final today = dateOnly(now);
    final dayScores = buildRiverDayScoreMap(series);
    final todayHours = forecastHoursForDay(series, today);

    ForecastWeatherHour? closest;
    if (todayHours.isNotEmpty) {
      closest = todayHours.reduce((a, b) =>
          a.time.difference(now).abs() < b.time.difference(now).abs() ? a : b);
    }

    final tempC = closest?.temperatureC;

    final moonPhase = moonPhase01(now);
    final moonLabel = t.moonLong(moonPhase);

    final skyShort = _skyShortLabel(todayHours, t);
    final pressLabel = _pressureLabelForecast(todayHours, t);
    final todayScore = dayScores[today] ?? 52;
    final statusLabel = t.scoreLabel(todayScore);
    final statusDesc = '$skyShort + $moonLabel\n+ $pressLabel';

    String tempTrendPt = '';
    final sortedToday = [...todayHours]
      ..sort((a, b) => a.time.compareTo(b.time));
    if (closest != null && sortedToday.length >= 2) {
      var bestI = -1;
      var bestAbs = 999999999;
      for (var i = 0; i < sortedToday.length; i++) {
        final absMin =
            sortedToday[i].time.difference(closest.time).inMinutes.abs();
        if (absMin < bestAbs) {
          bestAbs = absMin;
          bestI = i;
        }
      }
      if (bestI >= 0 && bestI < sortedToday.length - 1) {
        tempTrendPt = _tempTrendLabel(
          sortedToday[bestI].temperatureC,
          sortedToday[bestI + 1].temperatureC,
          t,
        );
      }
    }

    final (nivelVal, nivelSub) = _riverNivelCard(sortedToday, now, t);
    final (visVal, visSub) = _riverVisibCard(closest, t);

    final bestHour = bestHourForRiver(todayHours);
    final windowHours = _windowFromHour(bestHour);

    final forecastDays = <OracleDayForecast>[];
    for (var i = 0; i < 5; i++) {
      final d = today.add(Duration(days: i));
      final s = dayScores[d] ?? 0;
      forecastDays.add(OracleDayForecast(
        dayLabel: i == 0 ? t.todayShort : t.weekdayShort(d.weekday),
        score: s,
        icon: _scoreIcon(s),
      ));
    }

    var janelaTexto = t.janelaPro;
    if (forecastDays.length >= 2) {
      final tomorrowFC = forecastDays[1];
      final tomorrowHours =
          forecastHoursForDay(series, today.add(const Duration(days: 1)));
      final tmrHour = bestHourForRiver(tomorrowHours);
      janelaTexto = t.janelaLine(
        tomorrowFC.dayLabel,
        _windowFromHour(tmrHour),
        tomorrowFC.score,
        placeShort,
      );
    }

    final caudalValue = discharge?.formatted ?? '—';
    final caudalSub = discharge != null
        ? t.caudalSource(discharge.trendIcon)
        : t.snirhSoon;

    final bundle = RiverOracleBundle(
      locationHeadline: headline,
      locationSubtitle: subtitle,
      usedGps: !isPlanning,
      score: todayScore,
      statusLabel: statusLabel,
      statusDesc: statusDesc,
      windowHours: windowHours,
      forecast: forecastDays,
      janelaTexto: janelaTexto,
      fetchedAt: now,
      caudalValue: caudalValue,
      caudalSub: caudalSub,
      nivelValue: nivelVal,
      nivelSub: nivelSub,
      tempC: tempC,
      tempTrendPt: tempTrendPt,
      visibValue: visVal,
      visibSub: visSub,
      gpsCountryIso2: gpsCountryIso2,
    );

    _riverCache = bundle;
    _riverCacheKey = key;
    _riverCacheTime = now;
    return bundle;
  }

  String _skyShortLabel(List<ForecastWeatherHour> dayHours, AqxL10n t) {
    final clouds =
        dayHours.map((e) => e.cloudCoverPct).whereType<double>().toList();
    if (clouds.isEmpty) return t.weatherVariable;
    final avg = clouds.reduce((a, b) => a + b) / clouds.length;
    if (avg < 38) return t.skyClear;
    if (avg < 72) return t.skyMedium;
    return t.skyOvercast;
  }

  String _pressureLabelForecast(List<ForecastWeatherHour> hours, AqxL10n t) {
    final pressures =
        hours.map((e) => e.pressureHpa).whereType<double>().toList();
    if (pressures.length < 4) return t.pressureDash;
    final mean = pressures.reduce((a, b) => a + b) / pressures.length;
    if (mean.abs() <= 1e-6) return t.pressureDash;
    var varSum = 0.0;
    for (final p in pressures) {
      varSum += (p - mean) * (p - mean);
    }
    final std = math.sqrt(varSum / pressures.length);
    final cv = (std / mean).abs();
    return cv < 0.006 ? t.pressureStable : t.pressureVariable;
  }

  (String, String) _riverNivelCard(
    List<ForecastWeatherHour> sortedToday,
    DateTime now,
    AqxL10n t,
  ) {
    if (sortedToday.length < 6) {
      return ('—', t.riverUpdating);
    }
    double sumRecent = 0;
    double sumPrev = 0;
    var nR = 0;
    var nP = 0;
    for (final h in sortedToday) {
      if (!h.time.isBefore(now)) continue;
      final p = h.precipitationMm ?? 0;
      final age = now.difference(h.time);
      if (age <= const Duration(hours: 6)) {
        sumRecent += p;
        nR++;
      } else if (age <= const Duration(hours: 12)) {
        sumPrev += p;
        nP++;
      }
    }
    final delta = nR > 0 && nP > 0 ? (sumRecent / nR - sumPrev / nP) : 0.0;
    final daySum =
        sortedToday.map((e) => e.precipitationMm ?? 0).fold(0.0, (a, b) => a + b);

    String val;
    if (daySum >= 5) {
      val = t.riverWet;
    } else if (daySum >= 0.8) {
      val = t.riverHumid;
    } else {
      val = t.riverDry;
    }

    String sub;
    if (delta > 0.35) {
      sub = t.rainIncreasing;
    } else if (delta < -0.35) {
      sub = t.rainDecreasing;
    } else {
      sub = t.precipStable;
    }
    return (val, sub);
  }

  (String, String) _riverVisibCard(ForecastWeatherHour? closest, AqxL10n t) {
    final c = closest?.cloudCoverPct;
    if (c == null) return ('—', '—');
    if (c < 38) return (t.visGood, t.visFewClouds);
    if (c < 72) return (t.visMedium, t.visMediumCloud);
    return (t.visLow, t.visHeavyCloud);
  }

  String _tideTrendLabel(double y0, double y1, AqxL10n t) {
    final dy = y1 - y0;
    if (dy > 0.02) return t.tideRising;
    if (dy < -0.02) return t.tideFalling;
    return t.tideFlat;
  }

  String _tempTrendLabel(double? t0, double? t1, AqxL10n t) {
    if (t0 == null || t1 == null) return '';
    final dt = t1 - t0;
    if (dt > 0.06) return t.tempWarming;
    if (dt < -0.06) return t.tempCooling;
    return t.tempStable;
  }

  /// Legenda para o cartão de pressão na grelha meteorologia (coerente com [_pressureLabel]).
  String _pressureTrendSubtitle(List<MarineHourPoint> hours, AqxL10n t) {
    final pressures =
        hours.map((e) => e.pressureHpa).whereType<double>().toList();
    if (pressures.length < 4) return '';
    final mean = pressures.reduce((a, b) => a + b) / pressures.length;
    if (mean.abs() <= 1e-6) return '';
    var varSum = 0.0;
    for (final p in pressures) {
      varSum += (p - mean) * (p - mean);
    }
    final std = math.sqrt(varSum / pressures.length);
    final cv = (std / mean).abs();
    return cv < 0.006 ? t.pressureStableShort : t.pressureVariableShort;
  }

  String _pressureLabel(List<MarineHourPoint> hours, AqxL10n t) {
    final pressures =
        hours.map((e) => e.pressureHpa).whereType<double>().toList();
    if (pressures.length < 4) return t.pressureDash;
    final mean = pressures.reduce((a, b) => a + b) / pressures.length;
    if (mean.abs() <= 1e-6) return t.pressureDash;
    var varSum = 0.0;
    for (final p in pressures) {
      varSum += (p - mean) * (p - mean);
    }
    final std = math.sqrt(varSum / pressures.length);
    final cv = (std / mean).abs();
    return cv < 0.006 ? t.pressureStable : t.pressureVariable;
  }

  String _scoreIcon(int s) {
    if (s >= 80) return '⚡';
    if (s >= 65) return '↑';
    if (s >= 45) return '☁';
    return '↓';
  }

  String _windowFromHour(int? h) {
    if (h == null) return '—';
    final endH = (h + 2) % 24;
    return '${_pad(h)}:00 -> ${_pad(endH)}:30';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
