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
import 'widgets/hourly_condition_card.dart';
import 'widgets/section_header.dart';
import 'widgets/weather_card.dart';

/// Ecrã Início — hub diário (dados mock via [HomeRepository]).
class InicioDashboardScreen extends StatefulWidget {
  const InicioDashboardScreen({
    super.key,
    required this.onVerMapa,
    this.repository,
  });

  final VoidCallback onVerMapa;
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
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const HomeAppBar(),
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
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const HomeAppBar(),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const HomeAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GreetingHeader(
              greetingLine: t.homeGreetingPersonalized(hour, data.userDisplayName),
              tagline: t.homeTagline,
            ),
            const SizedBox(height: AppSpacing.md),
            WeatherCard(weather: data.weather, t: t),
            const SizedBox(height: AppSpacing.md),
            HomeSectionHeader(title: t.homeSectionConditions, actionLabel: t.homeVerTodas, onActionTap: () {}),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: data.hourlyConditions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => HourlyConditionCard(item: data.hourlyConditions[i]),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            HomeSectionHeader(title: t.homeSectionSpots, actionLabel: t.homeVerMapa, onActionTap: widget.onVerMapa),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: data.featuredSpots.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => FeaturedSpotCard(spot: data.featuredSpots[i], es: t.es),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            HomeSectionHeader(title: t.homeSectionCommunity),
            const SizedBox(height: AppSpacing.sm),
            ...data.communityActivities.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: CommunityActivityCard(activity: a),
                )),
          ],
        ),
      ),
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
