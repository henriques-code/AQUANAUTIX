import 'dart:convert';
import 'package:http/http.dart' as http;

/// Resultado do caudal fluvial em tempo real via Open-Meteo Flood API (GloFAS/Copernicus).
class RiverDischargeResult {
  const RiverDischargeResult({
    required this.currentM3s,
    required this.trend,
  });

  /// Caudal actual em m³/s. Null se indisponível para esta localização.
  final double? currentM3s;

  /// 'up' | 'down' | 'stable'
  final String trend;

  /// Formata o valor como string legível: "45 m³/s", "1.2 k m³/s", "< 1 m³/s".
  String get formatted {
    final v = currentM3s;
    if (v == null) return '—';
    if (v < 1) return '< 1 m³/s';
    if (v < 1000) return '${v.round()} m³/s';
    return '${(v / 1000).toStringAsFixed(1)} k m³/s';
  }

  /// Ícone de tendência para UI.
  String get trendIcon {
    switch (trend) {
      case 'up':
        return '↑';
      case 'down':
        return '↓';
      default:
        return '→';
    }
  }
}

/// Repositório de caudal fluvial usando a Open-Meteo Flood API (GloFAS Copernicus).
///
/// - Gratuito, sem API key.
/// - Dados GloFAS v4 (Copernicus, ECMWF).
/// - Cobertura global incluindo PT e ES.
/// - Resolução ~10 km — caudal da célula de grade mais próxima.
class RiverDischargeRepository {
  static const _baseUrl = 'https://flood-api.open-meteo.com/v1/flood';
  static const _ua = 'aquanautix-app/1.0 (contact@aquanautix.app)';
  static const _timeout = Duration(seconds: 10);

  /// Obtém caudal actual e tendência para [lat]/[lon].
  ///
  /// Retorna null em caso de erro de rede ou se a célula de grade não tiver
  /// dados de rio (zonas costeiras planas ou longe de canais principais).
  Future<RiverDischargeResult?> fetch({
    required double lat,
    required double lon,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl'
        '?latitude=${lat.toStringAsFixed(4)}'
        '&longitude=${lon.toStringAsFixed(4)}'
        '&daily=river_discharge'
        '&past_days=2'
        '&forecast_days=1',
      );

      final resp = await http
          .get(uri, headers: {'User-Agent': _ua})
          .timeout(_timeout);

      if (resp.statusCode != 200) return null;

      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final daily = body['daily'] as Map<String, dynamic>?;
      if (daily == null) return null;

      final times = (daily['time'] as List?)?.cast<String>() ?? [];
      final discharges =
          (daily['river_discharge'] as List?)?.cast<dynamic>() ?? [];

      if (times.isEmpty || discharges.isEmpty) return null;

      // Encontra o índice de hoje (UTC)
      final todayStr = DateTime.now().toUtc().toIso8601String().substring(0, 10);
      final todayIdx = times.indexOf(todayStr);

      double? todayVal;
      double? yesterdayVal;

      if (todayIdx >= 0) {
        final raw = discharges[todayIdx];
        todayVal = raw is num ? raw.toDouble() : null;
        if (todayIdx > 0) {
          final rawY = discharges[todayIdx - 1];
          yesterdayVal = rawY is num ? rawY.toDouble() : null;
        }
      } else {
        // Fallback: último valor não nulo
        for (var i = discharges.length - 1; i >= 0; i--) {
          final raw = discharges[i];
          if (raw is num) {
            todayVal = raw.toDouble();
            if (i > 0) {
              final rawP = discharges[i - 1];
              if (rawP is num) yesterdayVal = rawP.toDouble();
            }
            break;
          }
        }
      }

      if (todayVal == null) return null;

      String trend = 'stable';
      if (yesterdayVal != null) {
        if (todayVal > yesterdayVal * 1.10) {
          trend = 'up';
        } else if (todayVal < yesterdayVal * 0.90) {
          trend = 'down';
        }
      }

      return RiverDischargeResult(currentM3s: todayVal, trend: trend);
    } catch (_) {
      return null;
    }
  }
}
