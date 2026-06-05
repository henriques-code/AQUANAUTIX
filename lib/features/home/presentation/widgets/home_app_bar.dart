import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/aqx_l10n.dart';
import '../../../../core/state/subscription_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../screens/paywall.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu_rounded, color: AppColors.accent),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('AQUANAUTIX', style: AppTextStyles.orbitron(14, fw: FontWeight.w700)),
          Text('.APP', style: AppTextStyles.orbitron(9, fw: FontWeight.w600, color: AppColors.accent, ls: 2)),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
          onPressed: () => _onNotifications(context),
        ),
      ],
    );
  }

  Future<void> _onNotifications(BuildContext context) async {
    HapticFeedback.selectionClick();
    final t = AqxL10n(Localizations.localeOf(context).languageCode);
    final plan = SubscriptionStore.instance.value.value;
    if (!plan.hasProEntitlement) {
      await PaywallScreen.open(context, source: 'home_alertas');
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.alertsProConfigSoon, style: AppTextStyles.ibmSans(14)),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
