import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/l10n/aqx_l10n.dart';
import '../../../core/location/gps_access.dart';
import '../../../core/location/gps_bootstrap.dart';
import '../../../core/supabase_bootstrap.dart';
import '../../../core/state/home_tab_index.dart';
import '../domain/entities/community_activity.dart';
import '../../../core/tides/oracle_data_service.dart';
import '../../../core/community/community_public_profile.dart';
import '../domain/entities/featured_spot.dart';
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

class _InicioDashboardScreenState extends State<InicioDashboardScreen>
    with WidgetsBindingObserver {
  late final HomeRepository _repo = widget.repository ?? HomeRepositoryImpl();

  bool _loading = false;
  String? _error;
  HomeDashboardData? _data;
  StreamSubscription<AuthState>? _authSub;
  Timer? _authReloadDebounce;
  bool _showGpsBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _data = HomeRepositoryImpl.instantFallback();
    unawaited(_load(silent: true));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startGpsFlow());
    });
    if (isSupabaseReady) {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
        if (event.event == AuthChangeEvent.signedIn) {
          GpsBootstrap.reset();
        }
        _authReloadDebounce?.cancel();
        _authReloadDebounce = Timer(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          if (event.event == AuthChangeEvent.signedIn) {
            unawaited(_startGpsFlow(forcePermission: true));
          } else {
            unawaited(_load(silent: true));
          }
        });
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authReloadDebounce?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    if (GpsAccess.cachedFix != null || GpsAccess.cachedFixStale != null) return;
    unawaited(_refreshGpsInBackground());
  }

  /// Permissão (diálogo) → fix curto em background → reload se houver coords.
  Future<void> _startGpsFlow({bool forcePermission = false}) async {
    final status = await GpsBootstrap.ensurePermission(forceRetry: forcePermission);
    if (!mounted) return;
    if (status == GpsAccessStatus.granted) {
      if (_showGpsBanner) setState(() => _showGpsBanner = false);
      unawaited(_refreshGpsInBackground());
      return;
    }
    setState(() => _showGpsBanner = true);
  }

  Future<void> _refreshGpsInBackground({bool forceRefresh = false}) async {
    final fix = await GpsBootstrap.refreshFix(forceRefresh: forceRefresh);
    if (!mounted) return;
    if (fix != null || forceRefresh) {
      OracleDataService.instance.invalidateCache();
      await _load(silent: true, forceRefresh: forceRefresh || fix != null);
    }
  }

  void _openFeaturedSpotOnMap(FeaturedSpot spot) {
    HomeTabIndex.pendingMapFocus.value = (
      lat: spot.lat,
      lon: spot.lon,
      label: spot.name,
    );
    widget.onOpenTab(HomeTabIndex.mapTabIndex);
  }

  void _openCommunityProfile(CommunityActivity activity) {
    HomeTabIndex.pendingCommunityProfile.value =
        CommunityPublicProfile.fromActivity(activity);
    widget.onOpenTab(HomeTabIndex.communityTabIndex);
  }

  Future<void> _enableGpsFromBanner() async {
    GpsBootstrap.reset();
    final status = await GpsBootstrap.ensurePermission(forceRetry: true);
    if (!mounted) return;
    if (status == GpsAccessStatus.granted) {
      setState(() => _showGpsBanner = false);
      await _refreshGpsInBackground();
      return;
    }
    await GpsAccess.openSystemSettings(status);
  }

  Future<void> _onPullRefresh() async {
    try {
      OracleDataService.instance.invalidateCache();
      final granted = await GpsAccess.check() == GpsAccessStatus.granted;
      if (granted) {
        await GpsAccess.tryGetFix(
          timeout: const Duration(seconds: 12),
          forceRefresh: true,
        );
      }
      await _load(silent: true, forceRefresh: true)
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      // Completa o RefreshIndicator mesmo se a rede demorar.
    }
  }

  Future<void> _load({bool silent = false, bool forceRefresh = false}) async {
    if (!silent) {
      setState(() {
        _loading = _data == null;
        _error = null;
      });
    }
    try {
      final d = await _repo.loadDashboard(forceRefresh: forceRefresh);
      if (!mounted) return;
      final displayName = _resolveUserDisplay(d.userDisplayName);
      setState(() {
        _data = d.copyWithUser(displayName);
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_data == null) _error = e.toString();
        _loading = false;
      });
    }
  }

  String _resolveUserDisplay(String fallback) {
    final client = supabaseClientOrNull;
    if (client == null) return fallback;
    try {
      final m = client.auth.currentUser?.userMetadata;
      final name = m?['full_name'] as String? ?? m?['name'] as String?;
      if (name != null && name.trim().isNotEmpty) {
        return name.trim().split(RegExp(r'\s+')).first;
      }
      final email = client.auth.currentUser?.email;
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
        onRefresh: _onPullRefresh,
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_showGpsBanner) ...[
              _GpsInlineBanner(
                t: t,
                onEnable: _enableGpsFromBanner,
                onDismiss: () => setState(() => _showGpsBanner = false),
                onSearchPlace: widget.onVerOracle,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
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
                  .map(
                    (s) => FeaturedSpotCard(
                      spot: s,
                      es: t.es,
                      onTap: () => _openFeaturedSpotOnMap(s),
                    ),
                  )
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
                        CommunityActivityCard(
                          activity: a,
                          onUserTap: () => _openCommunityProfile(a),
                        ),
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

/// Banner inline — nunca modal (modal bloqueava toques no MIUI).
class _GpsInlineBanner extends StatelessWidget {
  const _GpsInlineBanner({
    required this.t,
    required this.onEnable,
    required this.onDismiss,
    required this.onSearchPlace,
  });

  final AqxL10n t;
  final VoidCallback onEnable;
  final VoidCallback onDismiss;
  final VoidCallback onSearchPlace;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1408),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onEnable,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.45)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_off_rounded, color: AppColors.amber, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.locationPromptTitle,
                      style: AppTextStyles.ibmSans(13, fw: FontWeight.w700, color: AppColors.amber),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.gpsDenied,
                      style: AppTextStyles.ibmSans(12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        TextButton(
                          onPressed: onEnable,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(t.enableLocation, style: AppTextStyles.ibmSans(12, fw: FontWeight.w600)),
                        ),
                        TextButton(
                          onPressed: onSearchPlace,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(t.locationPromptChoosePlace, style: AppTextStyles.ibmSans(12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
