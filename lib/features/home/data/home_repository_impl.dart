import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/state/fishing_context_store.dart';
import '../../../core/tides/marine_bundle.dart';
import '../../../core/tides/moon_phase.dart';
import '../../../core/tides/open_meteo_tides_repository.dart';
import '../../../core/tides/oracle_data_service.dart';
import '../../../core/tides/region_presets.dart';
import '../domain/entities/community_activity.dart';
import '../domain/entities/featured_spot.dart';
import '../domain/entities/hourly_condition.dart';
import '../domain/entities/weather_data.dart';
import '../domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final _meteo = OpenMeteoTidesRepository();

  // ─── Spots em destaque (fotos reais em assets/marketing/spots/) ───────────
  static const _featuredSpots = [
    FeaturedSpot(
      id: '1',
      name: 'Cabo da Roca',
      imageUrl: 'assets/marketing/spots/cabo_da_roca.jpg',
      quality: SpotQuality.excelente,
    ),
    FeaturedSpot(
      id: '2',
      name: 'Peniche',
      imageUrl: 'assets/marketing/spots/peniche.jpg',
      quality: SpotQuality.muitoBom,
    ),
    FeaturedSpot(
      id: '3',
      name: 'Sesimbra',
      imageUrl: 'assets/marketing/spots/sesimbra.jpg',
      quality: SpotQuality.bom,
    ),
  ];

  // ─── Comunidade (fotos reais em assets/marketing/catches/) ────────────────
  static List<CommunityActivity> _communityActivities(DateTime now) => [
        CommunityActivity(
          userId: 'brunopescas',
          username: 'BrunoPescas',
          avatarUrl:
              'https://images.unsplash.com/photo-1568602471122-7832951cc4c5?w=96&q=80',
          activityText: 'Apanhou uma Dourada de 2.4 kg em Sesimbra',
          catchImageUrl: 'assets/marketing/catches/dourada.jpg',
          timestamp: now.subtract(const Duration(hours: 2)),
        ),
        CommunityActivity(
          userId: 'nuno_sesimbra',
          username: 'Nuno_Sesimbra',
          avatarUrl:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=96&q=80',
          activityText: 'Robalo de 2.8 kg no surfcasting · Sesimbra',
          catchImageUrl: 'assets/marketing/catches/robalo.jpg',
          timestamp: now.subtract(const Duration(hours: 5)),
        ),
        CommunityActivity(
          userId: 'miguel_peniche',
          username: 'Miguel_Peniche',
          avatarUrl:
              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=96&q=80',
          activityText: 'Sargo de 1.6 kg na costa rochosa · Peniche',
          catchImageUrl: 'assets/marketing/catches/sargo.jpg',
          timestamp: now.subtract(const Duration(hours: 9)),
        ),
      ];

  // ─── loadDashboard ────────────────────────────────────────────────────────
  @override
  Future<HomeDashboardData> loadDashboard() async {
    final now = DateTime.now();

    // 1. GPS — best effort (8 s timeout); se falhar usa região padrão
    double? lat, lon;
    // ignore: unused_local_variable — reservado para futura distinção GPS/fallback
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.denied &&
          perm != LocationPermission.deniedForever) {
        if (await Geolocator.isLocationServiceEnabled()) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 8),
            ),
          );
          lat = pos.latitude;
          lon = pos.longitude;
        }
      }
    } catch (_) {
      // GPS indisponível — usa coordenadas da região padrão abaixo
    }

    // Fallback de coordenadas: região padrão do utilizador (sem GPS)
    if (lat == null || lon == null) {
      final preset = TideMapPreset.forRegion(
        FishingContextStore.instance.value.value.region,
      );
      lat = preset.latitude;
      lon = preset.longitude;
    }

    // 2. OracleBundle — reutiliza cache de 30 min se disponível
    OracleBundle? bundle;
    // Primeiro tenta o cache sem nova chamada GPS
    bundle = OracleDataService.instance.lastBundle;
    if (bundle == null) {
      try {
        bundle = await OracleDataService.instance.fetch(
          ctx: FishingContextStore.instance.value.value,
        );
      } catch (_) {}
    }

    // 3. Condições actuais (vento, ondas, ícone) — paralelo, best effort
    ({
      double? tempC,
      double? windSpeedKmh,
      int? windDirDeg,
      double? waveHeightM,
      int? weatherCode,
    })? cur;
    cur = await _meteo.fetchCurrentConditions(
      latitude: lat,
      longitude: lon,
    );

    // 4. Condições horárias (próximas 5 horas)
    var hourly = _fallbackHourly(now);
    {
      try {
        final tz = TideMapPreset.timezoneForCountry(
          FishingContextStore.instance.value.value.country,
        );
        final series = await _meteo.fetchForecastWeatherSeries(
          latitude: lat,
          longitude: lon,
          timezone: tz,
          pastDays: 0,
          forecastDays: 1,
        );
        final mapped = _mapHourly(series, now);
        if (mapped.isNotEmpty) hourly = mapped;
      } catch (_) {}
    }

    // 5. Monta WeatherData
    final weather = _buildWeatherData(bundle, cur, now);

    return HomeDashboardData(
      userDisplayName: _getUserDisplayName(),
      weather: weather,
      hourlyConditions: hourly,
      featuredSpots: _featuredSpots,
      communityActivities: _communityActivities(now),
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

    // Localização: usa bundle (geocodificado) ou região padrão como fallback
    final String location;
    if (bundle != null && bundle.locationHeadline.isNotEmpty &&
        !bundle.locationHeadline.contains('pt') &&
        !bundle.locationHeadline.contains('es')) {
      location = bundle.locationHeadline;
    } else {
      final preset = TideMapPreset.forRegion(
        FishingContextStore.instance.value.value.region,
      );
      location = preset.label;
    }

    // Pressão
    final pressureHpa = bundle?.pressureHpa ?? cur?.tempC;

    // Maré
    final tideHeightM = bundle?.tideHeightM ?? 1.2;
    final tideRising = bundle != null
        ? (bundle.tideTrendPt.contains('subir') ||
            bundle.tideTrendPt.contains('↑'))
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

  List<HourlyCondition> _withBestHour(List<HourlyCondition> items) {
    if (items.isEmpty) return items;
    var bestIdx = 0;
    var bestScore = items.first.oracleScore;
    for (var i = 1; i < items.length; i++) {
      if (items[i].oracleScore > bestScore) {
        bestScore = items[i].oracleScore;
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

  List<HourlyCondition> _mapHourly(
      List<ForecastWeatherHour> series, DateTime now) {
    final upcoming = series.where((h) => h.time.isAfter(now)).take(5).toList();
    if (upcoming.isEmpty) return [];
    final items = upcoming.map((h) {
      final hourStr = '${h.time.hour.toString().padLeft(2, '0')}:00';
      return HourlyCondition(
        hour: hourStr,
        oracleScore: _hourlyOracleScore(h),
      );
    }).toList();
    return _withBestHour(items);
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
    return _withBestHour(items);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String _getUserDisplayName() {
    try {
      final user = Supabase.instance.client.auth.currentUser;
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
    if (code <= 82) return 'Aguaceiros';
    return 'Trovoada';
  }
}
