import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/vision/vision_share_payload.dart';
import '../widgets/vision_mockup_ui.dart';

/// Card estático para preview + export PNG (partilha Vision P11).
class VisionShareCard extends StatelessWidget {
  const VisionShareCard({
    super.key,
    required this.payload,
    this.width = 360,
  });

  final VisionSharePayload payload;
  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.25;
    final photoH = height * 0.52;

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: photoH,
                child: _SharePhoto(payload: payload),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(payload.speciesEmoji,
                              style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  payload.speciesName.toUpperCase(),
                                  style: GoogleFonts.orbitron(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Zona · ${payload.zoneLabel}',
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (payload.captureDateLabel != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    payload.captureDateLabel!,
                                    style: GoogleFonts.shareTechMono(
                                      fontSize: 9,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          _chip('IA ${payload.confidence}%', AppColors.accent),
                        ],
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (payload.weightLabel != null)
                            _chip(payload.weightLabel!, AppColors.amber),
                          if (payload.lengthLabel != null)
                            _chip(payload.lengthLabel!, AppColors.green),
                          if (payload.complianceLabel != null)
                            _chip(
                              payload.complianceLabel!,
                              payload.complianceLabel!.contains('LEGAL')
                                  ? AppColors.green
                                  : AppColors.amber,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.visibility_outlined,
                              size: 12,
                              color: AppColors.accent.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Text(
                            'VISION SCANNER',
                            style: GoogleFonts.shareTechMono(
                              fontSize: 8,
                              color: AppColors.accent.withValues(alpha: 0.7),
                              letterSpacing: 1,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'AQUANAUTIX',
                            style: GoogleFonts.orbitron(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent.withValues(alpha: 0.55),
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Text(
          label,
          style: GoogleFonts.shareTechMono(
            fontSize: 9,
            color: color,
            letterSpacing: 0.4,
          ),
        ),
      );
}

class _SharePhoto extends StatelessWidget {
  const _SharePhoto({required this.payload});

  final VisionSharePayload payload;

  @override
  Widget build(BuildContext context) {
    if (payload.photoBytes != null) {
      return Image.memory(payload.photoBytes!, fit: BoxFit.cover);
    }
    return Image.asset(kVisionMockupHeroAsset, fit: BoxFit.cover);
  }
}
