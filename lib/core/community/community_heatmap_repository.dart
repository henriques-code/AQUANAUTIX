import 'package:latlong2/latlong.dart';

import '../supabase_bootstrap.dart';

/// Hotspot Ghost agregado por zona (≥5 km — sem coords exactas).
class HeatmapZone {
  final String zoneLabel;
  final double lat;
  final double lon;
  final int catchCount;
  final String topSpecies;

  const HeatmapZone({
    required this.zoneLabel,
    required this.lat,
    required this.lon,
    required this.catchCount,
    required this.topSpecies,
  });
}

class CommunityHeatmapRepository {
  static const _table = 'community_posts';
  static const _maxZones = 20;

  /// Centróides aproximados por etiqueta de zona (Ghost — não são GPS reais).
  static const Map<String, (double lat, double lon)> _zoneCentroids = {
    'zona sesimbra': (38.44, -9.10),
    'sesimbra': (38.44, -9.10),
    'zona peniche': (39.36, -9.38),
    'peniche': (39.36, -9.38),
    'zona comporta': (38.37, -8.78),
    'comporta': (38.37, -8.78),
    'zona setubal': (38.52, -8.88),
    'setubal': (38.52, -8.88),
    'laranjeiro': (38.66, -9.15),
    'almada': (38.66, -9.15),
    'zona ericeira': (38.97, -9.42),
    'ericeira': (38.97, -9.42),
    'cascais': (38.70, -9.42),
    'zona cascais': (38.70, -9.42),
    'sagres': (37.01, -8.95),
    'algarve': (37.10, -8.20),
    'vigo': (42.23, -8.73),
    'zona vigo': (42.23, -8.73),
    'a coruna': (43.37, -8.40),
    'coruna': (43.37, -8.40),
    'zona tarragona': (40.72, 0.87),
    'delta ebro': (40.72, 0.87),
    'zona coimbra': (40.20, -8.43),
    'mondego': (40.20, -8.43),
    'zona aveiro': (40.64, -8.65),
    'aveiro': (40.64, -8.65),
  };

  static final List<HeatmapZone> _fallbackZones = [
    const HeatmapZone(
      zoneLabel: 'Zona Sesimbra',
      lat: 38.44,
      lon: -9.10,
      catchCount: 12,
      topSpecies: 'ROBALO',
    ),
    const HeatmapZone(
      zoneLabel: 'Zona Peniche',
      lat: 39.36,
      lon: -9.38,
      catchCount: 8,
      topSpecies: 'DOURADA',
    ),
    const HeatmapZone(
      zoneLabel: 'Zona Comporta',
      lat: 38.37,
      lon: -8.78,
      catchCount: 5,
      topSpecies: 'SARGO',
    ),
    const HeatmapZone(
      zoneLabel: 'Zona Setúbal',
      lat: 38.52,
      lon: -8.88,
      catchCount: 4,
      topSpecies: 'DOURADA',
    ),
  ];

  static double _distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const d = Distance();
    return d.as(LengthUnit.Kilometer, LatLng(lat1, lon1), LatLng(lat2, lon2));
  }

  static String _normalizeZoneKey(String raw) {
    return raw
        .toLowerCase()
        .trim()
        .replaceAll('ú', 'u')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ã', 'a')
        .replaceAll('ç', 'c');
  }

  static (double, double)? _centroidFor(String zoneLabel) {
    final key = _normalizeZoneKey(zoneLabel);
    if (key.isEmpty) return null;
    final direct = _zoneCentroids[key];
    if (direct != null) return direct;
    for (final e in _zoneCentroids.entries) {
      if (key.contains(e.key) || e.key.contains(key)) return e.value;
    }
    return null;
  }

  static String _topSpecies(Map<String, int> speciesCounts) {
    if (speciesCounts.isEmpty) return '—';
    final sorted = speciesCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  Future<List<HeatmapZone>> fetchHeatmap({
    required double lat,
    required double lon,
    double radiusKm = 120,
  }) async {
    if (!canUseSupabase) {
      return _filterNearby(_fallbackZones, lat: lat, lon: lon, radiusKm: radiusKm);
    }

    final client = supabaseClientOrNull;
    if (client == null) {
      return _filterNearby(_fallbackZones, lat: lat, lon: lon, radiusKm: radiusKm);
    }

    try {
      final since = DateTime.now()
          .subtract(const Duration(days: 7))
          .toUtc()
          .toIso8601String();

      final rows = await client
          .from(_table)
          .select('zone_label, zone_id, species')
          .gte('created_at', since)
          .order('created_at', ascending: false)
          .limit(400);

      final list = (rows as List).cast<Map<String, dynamic>>();
      if (list.isEmpty) {
        return _filterNearby(_fallbackZones, lat: lat, lon: lon, radiusKm: radiusKm);
      }

      final byZone = <String, ({int count, Map<String, int> species})>{};
      for (final row in list) {
        final label = (row['zone_label'] as String?)?.trim() ??
            (row['zone_id'] as String?)?.trim() ??
            '';
        if (label.isEmpty) continue;
        final species = (row['species'] as String?)?.trim().toUpperCase() ?? '—';
        final bucket = byZone.putIfAbsent(
          label,
          () => (count: 0, species: <String, int>{}),
        );
        byZone[label] = (
          count: bucket.count + 1,
          species: {...bucket.species, species: (bucket.species[species] ?? 0) + 1},
        );
      }

      final zones = <HeatmapZone>[];
      for (final e in byZone.entries) {
        final centroid = _centroidFor(e.key);
        if (centroid == null) continue;
        zones.add(
          HeatmapZone(
            zoneLabel: e.key,
            lat: centroid.$1,
            lon: centroid.$2,
            catchCount: e.value.count,
            topSpecies: _topSpecies(e.value.species),
          ),
        );
      }

      zones.sort((a, b) => b.catchCount.compareTo(a.catchCount));
      final limited = zones.length > _maxZones ? zones.sublist(0, _maxZones) : zones;

      final nearby = _filterNearby(limited, lat: lat, lon: lon, radiusKm: radiusKm);
      if (nearby.isNotEmpty) return nearby;

      return _filterNearby(_fallbackZones, lat: lat, lon: lon, radiusKm: radiusKm);
    } catch (_) {
      return _filterNearby(_fallbackZones, lat: lat, lon: lon, radiusKm: radiusKm);
    }
  }

  List<HeatmapZone> _filterNearby(
    List<HeatmapZone> zones, {
    required double lat,
    required double lon,
    required double radiusKm,
  }) {
    return zones
        .where((z) => _distanceKm(lat, lon, z.lat, z.lon) <= radiusKm)
        .toList()
      ..sort((a, b) => b.catchCount.compareTo(a.catchCount));
  }
}
