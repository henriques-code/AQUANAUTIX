import 'package:geolocator/geolocator.dart';

/// Estado de acesso GPS — partilhado Início / Oráculo / Mapa.
enum GpsAccessStatus {
  granted,
  denied,
  deniedForever,
  serviceOff,
}

class GpsAccess {
  GpsAccess._();

  static Future<({double lat, double lon})?>? _inFlight;
  static ({double lat, double lon})? _cachedFix;
  static DateTime? _cachedFixAt;

  static const _cacheFresh = Duration(minutes: 30);
  static const _cacheStaleMax = Duration(hours: 2);

  /// Fix recente em memória (evita rajadas de getCurrentPosition).
  static ({double lat, double lon})? get cachedFix {
    if (_cachedFix == null || _cachedFixAt == null) return null;
    if (DateTime.now().difference(_cachedFixAt!) > _cacheFresh) return null;
    return _cachedFix;
  }

  static ({double lat, double lon})? get cachedFixStale {
    if (_cachedFix == null || _cachedFixAt == null) return null;
    if (DateTime.now().difference(_cachedFixAt!) > _cacheStaleMax) return null;
    return _cachedFix;
  }

  static void _rememberFix(double lat, double lon) {
    _cachedFix = (lat: lat, lon: lon);
    _cachedFixAt = DateTime.now();
  }

  static Future<GpsAccessStatus> check() async {
    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.deniedForever) {
      return GpsAccessStatus.deniedForever;
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.unableToDetermine) {
      return GpsAccessStatus.denied;
    }
    if (perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always) {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return GpsAccessStatus.serviceOff;
      }
      return GpsAccessStatus.granted;
    }
    return GpsAccessStatus.denied;
  }

  /// Pede permissão ao SO (se ainda não foi pedida).
  static Future<GpsAccessStatus> request() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.unableToDetermine) {
      perm = await Geolocator.requestPermission();
    }
    return check();
  }

  /// Fix GPS robusto (MIUI/Android): cache → last-known → current (timeout curto).
  static Future<({double lat, double lon})?> tryGetFix({
    Duration freshMaxAge = const Duration(minutes: 45),
    Duration timeout = const Duration(seconds: 8),
    bool allowStaleCache = true,
  }) {
    final cached = cachedFix;
    if (cached != null) return Future.value(cached);

    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final future = _tryGetFixImpl(
      freshMaxAge: freshMaxAge,
      timeout: timeout,
      allowStaleCache: allowStaleCache,
    );
    _inFlight = future;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
  }

  /// Recheck leve (resume / tab) — não bloqueia dezenas de segundos.
  static Future<({double lat, double lon})?> tryGetFixQuick() {
    final cached = cachedFix ?? cachedFixStale;
    if (cached != null) return Future.value(cached);
    return tryGetFix(
      timeout: const Duration(seconds: 8),
      allowStaleCache: true,
    );
  }

  static Future<({double lat, double lon})?> _tryGetFixImpl({
    required Duration freshMaxAge,
    required Duration timeout,
    required bool allowStaleCache,
  }) async {
    if (await check() != GpsAccessStatus.granted) return null;

    Position? cached;
    try {
      cached = await Geolocator.getLastKnownPosition();
      if (cached != null) {
        final age = DateTime.now().difference(cached.timestamp);
        if (!age.isNegative && age <= freshMaxAge) {
          _rememberFix(cached.latitude, cached.longitude);
          return (lat: cached.latitude, lon: cached.longitude);
        }
      }
    } catch (_) {}

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
      _rememberFix(pos.latitude, pos.longitude);
      return (lat: pos.latitude, lon: pos.longitude);
    } catch (_) {}

    if (cached != null) {
      _rememberFix(cached.latitude, cached.longitude);
      return (lat: cached.latitude, lon: cached.longitude);
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 5),
        ),
      );
      _rememberFix(pos.latitude, pos.longitude);
      return (lat: pos.latitude, lon: pos.longitude);
    } catch (_) {}

    if (allowStaleCache) {
      final stale = cachedFixStale;
      if (stale != null) return stale;
    }

    return null;
  }

  static Future<bool> openSystemSettings(GpsAccessStatus status) async {
    if (status == GpsAccessStatus.serviceOff) {
      return Geolocator.openLocationSettings();
    }
    return Geolocator.openAppSettings();
  }
}
