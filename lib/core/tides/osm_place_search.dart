import 'dart:convert';

import 'package:http/http.dart' as http;

class OsmPlace {
  const OsmPlace({
    required this.lat,
    required this.lon,
    required this.label,
    required this.displayName,
  });

  final double lat;
  final double lon;

  /// Rótulo curto (ex.: «Nazaré · Leiria») — para chip e estado seleccionado.
  final String label;

  /// Nome completo Nominatim — para desambiguar na lista.
  final String displayName;
}

/// Forward geocode Nominatim — pesquisa por nome, até 5 resultados PT/ES.
Future<List<OsmPlace>> searchPlaces(
  String query, {
  String acceptLanguage = 'pt',
}) async {
  final q = query.trim();
  if (q.isEmpty) return [];
  try {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': q,
      'format': 'json',
      'limit': '5',
      'addressdetails': '1',
      'accept-language': acceptLanguage,
      'countrycodes': 'pt,es',
    });
    final res = await http
        .get(uri, headers: const {
          'User-Agent': 'AQUANAUTIX/1.0 (+https://aquanautix.vercel.app)',
        })
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return [];
    final raw = jsonDecode(res.body);
    if (raw is! List) return [];
    final places = <OsmPlace>[];
    for (final e in raw) {
      if (e is! Map<String, dynamic>) continue;
      final lat = double.tryParse(e['lat']?.toString() ?? '');
      final lon = double.tryParse(e['lon']?.toString() ?? '');
      if (lat == null || lon == null) continue;
      final displayName = e['display_name']?.toString() ?? '';
      final label = _buildLabel(e['address'], displayName);
      places.add(OsmPlace(lat: lat, lon: lon, label: label, displayName: displayName));
    }
    return places;
  } catch (_) {
    return [];
  }
}

String _buildLabel(dynamic addr, String displayName) {
  if (addr is Map<String, dynamic>) {
    String? get(String k) => addr[k]?.toString();
    final locality = get('city') ??
        get('town') ??
        get('village') ??
        get('hamlet') ??
        get('municipality');
    final district = get('county') ?? get('state');
    if (locality != null &&
        district != null &&
        district.toLowerCase() != locality.toLowerCase()) {
      return '$locality · $district';
    }
    if (locality != null) return locality;
  }
  final parts = displayName
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (parts.length >= 2) return '${parts[0]} · ${parts[1]}';
  return parts.isNotEmpty ? parts.first : displayName;
}
