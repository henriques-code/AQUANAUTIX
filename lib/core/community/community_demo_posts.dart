import 'community_post.dart';

/// Feed demo Ghost Mode — offline ou Supabase vazio (mesmos dados do Logbook).
class CommunityDemoPosts {
  CommunityDemoPosts._();

  /// Cards GHOST do Oráculo — fotos do mockup (pescador + dourada).
  static List<CommunityPost> oracleGhostRow() => [
        CommunityPost(
          id: 'ghost-robalo',
          userId: 'ghost',
          username: 'Ghost',
          tier: 'PRO',
          zoneLabel: 'Zona Sesimbra',
          photoUrl: 'assets/marketing/catches/oracle_hero_pescador.jpg',
          species: 'ROBALO',
          weightKg: 2.8,
          country: 'PT',
          createdAt: DateTime.now().subtract(const Duration(minutes: 23)),
        ),
        CommunityPost(
          id: 'ghost-dourada',
          userId: 'ghost',
          username: 'Ghost',
          tier: 'PRO',
          zoneLabel: '',
          photoUrl: 'assets/marketing/catches/dourada.jpg',
          species: 'DOURADA',
          weightKg: 2.4,
          country: 'PT',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];

  static List<CommunityPost> posts() => [
        CommunityPost(
          id: 'mock-br',
          userId: 'brunopescas',
          username: 'BrunoPescas',
          tier: 'PRO',
          avatarUrl:
              'https://images.unsplash.com/photo-1568602471122-7832951cc4c5?w=96&q=80',
          zoneLabel: 'Zona Sesimbra',
          photoUrl: 'assets/marketing/catches/dourada.jpg',
          species: 'DOURADA',
          weightKg: 2.4,
          caption: 'Dourada de 2.4 kg ao amanhecer · Sesimbra',
          oracleScore: 79,
          country: 'PT',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          likesCount: 24,
        ),
        CommunityPost(
          id: 'mock-0',
          userId: 'nuno_sesimbra',
          username: 'Nuno_Sesimbra',
          tier: 'PRO',
          avatarUrl: 'https://i.pravatar.cc/80?img=11',
          zoneLabel: 'Zona Sesimbra',
          photoUrl: 'assets/marketing/catches/robalo.jpg',
          species: 'ROBALO',
          weightKg: 2.8,
          caption: 'Manhã incrível! Score 82 e a maré a subir.',
          oracleScore: 82,
          country: 'PT',
          createdAt: DateTime.now().subtract(const Duration(minutes: 23)),
          likesCount: 47,
        ),
        CommunityPost(
          id: 'mock-mp',
          userId: 'miguel_peniche',
          username: 'Miguel_Peniche',
          tier: 'PRO',
          avatarUrl:
              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=96&q=80',
          zoneLabel: 'Zona Peniche',
          photoUrl: 'assets/marketing/catches/sargo.jpg',
          species: 'SARGO',
          weightKg: 1.6,
          caption: 'Sargo de 1.6 kg na costa rochosa · Peniche',
          oracleScore: 72,
          country: 'PT',
          createdAt: DateTime.now().subtract(const Duration(hours: 9)),
          likesCount: 18,
        ),
        CommunityPost(
          id: 'mock-2',
          userId: 'mock-u2',
          username: 'RuiSurf_PT',
          tier: 'PRO',
          avatarUrl: 'https://i.pravatar.cc/80?img=22',
          zoneLabel: 'Zona Comporta',
          photoUrl:
              'https://images.unsplash.com/photo-1499728603263-13726abce5fd?w=600&q=75&auto=format',
          species: 'SARGO',
          weightKg: 1.6,
          oracleScore: 74,
          country: 'PT',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          likesCount: 31,
        ),
        CommunityPost(
          id: 'mock-3',
          userId: 'mock-u3',
          username: 'Carlos_V',
          tier: 'PRO',
          avatarUrl: 'https://i.pravatar.cc/80?img=44',
          zoneLabel: 'Zona Setúbal',
          photoUrl:
              'https://images.unsplash.com/photo-1518568814500-bf0f8d125f46?w=600&q=75&auto=format',
          species: 'DOURADA',
          weightKg: 2.3,
          oracleScore: 68,
          country: 'PT',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          likesCount: 19,
        ),
      ];
}
