// lib/core/spots/fishing_spot.dart

class FishingSpot {
  static const _defaultPhoto =
      'assets/marketing/catches/robalo.jpg';

  /// Fotos reais — assets locais (costa) + Wikimedia (rio/mar).
  static const Map<String, String> _speciesPhotos = {
    'robalo': 'assets/marketing/catches/robalo.jpg',
    'dourada': 'assets/marketing/catches/dourada.jpg',
    'sargo': 'assets/marketing/catches/sargo.jpg',
    'corvina':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2f/Argyrosomus_regius_aquarium.jpg/640px-Argyrosomus_regius_aquarium.jpg',
    'achiga':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/df/Micropterus_salmoides.jpg/640px-Micropterus_salmoides.jpg',
    'achigã':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/df/Micropterus_salmoides.jpg/640px-Micropterus_salmoides.jpg',
    'carpa':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f9/Common_carp_Cyprinus_carpio.jpg/640px-Common_carp_Cyprinus_carpio.jpg',
    'barbo':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d8/Luciobarbus_bocagei.jpg/640px-Luciobarbus_bocagei.jpg',
    'truta':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0f/Salmo_trutta_marmorata.jpg/640px-Salmo_trutta_marmorata.jpg',
    'linguado':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/0/01/Solea_solea_Pleschen.jpg/640px-Solea_solea_Pleschen.jpg',
    'enguia':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/Anguilla_anguilla.jpg/640px-Anguilla_anguilla.jpg',
    'lucio':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ec/Esox_lucius_pik.jpg/640px-Esox_lucius_pik.jpg',
    'lúcio':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ec/Esox_lucius_pik.jpg/640px-Esox_lucius_pik.jpg',
  };

  static String _speciesKey(String name) =>
      name.toLowerCase().trim().replaceAll('ú', 'u').replaceAll('í', 'i');

  static String? photoForSpecies(String speciesName) =>
      _speciesPhotos[_speciesKey(speciesName)];

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

  String get photo {
    for (final sp in species) {
      final fromSpecies = photoForSpecies(sp);
      if (fromSpecies != null) return fromSpecies;
    }
    if (photos.isNotEmpty && !photos.first.contains('unsplash')) {
      return photos.first;
    }
    return _defaultPhoto;
  }

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
