class HourlyCondition {
  const HourlyCondition({
    required this.hour,
    required this.oracleScore,
    this.isBestHour = false,
    this.isCurrentHour = false,
    this.isGoldenWindow = false,
  });

  final String hour;
  final int oracleScore;

  /// Hora com melhor score na janela visível.
  final bool isBestHour;

  /// Hora actual (relógio local).
  final bool isCurrentHour;

  /// Dentro da janela de ouro do Oráculo (ex. 07:00→09:30).
  final bool isGoldenWindow;
}
