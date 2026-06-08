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
    if (perm == LocationPermission.denied) {
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
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return check();
  }

  static Future<bool> openSystemSettings(GpsAccessStatus status) async {
    if (status == GpsAccessStatus.serviceOff) {
      return Geolocator.openLocationSettings();
    }
    return Geolocator.openAppSettings();
  }
}
