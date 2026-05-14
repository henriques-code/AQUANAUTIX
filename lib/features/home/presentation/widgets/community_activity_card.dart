import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/aqua_card.dart';
import '../../domain/entities/community_activity.dart';

class CommunityActivityCard extends StatelessWidget {
  const CommunityActivityCard({super.key, required this.activity});

  final CommunityActivity activity;

  @override
  Widget build(BuildContext context) {
    return AquaCard(
      borderRadius: 16,
      borderAlpha: 0.2,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          ClipOval(
            child: activity.avatarUrl.isEmpty
                ? Container(
                    width: 40,
                    height: 40,
                    color: AppColors.nav,
                    child: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary, size: 22),
                  )
                : Image.network(
                    activity.avatarUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 40,
                      height: 40,
                      color: AppColors.nav,
                      child: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary, size: 22),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.username, style: AppTextStyles.ibmSans(14, fw: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(activity.activityText, style: AppTextStyles.ibmSans(13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (activity.catchImageUrl != null && activity.catchImageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    activity.catchImageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      color: AppColors.nav,
                      child: Icon(Icons.image_not_supported_outlined, color: AppColors.inactive, size: 22),
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Text(_relative(activity.timestamp), style: AppTextStyles.ibmSans(11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  static String _relative(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes.clamp(1, 59)}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}
