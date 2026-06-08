import 'community_post.dart';

/// Feed demo Ghost Mode — offline ou Supabase vazio (mesmos dados do Logbook).
class CommunityDemoPosts {
  CommunityDemoPosts._();

  static List<CommunityPost> posts() => [
        CommunityPost(
          id: 'mock-0',
          userId: 'mock-u0',
          username: 'Nuno_Sesimbra',
          tier: 'PRO',
          avatarUrl: 'https://i.pravatar.cc/80?img=11',
          zoneLabel: '👻 Zona Sesimbra',
          photoUrl:
              'https://images.unsplash.com/photo-1544979590-04bcee11af7d?w=600&q=75&auto=format',
          species: 'ROBALO',
          weightKg: 2.8,
          caption: 'Manhã incrível! Score 82 e a maré a subir.',
          oracleScore: 82,
          country: 'PT',
          createdAt: DateTime.now().subtract(const Duration(minutes: 23)),
          likesCount: 47,
        ),
        CommunityPost(
          id: 'mock-2',
          userId: 'mock-u2',
          username: 'RuiSurf_PT',
          tier: 'PRO',
          avatarUrl: 'https://i.pravatar.cc/80?img=22',
          zoneLabel: '👻 Zona Comporta',
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
          zoneLabel: '👻 Zona Setúbal',
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
