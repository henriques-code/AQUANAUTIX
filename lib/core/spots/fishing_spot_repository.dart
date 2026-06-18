// lib/core/spots/fishing_spot_repository.dart

import 'package:latlong2/latlong.dart';

import '../supabase_bootstrap.dart';
import 'fishing_spot.dart';

class FishingSpotRepository {
  static const _table = 'fishing_spots';

  static double _distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const d = Distance();
    return d.as(LengthUnit.Kilometer, LatLng(lat1, lon1), LatLng(lat2, lon2));
  }

  /// Spots de fallback offline (espelham seed da migration).
  static final List<FishingSpot> _fallbackSpots = [
    const FishingSpot(
      id: 'local-alqueva',
      name: 'Barragem de Alqueva',
      lat: 38.2,
      lon: -7.5,
      tier: 'free',
      country: 'PT',
      region: 'Alentejo',
      zoneType: 'barragem',
      species: ['Achigã', 'Carpa'],
      bestSeason: ['Primavera'],
      bestBait: ['Shad', 'Minhoca'],
      difficulty: 2,
      scoreAvg: 82,
    ),
    const FishingSpot(
      id: 'local-sesimbra',
      name: 'Praia de Sesimbra',
      lat: 38.44,
      lon: -9.1,
      tier: 'free',
      country: 'PT',
      region: 'Setúbal',
      zoneType: 'costa',
      species: ['Robalo', 'Sargo'],
      bestSeason: ['Outono'],
      bestBait: ['Lula'],
      difficulty: 2,
      scoreAvg: 78,
    ),
    const FishingSpot(
      id: 'local-mondego',
      name: 'Rio Mondego Coimbra',
      lat: 40.2,
      lon: -8.4,
      tier: 'free',
      country: 'PT',
      region: 'Centro',
      zoneType: 'rio',
      species: ['Barbo', 'Achigã'],
      bestSeason: ['Primavera'],
      bestBait: ['Milho'],
      difficulty: 1,
      scoreAvg: 71,
    ),
    const FishingSpot(
      id: 'local-espichel',
      name: 'Cabo Espichel',
      lat: 38.41,
      lon: -9.22,
      tier: 'pro',
      country: 'PT',
      region: 'Setúbal',
      zoneType: 'costa',
      species: ['Corvina', 'Robalo'],
      bestSeason: ['Inverno'],
      bestBait: ['Lula'],
      difficulty: 4,
      scoreAvg: 85,
    ),
    const FishingSpot(
      id: 'local-ebro',
      name: 'Delta del Ebro',
      lat: 40.7,
      lon: 0.9,
      tier: 'pro',
      country: 'ES',
      region: 'Tarragona',
      zoneType: 'rio',
      species: ['Lúcio', 'Carpa'],
      bestSeason: ['Primavera'],
      bestBait: ['Jig'],
      difficulty: 2,
      scoreAvg: 79,
    ),
  ];

  List<FishingSpot> _filterNearby(
    List<FishingSpot> spots, {
    required double lat,
    required double lon,
    required double radiusKm,
  }) {
    final out = spots
        .where((s) => _distanceKm(lat, lon, s.lat, s.lon) <= radiusKm)
        .toList()
      ..sort(
        (a, b) => _distanceKm(lat, lon, a.lat, a.lon)
            .compareTo(_distanceKm(lat, lon, b.lat, b.lon)),
      );
    return out;
  }

  Future<List<FishingSpot>> fetchNearby({
    required double lat,
    required double lon,
    double radiusKm = 100,
  }) async {
    if (!canUseSupabase) {
      return _filterNearby(
        _fallbackSpots,
        lat: lat,
        lon: lon,
        radiusKm: radiusKm,
      );
    }

    final client = supabaseClientOrNull;
    if (client == null) {
      return _filterNearby(
        _fallbackSpots,
        lat: lat,
        lon: lon,
        radiusKm: radiusKm,
      );
    }

    try {
      final rows = await client
          .from(_table)
          .select()
          .order('score_avg', ascending: false)
          .limit(200);

      final spots = (rows as List)
          .cast<Map<String, dynamic>>()
          .map(FishingSpot.fromJson)
          .toList();

      final nearby = _filterNearby(
        spots,
        lat: lat,
        lon: lon,
        radiusKm: radiusKm,
      );

      if (nearby.isNotEmpty) return nearby;

      // RLS pode devolver só tier free — complementar com fallback local.
      return _filterNearby(
        _fallbackSpots,
        lat: lat,
        lon: lon,
        radiusKm: radiusKm,
      );
    } catch (e) {
      return _filterNearby(
        _fallbackSpots,
        lat: lat,
        lon: lon,
        radiusKm: radiusKm,
      );
    }
  }

  Future<List<FishingSpot>> fetchBySpecies(String species) async {
    final needle = species.trim();
    if (needle.isEmpty) return [];

    bool matches(FishingSpot s) => s.species.any(
          (x) => x.toLowerCase() == needle.toLowerCase(),
        );

    if (!canUseSupabase) {
      return _fallbackSpots.where(matches).toList();
    }

    final client = supabaseClientOrNull;
    if (client == null) {
      return _fallbackSpots.where(matches).toList();
    }

    try {
      final rows = await client
          .from(_table)
          .select()
          .contains('species', [needle])
          .order('score_avg', ascending: false)
          .limit(50);

      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(FishingSpot.fromJson)
          .toList();
    } catch (_) {
      return _fallbackSpots.where(matches).toList();
    }
  }
}
