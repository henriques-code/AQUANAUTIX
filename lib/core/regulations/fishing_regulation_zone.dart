import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

/// Zona regulamentada DGRM / MITERD para overlay no mapa.
class FishingRegulationZone {
  final String name;
  final String country;
  final String tipo;
  final String ruleSummary;
  final String contactUrl;
  final List<LatLng> points;

  const FishingRegulationZone({
    required this.name,
    required this.country,
    required this.tipo,
    required this.ruleSummary,
    required this.contactUrl,
    required this.points,
  });

  static const assetPath = 'assets/data/fishing_regulations_pt_es.geojson';

  static Future<List<FishingRegulationZone>> loadFromAsset() async {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final features = json['features'] as List<dynamic>? ?? [];
    final out = <FishingRegulationZone>[];
    for (final f in features) {
      final feature = f as Map<String, dynamic>;
      final props = feature['properties'] as Map<String, dynamic>? ?? {};
      final geom = feature['geometry'] as Map<String, dynamic>?;
      if (geom == null) continue;
      final ring = _outerRing(geom);
      if (ring == null || ring.length < 3) continue;
      out.add(
        FishingRegulationZone(
          name: props['name'] as String? ?? 'Zona regulamentada',
          country: props['country'] as String? ?? 'PT',
          tipo: props['tipo'] as String? ?? 'proibido',
          ruleSummary: props['rule_summary'] as String? ?? '',
          contactUrl: props['contact_url'] as String? ?? 'https://www.dgrm.pt/',
          points: ring,
        ),
      );
    }
    return out;
  }

  static List<LatLng>? _outerRing(Map<String, dynamic> geom) {
    final type = geom['type'] as String?;
    final coords = geom['coordinates'];
    if (coords is! List || coords.isEmpty) return null;

    List<dynamic> ring;
    if (type == 'Polygon') {
      ring = coords.first as List<dynamic>;
    } else if (type == 'LineString') {
      ring = coords;
    } else {
      return null;
    }

    return ring
        .map((c) {
          final pair = c as List<dynamic>;
          return LatLng(
            (pair[1] as num).toDouble(),
            (pair[0] as num).toDouble(),
          );
        })
        .toList();
  }
}
