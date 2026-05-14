import 'dart:math';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Contexto estável por instalação (funil, retenção D1/D7, versão da app).
abstract class AnalyticsContext {
  AnalyticsContext._();

  static const _kInstallId = 'analytics_install_id_v1';
  static const _kFirstOpenUtc = 'analytics_first_open_at_v1';

  static String? _installId;
  static DateTime? _firstOpenUtc;
  static String _appVersion = '1.0.0';

  static String? get installId => _installId;

  static int? get daysSinceFirstOpenUtc {
    final t = _firstOpenUtc;
    if (t == null) return null;
    final now = DateTime.now().toUtc();
    return now.difference(t).inHours ~/ 24;
  }

  static Map<String, dynamic> baseParams() {
    return {
      if (_installId != null) 'install_id': _installId,
      if (daysSinceFirstOpenUtc != null) 'days_since_first_open': daysSinceFirstOpenUtc,
      'app_version': _appVersion,
    };
  }

  static Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    _installId = p.getString(_kInstallId) ?? _newInstallId();
    await p.setString(_kInstallId, _installId!);

    final raw = p.getString(_kFirstOpenUtc);
    if (raw == null) {
      _firstOpenUtc = DateTime.now().toUtc();
      await p.setString(_kFirstOpenUtc, _firstOpenUtc!.toIso8601String());
    } else {
      _firstOpenUtc = DateTime.tryParse(raw)?.toUtc();
    }

    try {
      final pi = await PackageInfo.fromPlatform();
      _appVersion = '${pi.version}+${pi.buildNumber}';
    } catch (_) {}
  }

  static String _newInstallId() {
    final r = Random();
    return 'aqx_${DateTime.now().microsecondsSinceEpoch}_${r.nextInt(1 << 20)}';
  }
}
