import 'dart:async';

import 'gps_access.dart';

/// Arranque GPS — permissão síncrona; fix em background (não bloqueia Início).
class GpsBootstrap {
  GpsBootstrap._();

  static Future<GpsAccessStatus>? _permissionFuture;
  static GpsAccessStatus? _lastStatus;

  static GpsAccessStatus? get lastStatus => _lastStatus;

  /// Só pede permissão (diálogo MIUI). Não espera pelo fix GPS.
  static Future<GpsAccessStatus> ensurePermission({bool forceRetry = false}) {
    if (forceRetry) _permissionFuture = null;
    _permissionFuture ??= _requestPermission();
    return _permissionFuture!;
  }

  /// Fix GPS curto — usar em background após permissão ou no pull-to-refresh.
  static Future<({double lat, double lon})?> refreshFix({
    Duration timeout = const Duration(seconds: 12),
    bool forceRefresh = false,
  }) async {
    if (await GpsAccess.check() != GpsAccessStatus.granted) return null;
    return GpsAccess.tryGetFix(timeout: timeout, forceRefresh: forceRefresh);
  }

  /// Legado: permissão + fix (evitar no caminho crítico do Início).
  static Future<GpsAccessStatus> ensureOnAppEntry({
    Duration fixTimeout = const Duration(seconds: 5),
    bool forceRetry = false,
  }) async {
    final status = await ensurePermission(forceRetry: forceRetry);
    if (status == GpsAccessStatus.granted) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await refreshFix(timeout: fixTimeout);
    }
    return status;
  }

  static Future<GpsAccessStatus> _requestPermission() async {
    var status = await GpsAccess.check();
    if (status != GpsAccessStatus.granted) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      status = await GpsAccess.request();
    }
    _lastStatus = status;
    return status;
  }

  static void reset() {
    _permissionFuture = null;
    _lastStatus = null;
  }
}
