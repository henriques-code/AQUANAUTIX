import 'package:flutter/material.dart';

import '../../core/community/community_post.dart';
import 'oracle_community_photo_row.dart';
import 'oracle_hero_decision.dart';
import 'oracle_pro_spot_teaser.dart';

/// Fold do Oráculo — ordem exacta do mockup `oraculo-decisao-mockup-full.png`.
class OracleDecisaoFold extends StatelessWidget {
  const OracleDecisaoFold({
    super.key,
    required this.hero,
    required this.speciesCard,
    required this.ctas,
    required this.communityPosts,
    required this.onViewCommunity,
    required this.proDistanceLabel,
    required this.proScoreLine,
    required this.proUnlockLabel,
    this.communityTitle = 'GHOST ATIVIDADE NA ZONA',
    this.es = false,
  });

  final OracleHeroScoreCard hero;
  final OracleSpeciesTargetCard speciesCard;
  final OracleMockupCtas ctas;
  final List<CommunityPost> communityPosts;
  final VoidCallback onViewCommunity;
  final String proDistanceLabel;
  final String proScoreLine;
  final String proUnlockLabel;
  final String communityTitle;
  final bool es;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        hero,
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              speciesCard,
              const SizedBox(height: 14),
              ctas,
              const SizedBox(height: 18),
              OracleCommunityPhotoRow(
                posts: communityPosts,
                es: es,
                title: communityTitle,
                onViewCommunity: onViewCommunity,
              ),
              const SizedBox(height: 12),
              OracleProSpotTeaser(
                distanceLabel: proDistanceLabel,
                scoreLine: proScoreLine,
                unlockLabel: proUnlockLabel,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
