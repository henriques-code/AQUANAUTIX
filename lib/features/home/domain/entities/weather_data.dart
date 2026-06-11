class WeatherData {
  const WeatherData({
    required this.location,
    required this.temperature,
    required this.condition,
    required this.conditionIcon,
    required this.windSpeed,
    required this.waveHeight,
    required this.tideHeight,
    required this.tideRising,
    this.hasTide = true,
    required this.moonPhase,
    required this.moonIcon,
    this.solunarScore = 0,
    this.windDir,
    this.pressure,
  });

  final String location;
  final double temperature;
  final String condition;
  final String conditionIcon;
  final double windSpeed;
  final double waveHeight;
  final double tideHeight;
  final bool tideRising;
  /// False quando o bundle não traz [tideHeight] (Open‑Meteo marine).
  final bool hasTide;
  final String moonPhase;
  final String moonIcon;
  final int solunarScore;
  final String? windDir;
  final int? pressure;
}
