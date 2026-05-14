class CommunityActivity {
  const CommunityActivity({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.activityText,
    this.catchImageUrl,
    required this.timestamp,
  });

  final String userId;
  final String username;
  final String avatarUrl;
  final String activityText;
  final String? catchImageUrl;
  final DateTime timestamp;
}
