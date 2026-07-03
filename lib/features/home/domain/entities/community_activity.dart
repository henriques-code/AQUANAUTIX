class CommunityActivity {
  const CommunityActivity({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.activityText,
    this.catchImageUrl,
    required this.timestamp,
    this.species,
    this.weightKg,
    this.lengthCm,
    this.location,
    this.likes = 0,
    this.verified = false,
  });

  final String userId;
  final String username;
  final String avatarUrl;
  final String activityText;
  final String? catchImageUrl;
  final DateTime timestamp;
  final String? species;
  final double? weightKg;
  final double? lengthCm;
  final String? location;
  final int likes;
  final bool verified;

  String get displayName {
    final parts = username.replaceAll('_', ' ').split(' ');
    if (parts.isEmpty) return username;
    if (parts.length == 1) {
      final p = parts.first;
      return '${p[0].toUpperCase()}${p.length > 1 ? p.substring(1) : ''}.';
    }
    final first = parts.first;
    final last = parts.last;
    return '${first[0].toUpperCase()}${first.length > 1 ? first.substring(1) : ''} '
        '${last[0].toUpperCase()}.';
  }

  String get catchLine {
    if (species != null && weightKg != null && lengthCm != null) {
      final w = weightKg!.toStringAsFixed(1);
      final l = lengthCm!.round();
      return '🐟 $species $w kg • $l cm';
    }
    return activityText;
  }

  String get locationLine {
    final loc = location ?? _locationFromText(activityText);
    return '$loc • ${_relativePt(timestamp)}';
  }

  static String _locationFromText(String text) {
    final m = RegExp(r'(?:em|·|en)\s+([A-Za-zÀ-ú]+)', caseSensitive: false).firstMatch(text);
    return m?.group(1) ?? 'Zona';
  }

  static String _relativePt(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return 'há ${d.inMinutes.clamp(1, 59)}m';
    if (d.inHours < 24) return 'há ${d.inHours}h';
    return 'há ${d.inDays}d';
  }
}
