import 'package:flutter/material.dart';

import '../_shared.dart';
import '../../core/community/community_post.dart';
import 'aqx_pressable.dart';

/// Bloco Comunidade Ghost no Oráculo — feed compacto + CTAs.
class OracleCommunityStrip extends StatelessWidget {
  const OracleCommunityStrip({
    super.key,
    required this.posts,
    required this.onViewCommunity,
    required this.onShare,
    this.loading = false,
    this.title = 'ACTIVIDADE NA ZONA',
    this.subtitle = 'Descobre o que a comunidade está a capturar',
    this.viewLabel = 'VER COMUNIDADE',
    this.shareLabel = 'PARTILHAR 👻',
    this.es = false,
  });

  final List<CommunityPost> posts;
  final VoidCallback onViewCommunity;
  final VoidCallback onShare;
  final bool loading;
  final String title;
  final String subtitle;
  final String viewLabel;
  final String shareLabel;
  final bool es;

  static String timeAgo(DateTime dt, {bool es = false}) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) {
      return es ? 'hace ${d.inMinutes} min' : 'há ${d.inMinutes} min';
    }
    if (d.inHours < 24) return es ? 'hace ${d.inHours}h' : 'há ${d.inHours}h';
    return es ? 'hace ${d.inDays}d' : 'há ${d.inDays}d';
  }

  static String _speciesLabel(String code) {
    switch (code.toUpperCase()) {
      case 'ROBALO':
        return 'Robalo';
      case 'SARGO':
        return 'Sargo';
      case 'DOURADA':
        return 'Dourada';
      case 'BARBO':
        return 'Barbo';
      case 'ACHIGA':
        return 'Achigã';
      default:
        if (code.isEmpty) return code;
        return code[0] + code.substring(1).toLowerCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = posts.take(2).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kCyan.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('👻', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: mono(11, c: kCyan, ls: 0.8)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: ibm(12, c: kHint)),
          const SizedBox(height: 10),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: kCyan,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else if (preview.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Sê o primeiro a partilhar na tua zona — Ghost Mode activo.',
                style: ibm(12, c: Colors.white54),
              ),
            )
          else
            for (final p in preview)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: kGreen.withValues(alpha: 0.8)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_speciesLabel(p.species)} · ${p.zoneLabel} · '
                        '${timeAgo(p.createdAt, es: es)}',
                        style: ibm(12, c: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AqxGlassButton(
                  label: viewLabel,
                  onTap: onViewCommunity,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AqxNeonCompactButton(
                  label: shareLabel,
                  onTap: onShare,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
