import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/community_activity.dart';
import '../domain/entities/featured_spot.dart';
import '../domain/entities/hourly_condition.dart';
import '../domain/entities/weather_data.dart';
import '../domain/repositories/home_repository.dart';

/// Dados mock — fase inicial.
///
/// TODO: integrar API de meteorologia (Open‑Meteo / marine).
/// TODO: integrar Supabase realtime para feed comunitário.
class HomeRepositoryImpl implements HomeRepository {
  @override
  Future<HomeDashboardData> loadDashboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 380));
    final now = DateTime.now();
    return HomeDashboardData(
      userDisplayName: _getUserDisplayName(),
      weather: const WeatherData(
        location: 'Cascais, Portugal',
        temperature: 18,
        condition: 'Céu limpo',
        conditionIcon: '☀️',
        windSpeed: 14,
        waveHeight: 0.6,
        tideHeight: 1.2,
        tideRising: true,
        moonPhase: 'Crescente',
        moonIcon: '🌙',
      ),
      hourlyConditions: const [
        HourlyCondition(hour: '07:00', weatherIcon: '☀️', temperature: 18),
        HourlyCondition(hour: '10:00', weatherIcon: '⛅', temperature: 20),
        HourlyCondition(hour: '13:00', weatherIcon: '☀️', temperature: 21),
        HourlyCondition(hour: '16:00', weatherIcon: '⛅', temperature: 19),
        HourlyCondition(hour: '19:00', weatherIcon: '🌙', temperature: 17),
      ],
      featuredSpots: const [
        FeaturedSpot(
          id: '1',
          name: 'Cabo da Roca',
          imageUrl: 'https://picsum.photos/seed/aqxroca/400/260',
          quality: SpotQuality.excelente,
        ),
        FeaturedSpot(
          id: '2',
          name: 'Peniche',
          imageUrl: 'https://picsum.photos/seed/aqxpen/400/260',
          quality: SpotQuality.muitoBom,
        ),
        FeaturedSpot(
          id: '3',
          name: 'Sesimbra',
          imageUrl: 'https://picsum.photos/seed/aqxses/400/260',
          quality: SpotQuality.bom,
        ),
      ],
      communityActivities: [
        CommunityActivity(
          userId: 'u1',
          username: 'BrunoPescas',
          avatarUrl: 'https://picsum.photos/seed/aqxav1/96/96',
          activityText: 'apanhou uma Dourada',
          catchImageUrl: 'https://picsum.photos/seed/aqxcatch1/120/96',
          timestamp: now.subtract(const Duration(hours: 2)),
        ),
        CommunityActivity(
          userId: 'u2',
          username: 'MariaCosta',
          avatarUrl: 'https://picsum.photos/seed/aqxav2/96/96',
          activityText: 'registou um Robalo',
          catchImageUrl: 'https://picsum.photos/seed/aqxcatch2/120/96',
          timestamp: now.subtract(const Duration(hours: 6)),
        ),
      ],
    );
  }

  String _getUserDisplayName() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 'Pescador';

    final fullName = user.userMetadata?['full_name'] as String?;
    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName.trim().split(RegExp(r'\s+')).first;
    }

    final name = user.userMetadata?['name'] as String?;
    if (name != null && name.trim().isNotEmpty) {
      return name.trim().split(RegExp(r'\s+')).first;
    }

    final displayName = user.userMetadata?['display_name'] as String?;
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim().split(RegExp(r'\s+')).first;
    }

    final email = user.email ?? '';
    if (email.isNotEmpty) return email.split('@').first;

    return 'Pescador';
  }
}
