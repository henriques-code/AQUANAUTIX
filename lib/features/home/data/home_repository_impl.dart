import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/tides/moon_phase.dart';
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
      weather: WeatherData(
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
        solunarScore: (moonFishingFactor(now) * 100).round(),
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
          imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
          quality: SpotQuality.excelente,
        ),
        FeaturedSpot(
          id: '2',
          name: 'Peniche',
          imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400',
          quality: SpotQuality.muitoBom,
        ),
        FeaturedSpot(
          id: '3',
          name: 'Sesimbra',
          imageUrl: 'https://picsum.photos/seed/aqxses/400/260',
          quality: SpotQuality.bom,
        ),
      ],
      communityActivities: const [],
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
