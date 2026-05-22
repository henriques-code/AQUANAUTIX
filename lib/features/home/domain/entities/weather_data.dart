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
  final String moonPhase;
  final String moonIcon;
  final int solunarScore;
  final String? windDir;
  final int? pressure;
}
