import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/featured_spot.dart';
import '../spot_quality_colors.dart';

class FeaturedSpotCard extends StatelessWidget {
  const FeaturedSpotCard({super.key, required this.spot, required this.es});

  final FeaturedSpot spot;
  final bool es;

  @override
  Widget build(BuildContext context) {
    final qc = qualityColor(spot.quality);
    final nameColor = spot.quality == SpotQuality.muitoBom ? AppColors.accent : AppColors.textPrimary;
    return SizedBox(
      width: 200,
      height: 130,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              spot.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.surface,
                      AppColors.surface.withValues(alpha: 0.6),
                      AppColors.nav,
                    ],
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    spot.name,
                    style: AppTextStyles.ibmSans(15, fw: FontWeight.w700, color: nameColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: qc,
                          boxShadow: [BoxShadow(color: qc.withValues(alpha: 0.7), blurRadius: 6)],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        qualityLabel(spot.quality, es),
                        style: AppTextStyles.ibmSans(11, fw: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
