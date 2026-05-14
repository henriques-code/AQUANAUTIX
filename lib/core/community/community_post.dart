class CommunityPost {
  final String id;
  final String userId;
  final String username;
  final String tier;
  final String? avatarUrl;
  final String zoneLabel;
  final String photoUrl;
  final String species;
  final double? weightKg;
  final String? technique;
  final String? caption;
  final int oracleScore;
  final bool isLegal;
  final String country;
  final DateTime createdAt;
  final int likesCount;
  final bool likedByMe;
  final bool locked;

  const CommunityPost({
    required this.id,
    required this.userId,
    required this.username,
    required this.tier,
    this.avatarUrl,
    required this.zoneLabel,
    required this.photoUrl,
    required this.species,
    this.weightKg,
    this.technique,
    this.caption,
    this.oracleScore = 0,
    this.isLegal = true,
    this.country = 'PT',
    required this.createdAt,
    this.likesCount = 0,
    this.likedByMe = false,
    this.locked = false,
  });

  factory CommunityPost.fromJson(
    Map<String, dynamic> j, {
    String? currentUserId,
  }) {
    final profile =
        (j['user_profiles'] as Map<String, dynamic>?) ?? {};
    final reactions =
        ((j['community_reactions'] as List?) ?? [])
            .cast<Map<String, dynamic>>();
    return CommunityPost(
      id: j['id'] as String,
      userId: j['user_id'] as String,
      username: (profile['username'] as String?) ?? 'Anónimo',
      tier: (profile['tier'] as String?) ?? 'FREE',
      avatarUrl: profile['avatar_url'] as String?,
      zoneLabel: j['zone_label'] as String,
      photoUrl: j['photo_url'] as String,
      species: j['species'] as String,
      weightKg: (j['weight_kg'] as num?)?.toDouble(),
      technique: j['technique'] as String?,
      caption: j['caption'] as String?,
      oracleScore: (j['oracle_score'] as int?) ?? 0,
      isLegal: (j['is_legal'] as bool?) ?? true,
      country: (j['country'] as String?) ?? 'PT',
      createdAt: DateTime.parse(j['created_at'] as String),
      likesCount: reactions.length,
      likedByMe: currentUserId != null &&
          reactions.any((r) => r['user_id'] == currentUserId),
    );
  }

  CommunityPost copyWith({int? likesCount, bool? likedByMe}) =>
      CommunityPost(
        id: id, userId: userId, username: username, tier: tier,
        avatarUrl: avatarUrl, zoneLabel: zoneLabel, photoUrl: photoUrl,
        species: species, weightKg: weightKg, technique: technique,
        caption: caption, oracleScore: oracleScore, isLegal: isLegal,
        country: country, createdAt: createdAt, locked: locked,
        likesCount: likesCount ?? this.likesCount,
        likedByMe: likedByMe ?? this.likedByMe,
      );
}
