import '../../features/home/domain/entities/community_activity.dart';
import 'community_post.dart';

/// Perfil público Ghost — sem coordenadas exactas (P9).
class CommunityPublicProfile {
  const CommunityPublicProfile({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.tier,
    required this.zoneLabel,
    required this.recentCatches,
  });

  final String userId;
  final String username;
  final String avatarUrl;
  final String tier;
  final String zoneLabel;
  final List<CommunityProfileCatch> recentCatches;

  static CommunityPublicProfile fromActivity(CommunityActivity activity) {
    return find(userId: activity.userId, username: activity.username) ??
        CommunityPublicProfile(
          userId: activity.userId,
          username: activity.username,
          avatarUrl: activity.avatarUrl,
          tier: 'PRO',
          zoneLabel: _zoneFromActivityText(activity.activityText),
          recentCatches: [
            if (activity.catchImageUrl != null)
              CommunityProfileCatch(
                species: _speciesFromActivityText(activity.activityText),
                weightLabel: _weightFromActivityText(activity.activityText),
                imageUrl: activity.catchImageUrl,
                when: 'Recente',
              ),
          ],
        );
  }

  static CommunityPublicProfile fromPost(CommunityPost post) {
    return find(userId: post.userId, username: post.username) ??
        CommunityPublicProfile(
          userId: post.userId,
          username: post.username,
          avatarUrl: post.avatarUrl ??
              'https://i.pravatar.cc/80?u=${post.userId}',
          tier: post.tier,
          zoneLabel: post.zoneLabel.replaceAll('📍 ', '').replaceAll('🔒 ', ''),
          recentCatches: [
            CommunityProfileCatch(
              species: post.species,
              weightLabel: post.weightKg != null
                  ? '${post.weightKg!.toStringAsFixed(1)} kg'
                  : '—',
              imageUrl: post.photoUrl,
              when: 'Recente',
            ),
          ],
        );
  }

  static CommunityPublicProfile? find({String? userId, String? username}) {
    for (final p in _catalog) {
      if (userId != null && p.userId == userId) return p;
      if (username != null &&
          p.username.toLowerCase() == username.toLowerCase()) {
        return p;
      }
    }
    return null;
  }

  static String _zoneFromActivityText(String text) {
    if (text.contains('Sesimbra')) return 'Zona Sesimbra · ~5 km';
    if (text.contains('Peniche')) return 'Zona Peniche · ~5 km';
    if (text.contains('Comporta')) return 'Zona Comporta · ~5 km';
    return 'Zona agregada · ~5 km';
  }

  static String _speciesFromActivityText(String text) {
    if (text.contains('Dourada')) return 'DOURADA';
    if (text.contains('Robalo')) return 'ROBALO';
    if (text.contains('Sargo')) return 'SARGO';
    return 'CAPTURA';
  }

  static String _weightFromActivityText(String text) {
    final m = RegExp(r'(\d+[.,]\d+)\s*kg').firstMatch(text);
    if (m != null) return '${m.group(1)!.replaceAll(',', '.')} kg';
    return '—';
  }

  static const _catalog = [
    CommunityPublicProfile(
      userId: 'brunopescas',
      username: 'BrunoPescas',
      avatarUrl:
          'https://images.unsplash.com/photo-1568602471122-7832951cc4c5?w=96&q=80',
      tier: 'PRO',
      zoneLabel: 'Zona Sesimbra · ~5 km',
      recentCatches: [
        CommunityProfileCatch(
          species: 'DOURADA',
          weightLabel: '2.4 kg',
          imageUrl: 'assets/marketing/catches/dourada.jpg',
          when: 'Há 2 h',
        ),
        CommunityProfileCatch(
          species: 'ROBALO',
          weightLabel: '1.9 kg',
          imageUrl: 'assets/marketing/catches/robalo.jpg',
          when: 'Há 3 d',
        ),
      ],
    ),
    CommunityPublicProfile(
      userId: 'nuno_sesimbra',
      username: 'Nuno_Sesimbra',
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=96&q=80',
      tier: 'PRO',
      zoneLabel: 'Zona Sesimbra · ~5 km',
      recentCatches: [
        CommunityProfileCatch(
          species: 'ROBALO',
          weightLabel: '2.8 kg',
          imageUrl: 'assets/marketing/catches/robalo.jpg',
          when: 'Há 5 h',
        ),
      ],
    ),
    CommunityPublicProfile(
      userId: 'miguel_peniche',
      username: 'Miguel_Peniche',
      avatarUrl:
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=96&q=80',
      tier: 'PRO',
      zoneLabel: 'Zona Peniche · ~5 km',
      recentCatches: [
        CommunityProfileCatch(
          species: 'SARGO',
          weightLabel: '1.6 kg',
          imageUrl: 'assets/marketing/catches/sargo.jpg',
          when: 'Há 9 h',
        ),
      ],
    ),
  ];
}

class CommunityProfileCatch {
  const CommunityProfileCatch({
    required this.species,
    required this.weightLabel,
    this.imageUrl,
    required this.when,
  });

  final String species;
  final String weightLabel;
  final String? imageUrl;
  final String when;
}
