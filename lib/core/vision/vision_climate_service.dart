import '../location/gps_access.dart';
import '../state/fishing_context_store.dart';
import '../tides/open_meteo_tides_repository.dart';
import '../tides/oracle_data_service.dart';
import '../tides/osm_place_search.dart';
import '../tides/region_presets.dart';
import 'vision_climate_snapshot.dart';

/// Obtém clima actual (Open‑Meteo + maré Oráculo) para o Vision Scanner.
class VisionClimateService {
  VisionClimateService._();
  static final VisionClimateService instance = VisionClimateService._();

  final _meteo = OpenMeteoTidesRepository();

  Future<VisionClimateSnapshot> fetch() async {
    final ctx = FishingContextStore.instance.value.value;
    final preset = TideMapPreset.forRegion(ctx.region);

    final gpsGranted = await GpsAccess.check() == GpsAccessStatus.granted;
    ({double lat, double lon})? fix;
    if (gpsGranted) {
      fix = GpsAccess.cachedFix ?? GpsAccess.cachedFixStale;
      fix ??= await GpsAccess.tryGetFix(timeout: const Duration(seconds: 8));
    } else {
      fix = GpsAccess.cachedFix ?? GpsAccess.cachedFixStale;
    }

    final hasGpsCoords = gpsGranted && fix != null;
    final lat = fix?.lat ?? preset.latitude;
    final lon = fix?.lon ?? preset.longitude;

    final regionalPlace = OsmPlace(
      lat: preset.latitude,
      lon: preset.longitude,
      label: preset.label,
      displayName: preset.label,
    );

    OracleBundle? bundle = OracleDataService.instance.lastBundle;
    final bundleNeedsGpsRefresh =
        hasGpsCoords && bundle != null && !bundle.usedGps;
    if (bundle == null || bundleNeedsGpsRefresh) {
      try {
        if (hasGpsCoords) {
          bundle = await OracleDataService.instance
              .fetch(ctx: ctx, knownCoords: fix)
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

    ({
      double? tempC,
      double? windSpeedKmh,
      int? windDirDeg,
      double? waveHeightM,
      int? weatherCode,
      double? waterTempC,
      double? pressureHpa,
    })? cur;
    try {
      cur = await _meteo
          .fetchCurrentConditions(latitude: lat, longitude: lon)
          .timeout(const Duration(seconds: 8));
    } catch (_) {}

    final location = _locationLabel(bundle, preset.label);
    final tempC = bundle?.tempC ?? cur?.tempC;
    final tideHeightM = bundle?.tideHeightM;
    final tideRising = bundle != null
        ? (bundle.tideTrendPt.contains('subir') ||
            bundle.tideTrendPt.contains('↑') ||
            bundle.tideTrendPt.contains('creciente') ||
            bundle.tideTrendPt.contains('Enchente'))
        : true;

    return VisionClimateSnapshot(
      locationLabel: location,
      usedGps: hasGpsCoords && (bundle?.usedGps ?? false),
      temperatureC: tempC,
      conditionText: _wmoText(cur?.weatherCode),
      weatherCode: cur?.weatherCode,
      windKmh: cur?.windSpeedKmh,
      waveHeightM: cur?.waveHeightM,
      tideHeightM: tideHeightM,
      tideRising: tideRising,
    );
  }

  String _locationLabel(OracleBundle? bundle, String fallback) {
    if (bundle != null && bundle.locationHeadline.isNotEmpty) {
      return bundle.locationHeadline;
    }
    return fallback;
  }

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
