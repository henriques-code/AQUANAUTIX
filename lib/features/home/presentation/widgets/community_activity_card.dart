import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/community_activity.dart';

/// Linha de captura recente (mockup «Últimas Capturas»).
class CommunityActivityCard extends StatelessWidget {
  const CommunityActivityCard({
    super.key,
    required this.activity,
    this.onUserTap,
  });

  final CommunityActivity activity;
  final VoidCallback? onUserTap;

  static const _avatarSize = 36.0;
  static const _catchW = 72.0;
  static const _catchH = 52.0;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onUserTap,
            child: ClipOval(child: _avatar(activity.avatarUrl)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      activity.displayName,
                      style: AppTextStyles.ibmSans(13, fw: FontWeight.w700),
                    ),
                    if (activity.verified) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.verified_rounded, size: 14, color: AppColors.accent),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  activity.catchLine,
                  style: AppTextStyles.ibmSans(12, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.locationLine,
                  style: AppTextStyles.ibmSans(11, color: AppColors.textSecondary),
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
                  borderRadius: BorderRadius.circular(8),
                  child: _catchPhoto(activity.catchImageUrl!),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_rounded, size: 12, color: AppColors.accent.withValues(alpha: 0.8)),
                    const SizedBox(width: 3),
                    Text(
                      '${activity.likes}',
                      style: AppTextStyles.ibmSans(11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (onUserTap == null) return content;
    return InkWell(onTap: onUserTap, child: content);
  }

  Widget _avatar(String source) {
    final fallback = Container(
      width: _avatarSize,
      height: _avatarSize,
      color: AppColors.nav,
      child: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary, size: 18),
    );
    if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        width: _avatarSize,
        height: _avatarSize,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
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
      width: _catchW,
      height: _catchH,
      color: AppColors.nav,
      child: Icon(Icons.image_not_supported_outlined, color: AppColors.inactive, size: 18),
    );
    if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        width: _catchW,
        height: _catchH,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    return Image.network(
      source,
      width: _catchW,
      height: _catchH,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
