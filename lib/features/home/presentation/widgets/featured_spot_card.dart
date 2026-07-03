import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/featured_spot.dart';
import '../spot_quality_colors.dart';

/// Card vertical no carrossel «Spots em Destaque» (mockup).
class FeaturedSpotCard extends StatelessWidget {
  const FeaturedSpotCard({
    super.key,
    required this.spot,
    required this.es,
    this.onTap,
    this.width = 148,
  });

  final FeaturedSpot spot;
  final bool es;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final qc = qualityColor(spot.quality);
    final label = qualityLabel(spot.quality, es).toUpperCase();

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 210,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _spotPhoto(spot.imageUrl),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.82),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '${spot.scorePercent}%',
                        style: AppTextStyles.ibmSans(11, fw: FontWeight.w700, color: AppColors.accent),
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
                          style: AppTextStyles.ibmSans(14, fw: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          spot.species.join(' · '),
                          style: AppTextStyles.ibmSans(9, color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.near_me_outlined, size: 11, color: AppColors.textSecondary),
                            Text(
                              ' ${spot.distanceKm.round()} km  ',
                              style: AppTextStyles.ibmSans(9, color: AppColors.textSecondary),
                            ),
                            Icon(Icons.waves_outlined, size: 11, color: AppColors.textSecondary),
                            Text(
                              ' ${spot.waveHeightM.toStringAsFixed(1)} m',
                              style: AppTextStyles.ibmSans(9, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            color: qc.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: qc.withValues(alpha: 0.65)),
                          ),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.ibmSans(10, fw: FontWeight.w700, color: qc, ls: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _spotPhoto(String source) {
    final fallback = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.nav],
        ),
      ),
    );
    if (source.startsWith('assets/')) {
      return Image.asset(source, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
    }
    return Image.network(source, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
  }
}
