import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.menu_rounded, color: AppColors.accent),
        onPressed: () {},
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
          onPressed: () {},
        ),
      ],
    );
  }
}
