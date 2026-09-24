import 'package:flutter/material.dart';

import '_shared.dart';
import 'widgets/affiliate_shop_mockup.dart';

/// Ecrã mockup — loja afiliada (material de pesca PT/ES).
class AffiliateShopScreen extends StatelessWidget {
  const AffiliateShopScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const AffiliateShopScreen(),
        transitionDuration: const Duration(milliseconds: 320),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kNav,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: kCyan),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text('AQUANAUTIX', style: orb(13, ls: 0.6)),
            Text('LOJA', style: mono(8, c: kCyan, ls: 1.6)),
          ],
        ),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        child: AffiliateShopMockup(),
      ),
    );
  }
}
