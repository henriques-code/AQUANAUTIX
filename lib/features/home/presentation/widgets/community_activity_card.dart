import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/aqua_card.dart';
import '../../domain/entities/community_activity.dart';

class CommunityActivityCard extends StatelessWidget {
  const CommunityActivityCard({
    super.key,
    required this.activity,
    this.onUserTap,
  });

  final CommunityActivity activity;
  final VoidCallback? onUserTap;

  static const _avatarSize = 28.0;
  static const _catchSize = 40.0;

  @override
  Widget build(BuildContext context) {
    final card = AquaCard(
      borderRadius: 12,
      borderAlpha: 0.2,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(child: _avatar(activity.avatarUrl)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.username,
                  style: AppTextStyles.ibmSans(12, fw: FontWeight.w700),
                ),
                const SizedBox(height: 1),
                Text(
                  activity.activityText,
                  style: AppTextStyles.ibmSans(11, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (activity.catchImageUrl != null && activity.catchImageUrl!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: _catchPhoto(activity.catchImageUrl!),
                ),
                const SizedBox(height: 3),
                Text(
                  _relative(activity.timestamp),
                  style: AppTextStyles.ibmSans(10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (onUserTap == null) return card;

    // Material + InkWell + GestureDetector — fiável no MIUI (padrão FeaturedSpotCard).
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onUserTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      ),
    );
  }

  Widget _avatar(String source) {
    final fallback = Container(
      width: _avatarSize,
      height: _avatarSize,
      color: AppColors.nav,
      child: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary, size: 16),
    );
    if (source.startsWith('assets/')) {
      return Image.asset(source, width: _avatarSize, height: _avatarSize, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
    }
    return Image.network(
      source,
      width: _avatarSize,
      height: _avatarSize,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  Widget _catchPhoto(String source) {
    final fallback = Container(
      width: _catchSize,
      height: _catchSize,
      color: AppColors.nav,
      child: Icon(Icons.image_not_supported_outlined, color: AppColors.inactive, size: 16),
    );
    if (source.startsWith('assets/')) {
      return Image.asset(source, width: _catchSize, height: _catchSize, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
    }
    return Image.network(
      source,
      width: _catchSize,
      height: _catchSize,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  static String _relative(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes.clamp(1, 59)}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}
