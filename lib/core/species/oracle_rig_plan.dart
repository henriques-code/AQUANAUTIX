/// Recomendação isco + cana + técnica (Oráculo P3).
class OracleRigPlan {
  const OracleRigPlan({
    required this.bait,
    required this.rod,
    required this.technique,
    this.distance = '',
    this.fromCatalog = false,
  });

  final String bait;
  final String rod;
  final String technique;
  final String distance;
  final bool fromCatalog;
}
