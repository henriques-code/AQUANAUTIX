import 'dart:async';

import 'package:flutter/material.dart';

import '../core/community/community_demo_posts.dart';
import '../core/community/community_post.dart';
import '../core/community/community_public_profile.dart';
import '../core/community/community_store.dart';
import '../core/l10n/aqx_l10n.dart';
import '../core/state/fishing_context_store.dart';
import '../core/state/logbook_tab_index.dart';
import '../core/state/home_tab_index.dart';
import '../core/supabase_bootstrap.dart';
import '../core/widgets/aqx_ghost_mode_badge.dart';
import '../features/community/presentation/community_ghost_profile_sheet.dart';
import '_shared.dart';
import 'paywall.dart';

/// Tab Comunidade — feed Ghost (P9).
class ComunidadeScreen extends StatefulWidget {
  const ComunidadeScreen({super.key});

  @override
  State<ComunidadeScreen> createState() => _ComunidadeScreenState();
}

class _ComunidadeScreenState extends State<ComunidadeScreen> {
  final _feedLikes = <int, bool>{};

  @override
  void initState() {
    super.initState();
    HomeTabIndex.pendingCommunityProfile.addListener(_applyPendingCommunityProfile);
    if (isSupabaseConfigured) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx = FishingContextStore.instance.value.value;
        unawaited(CommunityStore.instance.loadFeed(country: ctx.country));
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyPendingCommunityProfile());
  }

  @override
  void dispose() {
    HomeTabIndex.pendingCommunityProfile.removeListener(_applyPendingCommunityProfile);
    super.dispose();
  }

  void _applyPendingCommunityProfile() {
    final profile = HomeTabIndex.pendingCommunityProfile.value;
    if (profile == null || !mounted) return;
    HomeTabIndex.pendingCommunityProfile.value = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(showCommunityGhostProfileSheet(context, profile));
    });
  }

  String _timeAgo(DateTime dt, AqxL10n t) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) {
      return t.es ? 'hace ${d.inMinutes} min' : 'há ${d.inMinutes} min';
    }
    if (d.inHours < 24) return t.es ? 'hace ${d.inHours}h' : 'há ${d.inHours}h';
    return t.es ? 'hace ${d.inDays}d' : 'há ${d.inDays}d';
  }

  void _openProfile(CommunityPost post) {
    unawaited(
      showCommunityGhostProfileSheet(
        context,
        CommunityPublicProfile.fromPost(post),
      ),
    );
  }

  void _openPublish() {
    LogbookTabIndex.pendingTab.value = LogbookTabIndex.comunidadeTab;
    LogbookTabIndex.pendingAction.value = 'novo_post';
    HomeTabIndex.notifier.value = HomeTabIndex.logTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    final t = aqxL10nOf(context);
    return Column(
      children: [
        Container(
          color: kCard,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Text(t.es ? 'COMUNIDAD' : 'COMUNIDADE', style: orb(20, ls: 2)),
              const Spacer(),
              GestureDetector(
                onTap: _openPublish,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kCyan.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, color: kCyan, size: 16),
                      const SizedBox(width: 4),
                      Text(t.es ? 'PUBLICAR' : 'PUBLICAR', style: mono(9, c: kCyan)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<CommunityState>(
            valueListenable: CommunityStore.instance.value,
            builder: (context, state, _) {
              final posts =
                  state.posts.isNotEmpty ? state.posts : CommunityDemoPosts.posts();
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: kAmber.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kAmber.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const AqxGhostModeBadge(size: 13),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.es
                                ? 'GHOST MODE — coordenadas nunca compartidas. Zona mínima 5km.'
                                : 'GHOST MODE — coordenadas nunca partilhadas. Zona mínima 5km.',
                            style: ibm(10, c: kHint),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...posts.asMap().entries.map(
                        (e) => _buildPostCard(e.key, e.value, t, state),
                      ),
                  if (state.loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(color: kCyan, strokeWidth: 2),
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPostCard(int idx, CommunityPost post, AqxL10n t, CommunityState state) {
    final isLive = isSupabaseConfigured && state.posts.isNotEmpty;
    final liked = isLive ? post.likedByMe : (_feedLikes[idx] ?? false);
    final likeCount =
        isLive ? post.likesCount : post.likesCount + (liked ? 1 : 0);
    final avatar = post.avatarUrl ?? 'https://i.pravatar.cc/80?u=${post.userId}';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      color: kCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openProfile(post),
                    customBorder: const CircleBorder(),
                    child: ClipOval(child: netImg(avatar, width: 36, height: 36)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openProfile(post),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(post.username, style: ibm(12, fw: FontWeight.w600)),
                            const SizedBox(height: 2),
                            AqxGhostZoneLabel(
                              label: post.zoneLabel,
                              style: mono(9),
                              badgeSize: 9,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Text(_timeAgo(post.createdAt, t), style: mono(9)),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 180,
            child: post.locked
                ? GestureDetector(
                    onTap: () =>
                        PaywallScreen.open(context, source: 'comunidade_post_locked'),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _postPhoto(post.photoUrl, 180),
                        Container(color: Colors.black.withValues(alpha: 0.35)),
                        Center(
                          child: Icon(Icons.lock_outline, color: kAmber.withValues(alpha: 0.9)),
                        ),
                      ],
                    ),
                  )
                : _postPhoto(post.photoUrl, 180),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _feedLikes[idx] = !liked),
                  child: Row(
                    children: [
                      Icon(
                        liked ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: liked ? Colors.redAccent : kHint,
                      ),
                      const SizedBox(width: 4),
                      Text('$likeCount', style: mono(10)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${post.species} · ${post.weightKg?.toStringAsFixed(1) ?? '—'} kg',
                  style: ibm(11, c: kHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _postPhoto(String source, double height) {
    if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: height,
          color: const Color(0xFF0A1F3A),
          child: const Icon(Icons.image_not_supported_outlined, color: kInact),
        ),
      );
    }
    return netImg(source, width: double.infinity, height: height);
  }
}
