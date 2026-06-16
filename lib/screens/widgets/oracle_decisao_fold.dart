import 'package:flutter/material.dart';

import '../../core/community/community_post.dart';
import 'oracle_community_photo_row.dart';
import 'oracle_conversion_pack.dart';
import 'oracle_hero_decision.dart';
import 'oracle_pro_spot_teaser.dart';

/// Fold do Oráculo — ordem mockup + ganchos conversão PRO.
class OracleDecisaoFold extends StatelessWidget {
  const OracleDecisaoFold({
    super.key,
    required this.hero,
    required this.decisionText,
    required this.decisionLoading,
    required this.proStickySummary,
    required this.onProUnlock,
    required this.speciesCard,
    required this.ctas,
    required this.communityPosts,
    required this.onViewCommunity,
    required this.onProCommunityHook,
    required this.proDistanceLabel,
    required this.proScoreLine,
    required this.proUnlockLabel,
    required this.proSpeciesLabel,
    this.communityTitle = 'GHOST ATIVIDADE NA ZONA',
    this.communityProHint,
    this.es = false,
  });

  final OracleHeroScoreCard hero;
  final String decisionText;
  final bool decisionLoading;
  final String proStickySummary;
  final VoidCallback onProUnlock;
  final OracleSpeciesTargetCard speciesCard;
  final OracleMockupCtas ctas;
  final List<CommunityPost> communityPosts;
  final VoidCallback onViewCommunity;
  final VoidCallback onProCommunityHook;
  final String proDistanceLabel;
  final String proScoreLine;
  final String proUnlockLabel;
  final String proSpeciesLabel;
  final String communityTitle;
  final String? communityProHint;
  final bool es;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        hero,
        OracleDecisionLine(text: decisionText, loading: decisionLoading),
        OracleProStickyStrip(
          summary: proStickySummary,
          onTap: onProUnlock,
        ),
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
                proHint: communityProHint,
                onProHintTap: onProCommunityHook,
                onViewCommunity: onViewCommunity,
              ),
              const SizedBox(height: 12),
              OracleProSpotTeaser(
                distanceLabel: proDistanceLabel,
                scoreLine: proScoreLine,
                unlockLabel: proUnlockLabel,
                speciesLabel: proSpeciesLabel,
                onUnlock: onProUnlock,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
