import 'dart:async';

import 'package:flutter/material.dart';
import '_shared.dart';
import 'oraculo.dart';
import 'mapa.dart';
import 'vision.dart';
import 'logbook.dart';
import 'perfil.dart';
import '../features/home/presentation/inicio_dashboard_screen.dart';
import '../core/l10n/aqx_l10n.dart';
import '../core/location/gps_access.dart';
import '../core/services/analytics_service.dart';
import '../core/state/home_tab_index.dart';
import 'widgets/location_access_sheet.dart';

/// Ecrã principal com navegação entre os 6 ecrãs AQUANAUTIX.
class AquanautixHome extends StatefulWidget {
  const AquanautixHome({super.key});

  @override
  State<AquanautixHome> createState() => _AquanautixHomeState();
}

class _AquanautixHomeState extends State<AquanautixHome> {
  int _idx = 0;
  bool _locationPromptShown = false;

  void _setTab(int i) {
    setState(() => _idx = i);
    HomeTabIndex.notifier.value = i;
  }

  @override
  void initState() {
    super.initState();
    HomeTabIndex.notifier.value = _idx;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_promptLocationIfNeeded());
    });
  }

  Future<void> _promptLocationIfNeeded() async {
    if (!mounted || _locationPromptShown) return;
    final status = await GpsAccess.check();
    if (status == GpsAccessStatus.granted || !mounted) return;

    _locationPromptShown = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (ctx) => LocationAccessSheet(
        status: status,
        onEnableGps: () async {
          Navigator.pop(ctx);
          var next = await GpsAccess.request();
          if (next != GpsAccessStatus.granted) {
            await GpsAccess.openSystemSettings(next);
          }
        },
        onSearchPlace: () {
          Navigator.pop(ctx);
          _openOraclePlaceSearch();
        },
      ),
    );
  }

  void _openOraclePlaceSearch() {
    _setTab(HomeTabIndex.oracleTabIndex);
    HomeTabIndex.pendingOraclePlaceSearch.value = true;
  }

  static const _icons = [
    Icons.home_outlined,
    Icons.track_changes_rounded,
    Icons.map_outlined,
    Icons.photo_camera_outlined,
    Icons.menu_book_outlined,
    Icons.person_outline_rounded,
  ];

  /// Sprint A — ao escolher spot no mapa, contexto actualiza e abre o Oráculo.
  void _openOracleFromMap() {
    if (!mounted) return;
    _setTab(HomeTabIndex.oracleTabIndex);
    unawaited(
      AnalyticsService.instance.track(
        AnalyticsEvents.tabChange,
        params: {'tab': 'ORÁCULO', 'source': 'mapa_spot'},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _idx,
          children: [
            InicioDashboardScreen(
              onVerMapa: () => _setTab(HomeTabIndex.mapTabIndex),
              onVerOracle: () => _setTab(HomeTabIndex.oracleTabIndex),
              onOpenTab: _setTab,
            ),
            const OraculoScreen(),
            MapaScreen(onSpotOpensOracle: _openOracleFromMap),
            const VisionScreen(),
            const LogbookScreen(),
            const PerfilScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _buildNav(),
    );
  }

  List<String> _tabLabels(AqxL10n t) => [
        t.tabHome,
        t.tabOracle,
        t.tabMap,
        t.tabVision,
        t.tabLog,
        t.tabProfile,
      ];

  Widget _buildNav() {
    final labels = _tabLabels(AqxL10n(Localizations.localeOf(context).languageCode));
    return Material(
      color: kNav,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: kNav,
            border: Border(top: BorderSide(color: kCyan.withValues(alpha: 0.15))),
          ),
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Row(
            children: List.generate(6, (i) {
              final sel = _idx == i;
              final c   = sel ? kCyan : kInact;
              return Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final nextLabel = labels[i];
                    _setTab(i);
                    unawaited(AnalyticsService.instance.track(
                      AnalyticsEvents.tabChange,
                      params: {'tab': nextLabel},
                    ));
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_icons[i], size: 20, color: c),
                    const SizedBox(height: 3),
                    Text(labels[i], style: mono(8, c: c)),
                    const SizedBox(height: 4),
                    Container(
                      width: 4, height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: sel ? kCyan : Colors.transparent,
                        boxShadow: sel
                            ? [BoxShadow(color: kCyan.withValues(alpha: 0.8), blurRadius: 6)]
                            : null,
                      ),
                    ),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
