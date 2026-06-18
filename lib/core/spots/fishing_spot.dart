// lib/core/spots/fishing_spot.dart

class FishingSpot {
  static const _defaultPhoto =
      'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?w=80&q=70&auto=format';

  final String id;
  final String name;
  final double lat;
  final double lon;
  final String tier;
  final String country;
  final String? region;
  final String? zoneType;
  final List<String> species;
  final List<String> bestSeason;
  final List<String> bestBait;
  final double? depthMin;
  final double? depthMax;
  final String? bottomType;
  final bool carAccess;
  final bool trailAccess;
  final int difficulty;
  final double scoreAvg;
  final List<String> photos;
  final DateTime? createdAt;

  const FishingSpot({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.tier,
    required this.country,
    this.region,
    this.zoneType,
    this.species = const [],
    this.bestSeason = const [],
    this.bestBait = const [],
    this.depthMin,
    this.depthMax,
    this.bottomType,
    this.carAccess = true,
    this.trailAccess = true,
    this.difficulty = 2,
    this.scoreAvg = 70,
    this.photos = const [],
    this.createdAt,
  });

  /// Tier em maiúsculas para UI / SubscriptionGate.
  String get tierLabel => tier.toUpperCase();

  bool get elite => tier == 'elite';

  int get score => scoreAvg.round();

  String get local {
    final r = region?.trim();
    final z = zoneType?.trim().toUpperCase();
    if (r != null && r.isNotEmpty && z != null && z.isNotEmpty) return '$r · $z';
    if (r != null && r.isNotEmpty) return r;
    return country;
  }

  String get photo => photos.isNotEmpty ? photos.first : _defaultPhoto;

  String get primarySpecies =>
      species.isNotEmpty ? species.first.toUpperCase() : 'PEIXE';

  /// Chave de região para contexto (Oráculo / insights).
  String get regionKey {
    final r = region?.trim();
    if (r == null || r.isEmpty) return country;
    return r
        .toUpperCase()
        .replaceAll('Ú', 'U')
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ã', 'A')
        .replaceAll(' ', '');
  }

  factory FishingSpot.fromJson(Map<String, dynamic> j) {
    List<String> strList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return const [];
    }

    return FishingSpot(
      id: j['id'] as String,
      name: j['name'] as String,
      lat: (j['lat'] as num).toDouble(),
      lon: (j['lon'] as num).toDouble(),
      tier: (j['tier'] as String?) ?? 'free',
      country: j['country'] as String,
      region: j['region'] as String?,
      zoneType: j['zone_type'] as String?,
      species: strList(j['species']),
      bestSeason: strList(j['best_season']),
      bestBait: strList(j['best_bait']),
      depthMin: (j['depth_min'] as num?)?.toDouble(),
      depthMax: (j['depth_max'] as num?)?.toDouble(),
      bottomType: j['bottom_type'] as String?,
      carAccess: j['car_access'] as bool? ?? true,
      trailAccess: j['trail_access'] as bool? ?? true,
      difficulty: (j['difficulty'] as num?)?.toInt() ?? 2,
      scoreAvg: (j['score_avg'] as num?)?.toDouble() ?? 70,
      photos: strList(j['photos']),
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'] as String)
          : null,
    );
  }
}
