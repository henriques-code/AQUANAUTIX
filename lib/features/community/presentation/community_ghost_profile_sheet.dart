import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/community/community_public_profile.dart';
import '../../../core/l10n/aqx_l10n.dart';
import '../../../core/state/home_tab_index.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/aqx_ghost_mode_badge.dart';

/// Sheet de perfil público Ghost (sem coordenadas exactas).
Future<void> showCommunityGhostProfileSheet(
  BuildContext context,
  CommunityPublicProfile profile,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _CommunityGhostProfileSheet(profile: profile),
  );
}

class _CommunityGhostProfileSheet extends StatelessWidget {
  const _CommunityGhostProfileSheet({required this.profile});

  final CommunityPublicProfile profile;

  TextStyle _ibm(double sz, {FontWeight fw = FontWeight.w400, Color? c}) =>
      GoogleFonts.ibmPlexSans(
        fontSize: sz,
        fontWeight: fw,
        color: c ?? AppColors.textPrimary,
      );

  TextStyle _mono(double sz, {Color? c}) => GoogleFonts.shareTechMono(
        fontSize: sz,
        color: c ?? AppColors.textSecondary,
        letterSpacing: 0.6,
      );

  @override
  Widget build(BuildContext context) {
    final t = AqxL10n(Localizations.localeOf(context).languageCode);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inactive,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipOval(child: _avatar(profile.avatarUrl, 56)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.username,
                        style: _ibm(16, fw: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _tierChip(profile.tier),
                          const SizedBox(width: 8),
                          const AqxGhostModeBadge(size: 12),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        profile.zoneLabel,
                        style: _mono(10, c: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              t.es
                  ? 'Coordenadas exactas nunca compartidas · Ghost Mode activo'
                  : 'Coordenadas exactas nunca partilhadas · Ghost Mode activo',
              style: _ibm(11, c: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              t.es ? 'Capturas recientes' : 'Capturas recentes',
              style: _ibm(13, fw: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...profile.recentCatches.map((c) => _catchRow(c)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                HomeTabIndex.notifier.value = HomeTabIndex.communityTabIndex;
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                t.es ? 'VER FEED COMUNIDAD' : 'VER FEED COMUNIDADE',
                style: _mono(11, c: AppColors.background),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tierChip(String tier) {
    final c = switch (tier.toUpperCase()) {
      'ELITE' => AppColors.amber,
      'PRO' => const Color(0xFF007BFF),
      _ => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withValues(alpha: 0.45)),
      ),
      child: Text(tier.toUpperCase(), style: _mono(9, c: c)),
    );
  }

  Widget _catchRow(CommunityProfileCatch c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          if (c.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _thumb(c.imageUrl!, 48),
            ),
          if (c.imageUrl != null) const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.species, style: _ibm(12, fw: FontWeight.w600)),
                Text(
                  '${c.weightLabel} · ${c.when}',
                  style: _ibm(11, c: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String source, double size) {
    final fallback = Container(
      width: size,
      height: size,
      color: AppColors.nav,
      child: Icon(Icons.person_outline, color: AppColors.textSecondary, size: size * 0.45),
    );
    if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    return Image.network(
      source,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  Widget _thumb(String source, double size) {
    if (source.startsWith('assets/')) {
      return Image.asset(source, width: size, height: size, fit: BoxFit.cover);
    }
    return Image.network(source, width: size, height: size, fit: BoxFit.cover);
  }
}
