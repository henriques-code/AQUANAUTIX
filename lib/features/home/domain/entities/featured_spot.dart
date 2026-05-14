enum SpotQuality { excelente, muitoBom, bom, razoavel, mau }

class FeaturedSpot {
  const FeaturedSpot({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.quality,
  });

  final String id;
  final String name;
  final String imageUrl;
  final SpotQuality quality;
}
