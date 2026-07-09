class HomeDayForecastChip {
  const HomeDayForecastChip({
    required this.dayLabel,
    required this.score,
    this.isHighlighted = false,
  });

  final String dayLabel;
  final int score;
  final bool isHighlighted;
}

class HomeRecommendation {
  const HomeRecommendation({
    required this.headline,
    required this.detail,
    required this.footer,
  });

  final String headline;
  final String detail;
  final String footer;
}

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
    this.waterTempC,
    this.highTideTime,
    this.highTideHeightM,
    this.pressureTrendDown,
    this.sunset,
    this.fiveDayForecast = const [],
    this.recommendation,
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
  final double? waterTempC;
  final DateTime? highTideTime;
  final double? highTideHeightM;
  final bool? pressureTrendDown;
  final DateTime? sunset;
  final List<HomeDayForecastChip> fiveDayForecast;
  final HomeRecommendation? recommendation;
}
