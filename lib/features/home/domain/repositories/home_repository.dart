import '../entities/community_activity.dart';
import '../entities/featured_spot.dart';
import '../entities/hourly_condition.dart';
import '../entities/weather_data.dart';

class HomeDashboardData {
  const HomeDashboardData({
    required this.weather,
    required this.hourlyConditions,
    required this.featuredSpots,
    required this.communityActivities,
    required this.userDisplayName,
    this.lastUpdated,
  });

  final WeatherData weather;
  final List<HourlyCondition> hourlyConditions;
  final List<FeaturedSpot> featuredSpots;
  final List<CommunityActivity> communityActivities;
  final String userDisplayName;
  final DateTime? lastUpdated;
}

abstract class HomeRepository {
  Future<HomeDashboardData> loadDashboard({bool forceRefresh = false});
}
