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

  /// Score compacto para UI do carrossel (mockup 20–40).
  int get displayScore => (oracleScore / 3).round().clamp(20, 40);
}
