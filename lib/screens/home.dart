import 'dart:async';

import 'package:flutter/material.dart';
import '_shared.dart';
import 'oraculo.dart';
import 'mapa.dart';
import 'vision.dart';
import 'logbook.dart';
import 'perfil.dart';
import 'comunidade.dart';
import '../features/home/presentation/inicio_dashboard_screen.dart';
import '../core/l10n/aqx_l10n.dart';
import '../core/services/analytics_service.dart';
import '../core/state/home_tab_index.dart';
import '../core/location/gps_bootstrap.dart';

/// Ecrã principal com navegação entre os 7 ecrãs AQUANAUTIX.
class AquanautixHome extends StatefulWidget {
  const AquanautixHome({super.key});

  @override
  State<AquanautixHome> createState() => _AquanautixHomeState();
}

class _AquanautixHomeState extends State<AquanautixHome> {
  int _idx = 0;
  /// Um tab de cada vez (sem IndexedStack) — preserva estado após 1.ª visita.
  final Map<int, Widget> _tabCache = {};

  void _setTab(int i) {
    setState(() => _idx = i);
    HomeTabIndex.notifier.value = i;
  }

  @override
  void initState() {
    super.initState();
    HomeTabIndex.notifier.value = _idx;
    HomeTabIndex.notifier.addListener(_onExternalTabRequest);
    // GPS o mais cedo possível após login — só permissão; fix em background no Início.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(GpsBootstrap.ensurePermission());
    });
  }

  @override
  void dispose() {
    HomeTabIndex.notifier.removeListener(_onExternalTabRequest);
    super.dispose();
  }

  void _onExternalTabRequest() {
    final i = HomeTabIndex.notifier.value;
    if (!mounted || i == _idx) return;
    setState(() => _idx = i);
  }

  Widget _createTab(int i) {
    switch (i) {
      case 0:
        return InicioDashboardScreen(
          key: const ValueKey('tab_inicio'),
          onVerMapa: () => _setTab(HomeTabIndex.mapTabIndex),
          onVerOracle: () => _setTab(HomeTabIndex.oracleTabIndex),
          onOpenTab: _setTab,
        );
      case 1:
        return const OraculoScreen(key: ValueKey('tab_oraculo'));
      case 2:
        return MapaScreen(
          key: const ValueKey('tab_mapa'),
          onSpotOpensOracle: _openOracleFromMap,
        );
      case 3:
        return const VisionScreen(key: ValueKey('tab_vision'));
      case 4:
        return const LogbookScreen(key: ValueKey('tab_logbook'));
      case 5:
        return const PerfilScreen(key: ValueKey('tab_perfil'));
      case 6:
        return const ComunidadeScreen(key: ValueKey('tab_comunidade'));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _activeTab() {
    return _tabCache.putIfAbsent(_idx, () => _createTab(_idx));
  }

  static const _icons = [
    Icons.home_outlined,
    Icons.track_changes_rounded,
    Icons.map_outlined,
    Icons.photo_camera_outlined,
    Icons.menu_book_outlined,
    Icons.person_outline_rounded,
    Icons.groups_outlined,
  ];

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
        child: _activeTab(),
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
        t.tabCommunity,
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
            children: List.generate(7, (i) {
              final sel = _idx == i;
              final c = sel ? kCyan : kInact;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
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
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          labels[i],
                          style: mono(8, c: c),
                          maxLines: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 4,
                      height: 4,
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
