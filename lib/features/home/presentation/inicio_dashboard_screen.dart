import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/l10n/aqx_l10n.dart';
import '../../../core/supabase_bootstrap.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/home_repository_impl.dart';
import '../domain/repositories/home_repository.dart';
import 'widgets/community_activity_card.dart';
import 'widgets/featured_spot_card.dart';
import 'widgets/greeting_header.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/home_navigation_drawer.dart';
import 'widgets/hourly_condition_card.dart';
import 'widgets/section_header.dart';
import 'widgets/weather_card.dart';

/// Ecrã Início — hub diário (dados mock via [HomeRepository]).
class InicioDashboardScreen extends StatefulWidget {
  const InicioDashboardScreen({
    super.key,
    required this.onVerMapa,
    required this.onVerOracle,
    required this.onOpenTab,
    this.repository,
  });

  final VoidCallback onVerMapa;
  final VoidCallback onVerOracle;
  final ValueChanged<int> onOpenTab;
  final HomeRepository? repository;

  @override
  State<InicioDashboardScreen> createState() => _InicioDashboardScreenState();
}

class _InicioDashboardScreenState extends State<InicioDashboardScreen> {
  late final HomeRepository _repo = widget.repository ?? HomeRepositoryImpl();

  bool _loading = true;
  String? _error;
  HomeDashboardData? _data;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _load();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await _repo.loadDashboard();
      if (!mounted) return;
      final displayName = _resolveUserDisplay(d.userDisplayName);
      setState(() {
        _data = d.copyWithUser(displayName);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _resolveUserDisplay(String fallback) {
    if (!isSupabaseConfigured) return fallback;
    try {
      final m = Supabase.instance.client.auth.currentUser?.userMetadata;
      final name = m?['full_name'] as String? ?? m?['name'] as String?;
      if (name != null && name.trim().isNotEmpty) {
        return name.trim().split(RegExp(r'\s+')).first;
      }
      final email = Supabase.instance.client.auth.currentUser?.email;
      if (email != null && email.contains('@')) {
        return email.split('@').first;
      }
    } catch (_) {}
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final t = AqxL10n(lang);

    if (_loading) {
      return _homeScaffold(
        body: const Center(
          child: SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.accent),
          ),
        ),
      );
    }

    if (_error != null || _data == null) {
      return _homeScaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(t.homeLoadError, textAlign: TextAlign.center, style: AppTextStyles.ibmSans(15)),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: _load,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                  ),
                  child: Text(t.homeRetry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final data = _data!;
    final hour = DateTime.now().hour;

    return _homeScaffold(
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: const Color(0xFF071428),
        onRefresh: _load,
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GreetingHeader(
              greetingLine: t.homeGreetingLine(hour),
              tagline: t.homeTagline,
            ),
            const SizedBox(height: AppSpacing.md),
            WeatherCard(weather: data.weather, t: t),
            const SizedBox(height: AppSpacing.md),
            HomeSectionHeader(
              title: t.homeSectionConditions,
              actionLabel: t.homeVerTodas,
              onActionTap: widget.onVerOracle,
            ),
            const SizedBox(height: AppSpacing.sm),
            // 5 slots iguais — sem altura fixa, sem scroll
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < data.hourlyConditions.length; i++) ...[
                  if (i > 0)
                    Container(
                      width: 0.5,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      color: AppColors.accent.withValues(alpha: 0.12),
                    ),
                  Expanded(
                    child: HourlyConditionCard(
                      item: data.hourlyConditions[i],
                      t: t,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            HomeSectionHeader(title: t.homeSectionSpots, actionLabel: t.homeVerMapa, onActionTap: widget.onVerMapa),
            const SizedBox(height: AppSpacing.sm),
            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: data.featuredSpots
                  .map((s) => FeaturedSpotCard(spot: s, es: t.es))
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            HomeSectionHeader(title: t.homeSectionCommunity),
            const SizedBox(height: AppSpacing.sm),
            if (data.communityActivities.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: Text(
                    t.es
                        ? 'Sé el primero en compartir una captura'
                        : 'Sê o primeiro a partilhar uma captura',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.ibmSans(14, color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...data.communityActivities.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CommunityActivityCard(activity: a),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.favorite_border, size: 12, color: AppColors.textSecondary),
                            Text(
                              ' 24  ',
                              style: AppTextStyles.ibmSans(10, color: AppColors.textSecondary),
                            ),
                            Icon(Icons.chat_bubble_outline, size: 12, color: AppColors.textSecondary),
                            Text(
                              ' 5 comentários',
                              style: AppTextStyles.ibmSans(10, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
          ],
        ),
        ),
      ),
    );
  }

  Widget _homeScaffold({required Widget body}) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const HomeAppBar(),
      drawer: HomeNavigationDrawer(onOpenTab: widget.onOpenTab),
      body: body,
    );
  }
}

extension on HomeDashboardData {
  HomeDashboardData copyWithUser(String name) => HomeDashboardData(
        weather: weather,
        hourlyConditions: hourlyConditions,
        featuredSpots: featuredSpots,
        communityActivities: communityActivities,
        userDisplayName: name,
      );
}
