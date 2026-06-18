// lib/core/spots/bait_shop_repository.dart

import 'package:latlong2/latlong.dart';

import '../supabase_bootstrap.dart';
import 'bait_shop.dart';

class BaitShopRepository {
  static const _table = 'bait_shops';

  static double _distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const d = Distance();
    return d.as(LengthUnit.Kilometer, LatLng(lat1, lon1), LatLng(lat2, lon2));
  }

  /// Fallback offline — espelha seed principal da migration.
  static final List<BaitShop> _fallbackShops = [
    const BaitShop(
      id: 'local-sesimbra-bait',
      name: 'Bait Sesimbra',
      lat: 38.443,
      lon: -9.100,
      country: 'PT',
      region: 'Setúbal',
      address: 'Sesimbra',
      hours: 'Seg-Sáb 9h-19h',
      speciality: ['vivos', 'mar'],
    ),
    const BaitShop(
      id: 'local-comporta',
      name: 'Iscos Comporta',
      lat: 38.372,
      lon: -8.781,
      country: 'PT',
      region: 'Setúbal',
      hours: 'Seg-Sáb 9h-20h',
      speciality: ['vivos', 'mar'],
    ),
    const BaitShop(
      id: 'local-ericeira',
      name: 'Ericeira Bait',
      lat: 38.969,
      lon: -9.418,
      country: 'PT',
      region: 'Lisboa',
      hours: 'Seg-Sáb 9h-19h',
      speciality: ['surf', 'mar'],
    ),
    const BaitShop(
      id: 'local-sagres',
      name: 'Sagres Tackle',
      lat: 37.011,
      lon: -8.948,
      country: 'PT',
      region: 'Algarve',
      hours: 'Seg-Sáb 9h-19h',
      speciality: ['mar', 'artificial'],
    ),
    const BaitShop(
      id: 'local-vigo',
      name: 'Vigo Mar Shop',
      lat: 42.226,
      lon: -8.734,
      country: 'ES',
      region: 'Galicia',
      hours: 'Cerrado domingo',
      speciality: ['mar', 'vivos'],
    ),
    const BaitShop(
      id: 'local-coruna',
      name: 'A Coruña Bait',
      lat: 43.370,
      lon: -8.398,
      country: 'ES',
      region: 'Galicia',
      hours: 'Lun-Sáb 10h-20h',
      speciality: ['surf', 'mar'],
    ),
    const BaitShop(
      id: 'local-lisboa-ativa',
      name: 'Pesca Ativa Lisboa',
      lat: 38.71,
      lon: -9.14,
      country: 'PT',
      region: 'Lisboa',
      address: 'Av. Almirante Reis 120',
      hours: 'Seg-Sáb 9h-19h',
      speciality: ['vivos', 'mar'],
    ),
    const BaitShop(
      id: 'local-porto-loisa',
      name: 'Loisa Pesca Porto',
      lat: 41.15,
      lon: -8.62,
      country: 'PT',
      region: 'Porto',
      hours: 'Seg-Sáb 9h-19h',
      speciality: ['vivos', 'rio'],
    ),
    const BaitShop(
      id: 'local-madrid-todo',
      name: 'Todo Pesca Madrid',
      lat: 40.42,
      lon: -3.70,
      country: 'ES',
      region: 'Madrid',
      hours: 'Lun-Sáb 10h-20h',
      speciality: ['vivos', 'rio'],
    ),
    const BaitShop(
      id: 'local-bcn-equipo',
      name: 'Equipo Pesca Barcelona',
      lat: 41.39,
      lon: 2.15,
      country: 'ES',
      region: 'Barcelona',
      hours: 'Lun-Sáb 10h-20h',
      speciality: ['mar', 'artificial'],
    ),
  ];

  List<BaitShop> _filterNearby(
    List<BaitShop> shops, {
    required double lat,
    required double lon,
    required double radiusKm,
  }) {
    final out = shops
        .where((s) => _distanceKm(lat, lon, s.lat, s.lon) <= radiusKm)
        .toList()
      ..sort(
        (a, b) => _distanceKm(lat, lon, a.lat, a.lon)
            .compareTo(_distanceKm(lat, lon, b.lat, b.lon)),
      );
    return out;
  }

  Future<List<BaitShop>> fetchNearby({
    required double lat,
    required double lon,
    double radiusKm = 150,
  }) async {
    if (!canUseSupabase) {
      return _filterNearby(
        _fallbackShops,
        lat: lat,
        lon: lon,
        radiusKm: radiusKm,
      );
    }

    final client = supabaseClientOrNull;
    if (client == null) {
      return _filterNearby(
        _fallbackShops,
        lat: lat,
        lon: lon,
        radiusKm: radiusKm,
      );
    }

    try {
      final rows = await client.from(_table).select().limit(300);

      final shops = (rows as List)
          .cast<Map<String, dynamic>>()
          .map(BaitShop.fromJson)
          .toList();

      final nearby = _filterNearby(
        shops,
        lat: lat,
        lon: lon,
        radiusKm: radiusKm,
      );

      if (nearby.isNotEmpty) return nearby;

      return _filterNearby(
        _fallbackShops,
        lat: lat,
        lon: lon,
        radiusKm: radiusKm,
      );
    } catch (_) {
      return _filterNearby(
        _fallbackShops,
        lat: lat,
        lon: lon,
        radiusKm: radiusKm,
      );
    }
  }
}
