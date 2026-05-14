import 'dart:convert';

import 'package:http/http.dart' as http;

/// Resultado de reverse geocode (etiqueta + país ISO2 quando disponível).
class OsmReverseResult {
  const OsmReverseResult({required this.label, this.countryIso2});
  final String label;
  /// 'PT', 'ES', … em maiúsculas, ou null.
  final String? countryIso2;
}

/// Nome legível para coordenadas (OpenStreetMap Nominatim — uso moderado).
Future<String> reverseGeocodePlaceLabel(double lat, double lon) async {
  final r = await reverseGeocodePlaceDetail(
    lat,
    lon,
    acceptLanguage: 'pt',
  );
  return r?.label ?? '';
}

Future<OsmReverseResult?> reverseGeocodePlaceDetail(
  double lat,
  double lon, {
  required String acceptLanguage,
}) async {
  try {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'format': 'json',
      'accept-language': acceptLanguage,
      'zoom': '11',
      'addressdetails': '1',
    });
    final res = await http
        .get(
          uri,
          headers: const {
            'User-Agent': 'AQUANAUTIX/1.0 (+https://aquanautix.vercel.app)',
          },
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final addr = map['address'];
    if (addr is! Map<String, dynamic>) return null;

    String? get(String k) => addr[k]?.toString();
    final ccRaw = get('country_code');
    final countryIso2 = ccRaw != null && ccRaw.length == 2
        ? ccRaw.toUpperCase()
        : null;

    final locality = get('city') ??
        get('town') ??
        get('village') ??
        get('hamlet') ??
        get('municipality');
    final district = get('county') ?? get('state');

    String label;
    if (locality != null &&
        district != null &&
        district.toLowerCase() != locality.toLowerCase()) {
      label = '$locality · $district';
    } else if (locality != null) {
      label = locality;
    } else {
      final disp = map['display_name'];
      if (disp is String && disp.isNotEmpty) {
        final parts = disp
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (parts.length >= 2) {
          label = '${parts[0]} · ${parts[1]}';
        } else {
          label = parts.first;
        }
      } else {
        label = '';
      }
    }

    return OsmReverseResult(label: label, countryIso2: countryIso2);
  } catch (_) {
    return null;
  }
}
