import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/aqx_l10n.dart';
import '../../../../core/state/home_tab_index.dart';
import '../../../../core/state/logbook_tab_index.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../screens/especies.dart';

class HomeNavigationDrawer extends StatelessWidget {
  const HomeNavigationDrawer({
    super.key,
    required this.onOpenTab,
  });

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final t = AqxL10n(Localizations.localeOf(context).languageCode);
    final email = Supabase.instance.client.auth.currentUser?.email;

    return Drawer(
      backgroundColor: AppColors.nav,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AQUANAUTIX', style: AppTextStyles.orbitron(16, fw: FontWeight.w700)),
                  Text('.APP', style: AppTextStyles.orbitron(10, fw: FontWeight.w600, color: AppColors.accent, ls: 2)),
                  if (email != null && email.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(email, style: AppTextStyles.ibmSans(11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF1A3050)),
            _item(context, Icons.track_changes_rounded, t.tabOracle, tabIndex: HomeTabIndex.oracleTabIndex),
            _item(context, Icons.map_outlined, t.tabMap, tabIndex: HomeTabIndex.mapTabIndex),
            _item(context, Icons.photo_camera_outlined, t.tabVision, tabIndex: HomeTabIndex.visionTabIndex),
            _item(context, Icons.menu_book_outlined, t.tabLog, tabIndex: HomeTabIndex.logTabIndex),
            _item(context, Icons.person_outline_rounded, t.tabProfile, tabIndex: HomeTabIndex.profileTabIndex),
            const Divider(height: 1, color: Color(0xFF1A3050)),
            _item(
              context,
              Icons.people_outline_rounded,
              t.drawerCommunity,
              onTap: () => _openCommunity(context),
            ),
            _item(
              context,
              Icons.auto_stories_outlined,
              t.drawerSpecies,
              onTap: () => _openSpecies(context),
            ),
            _item(
              context,
              Icons.phishing_outlined,
              t.drawerTechniques,
              onTap: () => _openTechniques(context),
            ),
            const Spacer(),
            const Divider(height: 1, color: Color(0xFF1A3050)),
            ListTile(
              dense: true,
              leading: const Icon(Icons.settings_outlined, color: AppColors.textSecondary, size: 20),
              title: Text(t.settings, style: AppTextStyles.ibmSans(13, color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                Geolocator.openAppSettings();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openCommunity(BuildContext context) {
    Navigator.pop(context);
    LogbookTabIndex.pendingTab.value = LogbookTabIndex.comunidadeTab;
    onOpenTab(HomeTabIndex.logTabIndex);
  }

  void _openSpecies(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const EspeciesScreen(),
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _openTechniques(BuildContext context) {
    Navigator.pop(context);
    onOpenTab(HomeTabIndex.oracleTabIndex);
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String label, {
    int? tabIndex,
    VoidCallback? onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: AppColors.accent, size: 20),
      title: Text(label, style: AppTextStyles.ibmSans(13, fw: FontWeight.w600)),
      onTap: onTap ??
          () {
            Navigator.pop(context);
            onOpenTab(tabIndex!);
          },
    );
  }
}
