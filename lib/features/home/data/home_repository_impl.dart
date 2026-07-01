import 'dart:math' as math;

import '../../../core/location/gps_access.dart';
import '../../../core/supabase_bootstrap.dart';
import '../../../core/state/fishing_context_store.dart';
import '../../../core/tides/marine_bundle.dart';
import '../../../core/tides/moon_phase.dart';
import '../../../core/tides/open_meteo_tides_repository.dart';
import '../../../core/tides/oracle_data_service.dart';
import '../../../core/tides/osm_place_search.dart';
import '../../../core/tides/region_presets.dart';
import '../domain/entities/community_activity.dart';
import '../domain/entities/featured_spot.dart';
import '../domain/entities/hourly_condition.dart';
import '../domain/entities/weather_data.dart';
import '../domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final _meteo = OpenMeteoTidesRepository();

  // ─── Spots em destaque (ordem mockup Início) ─────────────────────────────
  static const _featuredSpotsBase = [
    FeaturedSpot(
      id: 'sesimbra',
      name: 'Sesimbra',
      imageUrl: 'assets/marketing/spots/sesimbra.jpg',
      quality: SpotQuality.excelente,
      lat: 38.4443,
      lon: -9.1011,
      species: ['Robalo', 'Corvina', 'Sargo'],
      scorePercent: 85,
      distanceKm: 12,
      waveHeightM: 0.8,
    ),
    FeaturedSpot(
      id: 'peniche',
      name: 'Peniche',
      imageUrl: 'assets/marketing/spots/peniche.jpg',
      quality: SpotQuality.bom,
      lat: 38.3558,
      lon: -9.3812,
      species: ['Robalo', 'Corvina', 'Lúcio'],
      scorePercent: 72,
      distanceKm: 48,
      waveHeightM: 1.1,
    ),
    FeaturedSpot(
      id: 'espichel',
      name: 'Cabo Espichel',
      imageUrl: 'assets/marketing/spots/cabo_da_roca.jpg',
      quality: SpotQuality.razoavel,
      lat: 38.4162,
      lon: -9.2178,
      species: ['Sargo', 'Dourada', 'Corvina'],
      scorePercent: 64,
      distanceKm: 25,
      waveHeightM: 0.7,
    ),
  ];

  // ─── Comunidade (mockup Últimas Capturas) ────────────────────────────────
  static List<CommunityActivity> _communityActivities(DateTime now) => [
        CommunityActivity(
          userId: 'joao_m',
          username: 'João M.',
          avatarUrl:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=96&q=80',
          activityText: 'Robalo 3.1 kg',
          species: 'Robalo',
          weightKg: 3.1,
          lengthCm: 68,
          location: 'Sesimbra',
          catchImageUrl: 'assets/marketing/catches/robalo.jpg',
          timestamp: now.subtract(const Duration(hours: 2)),
          likes: 32,
          verified: true,
        ),
        CommunityActivity(
          userId: 'miguel_p',
          username: 'Miguel P.',
          avatarUrl:
              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=96&q=80',
          activityText: 'Sargo 1.2 kg',
          species: 'Sargo',
          weightKg: 1.2,
          lengthCm: 32,
          location: 'Cacilhas',
          catchImageUrl: 'assets/marketing/catches/sargo.jpg',
          timestamp: now.subtract(const Duration(hours: 4)),
          likes: 18,
        ),
      ];

  /// UI imediata no Início — sem rede nem GPS (actualizada em background).
  static HomeDashboardData instantFallback() {
    final now = DateTime.now();
    final ctx = FishingContextStore.instance.value.value;
    final preset = TideMapPreset.forRegion(ctx.region);
    final repo = HomeRepositoryImpl();
    return HomeDashboardData(
      userDisplayName: repo._getUserDisplayName(),
      weather: WeatherData(
        location: preset.label,
        temperature: 18,
        condition: 'A carregar…',
        conditionIcon: '🌤️',
        windSpeed: 14,
        waveHeight: 0.6,
        tideHeight: 1.2,
        tideRising: true,
        moonPhase: 'Crescente',
        moonIcon: '🌙',
        solunarScore: OracleDataService.instance.lastBundle?.score ?? 49,
      ),
      hourlyConditions: repo._fallbackHourly(now),
      featuredSpots: _featuredSpotsBase,
      communityActivities: _communityActivities(now),
      lastUpdated: now,
    );
  }

  // ─── loadDashboard ────────────────────────────────────────────────────────
  @override
  Future<HomeDashboardData> loadDashboard({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final ctx = FishingContextStore.instance.value.value;
    final preset = TideMapPreset.forRegion(ctx.region);

    // 1. Coordenadas — tentar GPS quando permitido (pull-to-refresh força novo fix).
    final gpsGranted = await GpsAccess.check() == GpsAccessStatus.granted;
    ({double lat, double lon})? cachedFix;
    if (gpsGranted) {
      if (forceRefresh) {
        cachedFix = await GpsAccess.tryGetFix(
          timeout: const Duration(seconds: 12),
          forceRefresh: true,
        );
      } else {
        cachedFix = GpsAccess.cachedFix ?? GpsAccess.cachedFixStale;
        cachedFix ??= await GpsAccess.tryGetFix(
          timeout: const Duration(seconds: 8),
        );
      }
    } else {
      cachedFix = GpsAccess.cachedFix ?? GpsAccess.cachedFixStale;
    }
    final hasGpsCoords = gpsGranted && cachedFix != null;
    final lat = cachedFix?.lat ?? preset.latitude;
    final lon = cachedFix?.lon ?? preset.longitude;

    final regionalPlace = OsmPlace(
      lat: preset.latitude,
      lon: preset.longitude,
      label: preset.label,
      displayName: preset.label,
    );

    // 2. OracleBundle — GPS quando há fix; senão regional. Re-fetch se cache é só regional.
    if (forceRefresh) {
      OracleDataService.instance.invalidateCache();
    }
    OracleBundle? bundle =
        forceRefresh ? null : OracleDataService.instance.lastBundle;
    final bundleNeedsGpsRefresh =
        hasGpsCoords && bundle != null && !bundle.usedGps;
    if (bundle == null || bundleNeedsGpsRefresh || forceRefresh) {
      try {
        if (hasGpsCoords) {
          bundle = await OracleDataService.instance
              .fetch(ctx: ctx, knownCoords: cachedFix)
              .timeout(const Duration(seconds: 10));
        } else {
          bundle = await OracleDataService.instance
              .fetch(ctx: ctx, planningPlace: regionalPlace)
              .timeout(const Duration(seconds: 10));
        }
      } on OracleGpsRequiredException {
        try {
          bundle = await OracleDataService.instance
              .fetch(ctx: ctx, planningPlace: regionalPlace)
              .timeout(const Duration(seconds: 10));
        } catch (_) {}
      } catch (_) {}
    }

    // 3–4. Meteo actual + horária em paralelo (best effort).
    var hourly = _fallbackHourly(now);
    ({
      double? tempC,
      double? windSpeedKmh,
      int? windDirDeg,
      double? waveHeightM,
      int? weatherCode,
    })? cur;
    try {
      final tz = TideMapPreset.timezoneForCountry(ctx.country);
      final results = await Future.wait([
        _meteo.fetchCurrentConditions(latitude: lat, longitude: lon),
        _meteo.fetchForecastWeatherSeries(
          latitude: lat,
          longitude: lon,
          timezone: tz,
          pastDays: 0,
          forecastDays: 1,
        ),
      ]);
      cur = results[0] as ({
        double? tempC,
        double? windSpeedKmh,
        int? windDirDeg,
        double? waveHeightM,
        int? weatherCode,
      })?;
      final series = results[1] as List<ForecastWeatherHour>;
      final mapped = _mapHourly(series, now);
      if (mapped.isNotEmpty) hourly = mapped;
    } catch (_) {
      try {
        cur = await _meteo.fetchCurrentConditions(
          latitude: lat,
          longitude: lon,
        );
      } catch (_) {}
    }

    // 5. Monta WeatherData
    final weather = _buildWeatherData(bundle, cur, now);

    return HomeDashboardData(
      userDisplayName: _getUserDisplayName(),
      weather: weather,
      hourlyConditions: hourly,
      featuredSpots: _spotsWithDistance(lat, lon, waveHeightM: cur?.waveHeightM ?? 0.8),
      communityActivities: _communityActivities(now),
      lastUpdated: now,
    );
  }

  // ─── Mapeamento WeatherData ───────────────────────────────────────────────
  WeatherData _buildWeatherData(
    OracleBundle? bundle,
    ({
      double? tempC,
      double? windSpeedKmh,
      int? windDirDeg,
      double? waveHeightM,
      int? weatherCode,
    })? cur,
    DateTime now,
  ) {
    // Temperatura: preferência bundle (Open-Meteo marine+weather) > current
    final tempC = bundle?.tempC ?? cur?.tempC ?? 18.0;

    // Localização: headline do Oráculo (GPS ou planeamento) ou região padrão.
    final String location;
    if (bundle != null && bundle.locationHeadline.isNotEmpty) {
      location = bundle.locationHeadline;
    } else {
      final preset = TideMapPreset.forRegion(
        FishingContextStore.instance.value.value.region,
      );
      location = preset.label;
    }

    // Pressão
    final pressureHpa = bundle?.pressureHpa ?? cur?.tempC;

    // Maré — MSL pode ser negativo; não usar tideHeight > 0 para visibilidade.
    final tideHeightOpt = bundle?.tideHeightM;
    final hasTide = tideHeightOpt != null || bundle == null;
    final tideHeightM = tideHeightOpt ?? 1.2;
    final tideRising = bundle != null
        ? (bundle.tideTrendPt.contains('subir') ||
            bundle.tideTrendPt.contains('↑') ||
            bundle.tideTrendPt.contains('creciente'))
        : true;

    // Lua
    final moonPhase = (bundle?.moonPhaseShortPt.isNotEmpty ?? false)
        ? bundle!.moonPhaseShortPt
        : 'Crescente';
    final moonIcon = _moonIcon(moonPhase);

    // Score solunar
    final solunarScore = bundle?.score ?? _defaultSolunar(now);

    // Vento
    final windSpeedKmh = cur?.windSpeedKmh ?? 14.0;
    final windDir =
        cur?.windDirDeg != null ? _cardinal(cur!.windDirDeg!) : null;

    // Ondas
    final waveHeightM = cur?.waveHeightM ?? 0.6;

    // Condição atmosférica
    final condIcon = _wmoIcon(cur?.weatherCode);
    final condText = _wmoText(cur?.weatherCode);

    return WeatherData(
      location: location,
      temperature: tempC,
      condition: condText,
      conditionIcon: condIcon,
      windSpeed: windSpeedKmh,
      windDir: windDir,
      waveHeight: waveHeightM,
      tideHeight: tideHeightM,
      tideRising: tideRising,
      hasTide: hasTide,
      moonPhase: moonPhase,
      moonIcon: moonIcon,
      solunarScore: solunarScore,
      pressure: pressureHpa?.round(),
    );
  }

  // ─── Condições horárias (score por hora) ────────────────────────────────────

  /// Heurística leve reutilizando lua + céu + chuva (alinhada ao Oráculo rio).
  int _hourlyOracleScore(ForecastWeatherHour h) {
    final cloud = h.cloudCoverPct ?? 30.0;
    final rain = h.precipitationMm ?? 0;
    final hour = h.time.hour;

    var dawnDusk = 1.0;
    if ((hour >= 5 && hour <= 9) || (hour >= 17 && hour <= 21)) {
      dawnDusk = 1.12;
    }

    final moon = moonFishingFactor(h.time) * 25;
    final cloudScore = (1 - cloud / 100) * 35 * dawnDusk;
    final rainPenalty = (rain * 8).clamp(0.0, 25.0);

    return (moon + cloudScore - rainPenalty).round().clamp(0, 100);
  }

  List<FeaturedSpot> _spotsWithDistance(
    double userLat,
    double userLon, {
    required double waveHeightM,
  }) {
    return _featuredSpotsBase.map((s) {
      final km = _haversineKm(userLat, userLon, s.lat, s.lon);
      return FeaturedSpot(
        id: s.id,
        name: s.name,
        imageUrl: s.imageUrl,
        quality: s.quality,
        lat: s.lat,
        lon: s.lon,
        species: s.species,
        scorePercent: s.scorePercent,
        distanceKm: km > 1 ? km : s.distanceKm,
        waveHeightM: waveHeightM,
      );
    }).toList();
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  List<HourlyCondition> _mapHourly(
      List<ForecastWeatherHour> series, DateTime now) {
    final upcoming = series.where((h) => h.time.isAfter(now)).take(12).toList();
    if (upcoming.isEmpty) return [];
    final items = upcoming.map((h) {
      final hourStr = '${h.time.hour.toString().padLeft(2, '0')}:00';
      return HourlyCondition(
        hour: hourStr,
        oracleScore: _hourlyOracleScore(h),
      );
    }).toList();
    final sorted = [...items]..sort((a, b) => b.displayScore.compareTo(a.displayScore));
    return [
      for (var i = 0; i < sorted.length && i < 6; i++)
        HourlyCondition(
          hour: sorted[i].hour,
          oracleScore: sorted[i].oracleScore,
          isBestHour: i == 0,
        ),
    ];
  }

  List<HourlyCondition> _fallbackHourly(DateTime now) {
    final items = List.generate(5, (i) {
      final h = (now.hour + i + 1) % 24;
      final fakeTime = DateTime(now.year, now.month, now.day, h);
      final cloud = 20.0 + (i * 12.0);
      final fake = ForecastWeatherHour(
        time: fakeTime,
        cloudCoverPct: cloud,
        precipitationMm: 0,
      );
      return HourlyCondition(
        hour: '${h.toString().padLeft(2, '0')}:00',
        oracleScore: _hourlyOracleScore(fake),
      );
    });
    final sorted = [...items]..sort((a, b) => b.displayScore.compareTo(a.displayScore));
    return [
      for (var i = 0; i < sorted.length; i++)
        HourlyCondition(
          hour: sorted[i].hour,
          oracleScore: sorted[i].oracleScore,
          isBestHour: i == 0,
        ),
    ];
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String _getUserDisplayName() {
    try {
      final user = supabaseClientOrNull?.auth.currentUser;
      if (user == null) return 'Pescador';
      final m = user.userMetadata;
      final fullName = m?['full_name'] as String? ?? m?['name'] as String?;
      if (fullName != null && fullName.trim().isNotEmpty) {
        return fullName.trim().split(RegExp(r'\s+')).first;
      }
      final email = user.email ?? '';
      if (email.contains('@')) return email.split('@').first;
    } catch (_) {}
    return 'Pescador';
  }

  int _defaultSolunar(DateTime now) {
    // Fallback solunar baseado na fase lunar real
    try {
      // moonFishingFactor está em moon_phase.dart — importado via OracleDataService
      // Usa o score do bundle se disponível, senão 50
      return OracleDataService.instance.lastBundle?.score ?? 50;
    } catch (_) {
      return 50;
    }
  }

  String _moonIcon(String phase) {
    final p = phase.toLowerCase();
    if (p.contains('cheia') || p.contains('llena')) return '🌕';
    if (p.contains('nova') || p.contains('nueva')) return '🌑';
    if (p.contains('crescente') || p.contains('creciente')) return '🌙';
    if (p.contains('minguante')) return '🌛';
    return '🌙';
  }

  /// Converte graus (0–360) para ponto cardeal de 8 posições.
  String _cardinal(int deg) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final idx = ((deg + 22.5) / 45).floor() % 8;
    return dirs[idx];
  }

  /// Ícone a partir do código WMO.
  String _wmoIcon(int? code) {
    if (code == null) return '☀️';
    if (code == 0) return '☀️';
    if (code <= 2) return '🌤️';
    if (code == 3) return '☁️';
    if (code <= 49) return '🌫️';
    if (code <= 55) return '🌦️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '❄️';
    if (code <= 82) return '🌦️';
    if (code <= 94) return '⛈️';
    return '⛈️';
  }

  /// Texto a partir do código WMO (PT).
  String _wmoText(int? code) {
    if (code == null) return 'Céu limpo';
    if (code == 0) return 'Céu limpo';
    if (code == 1) return 'Maioritariamente limpo';
    if (code == 2) return 'Parcialmente nublado';
    if (code == 3) return 'Nublado';
    if (code <= 49) return 'Nevoeiro';
    if (code <= 55) return 'Chuvisco';
    if (code <= 67) return 'Chuva';
    if (code <= 77) return 'Neve';
    if (code <= 82) return 'Aguaceiros leves';
    return 'Trovoada';
  }
}
