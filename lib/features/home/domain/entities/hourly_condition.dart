class HourlyCondition {
  const HourlyCondition({
    required this.hour,
    required this.oracleScore,
    this.isBestHour = false,
  });

  final String hour;
  final int oracleScore;

  /// Hora com melhor score na janela visível.
  final bool isBestHour;
}
