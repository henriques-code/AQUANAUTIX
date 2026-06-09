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

  /// Fix GPS robusto (MIUI/Android): last-known recente → current → stale → low accuracy.
  static Future<({double lat, double lon})?> tryGetFix({
    Duration freshMaxAge = const Duration(minutes: 20),
    Duration timeout = const Duration(seconds: 28),
  }) async {
    if (await check() != GpsAccessStatus.granted) return null;

    Position? cached;
    try {
      cached = await Geolocator.getLastKnownPosition();
      if (cached != null) {
        final age = DateTime.now().difference(cached.timestamp);
        if (!age.isNegative && age <= freshMaxAge) {
          return (lat: cached.latitude, lon: cached.longitude);
        }
      }
    } catch (_) {}

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: timeout,
        ),
      );
      return (lat: pos.latitude, lon: pos.longitude);
    } catch (_) {}

    if (cached != null) {
      return (lat: cached.latitude, lon: cached.longitude);
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return (lat: pos.latitude, lon: pos.longitude);
    } catch (_) {}

    return null;
  }

  static Future<bool> openSystemSettings(GpsAccessStatus status) async {
    if (status == GpsAccessStatus.serviceOff) {
      return Geolocator.openLocationSettings();
    }
    return Geolocator.openAppSettings();
  }
}
