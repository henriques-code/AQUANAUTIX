enum SpotQuality { excelente, muitoBom, bom, razoavel, mau }

class FeaturedSpot {
  const FeaturedSpot({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.quality,
    required this.lat,
    required this.lon,
    this.species = const [],
    this.scorePercent = 70,
    this.distanceKm = 0,
    this.waveHeightM = 0.8,
  });

  final String id;
  final String name;
  final String imageUrl;
  final SpotQuality quality;
  final double lat;
  final double lon;
  final List<String> species;
  final int scorePercent;
  final double distanceKm;
  final double waveHeightM;
}
