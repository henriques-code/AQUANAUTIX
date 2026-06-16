import 'package:flutter/material.dart';

import '../_shared.dart';
import '../../core/community/community_post.dart';
import 'oracle_community_strip.dart';

/// GHOST ATIVIDADE NA ZONA — 2 cards lado a lado (mockup).
class OracleCommunityPhotoRow extends StatelessWidget {
  const OracleCommunityPhotoRow({
    super.key,
    required this.posts,
    required this.onViewCommunity,
    this.es = false,
    this.title = 'GHOST ATIVIDADE NA ZONA',
    this.proHint,
    this.onProHintTap,
  });

  final List<CommunityPost> posts;
  final VoidCallback onViewCommunity;
  final bool es;
  final String title;
  final String? proHint;
  final VoidCallback? onProHintTap;

  String _speciesLabel(String code) {
    switch (code.toUpperCase()) {
      case 'ROBALO':
        return 'Robalo';
      case 'SARGO':
        return 'Sargo';
      case 'DOURADA':
        return 'Dourada';
      default:
        if (code.isEmpty) return code;
        return code[0] + code.substring(1).toLowerCase();
    }
  }

  String _zoneShort(String zoneLabel) {
    return zoneLabel
        .replaceFirst(RegExp(r'^Zona\s+', caseSensitive: false), '')
        .trim();
  }

  Widget _photo(String source) {
    if (source.startsWith('assets/')) {
      return Image.asset(source, fit: BoxFit.cover);
    }
    return Image.network(
      source,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: kBg,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined,
            color: kHint, size: 22),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = posts.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: mono(10, c: kCyan, ls: 0.9)),
        if (proHint != null && onProHintTap != null) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onProHintTap,
            child: Text(
              proHint!,
              style: ibm(11, c: kAmber, fw: FontWeight.w600),
            ),
          ),
        ],
        const SizedBox(height: 10),
        if (preview.isEmpty)
          Text(
            es
                ? 'Sé el primero en compartir en tu zona.'
                : 'Sê o primeiro a partilhar na tua zona.',
            style: ibm(12, c: Colors.white54),
          )
        else
          Row(
            children: [
              for (var i = 0; i < preview.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _GhostCard(
                    speciesLabel: _speciesLabel(preview[i].species),
                    zone: _zoneShort(preview[i].zoneLabel),
                    ago: OracleCommunityStrip.timeAgo(
                      preview[i].createdAt,
                      es: es,
                    ),
                    weightKg: preview[i].weightKg,
                    photo: _photo(preview[i].photoUrl),
                    onTap: onViewCommunity,
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

class _GhostCard extends StatelessWidget {
  const _GhostCard({
    required this.speciesLabel,
    required this.zone,
    required this.ago,
    required this.weightKg,
    required this.photo,
    required this.onTap,
  });

  final String speciesLabel;
  final String zone;
  final String ago;
  final double? weightKg;
  final Widget photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weight =
        weightKg != null ? '${weightKg!.toStringAsFixed(1)}kg' : '—';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kCyan.withValues(alpha: 0.12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(width: 54, height: 54, child: photo),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    speciesLabel,
                    style: ibm(12, c: kCyan, fw: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(weight, style: ibm(11, c: kHint)),
                  if (zone.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      zone,
                      style: ibm(10, c: kHint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 11, color: kHint.withValues(alpha: 0.85)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          ago,
                          style: ibm(10, c: kHint),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
