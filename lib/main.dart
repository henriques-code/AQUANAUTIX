import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/services/analytics_context.dart';
import 'core/services/analytics_service.dart';
import 'core/supabase_bootstrap.dart';
import 'core/state/app_locale_store.dart';
import 'core/state/fishing_context_store.dart';
import 'core/state/subscription_store.dart';
import 'core/services/revenue_cat_service.dart';
import 'core/monetization/subscription_auth_bridge.dart';
import 'core/config/mapbox_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initMapboxIfConfigured();
  await AnalyticsContext.init();
  await initSupabaseIfConfigured();
  unawaited(
    AnalyticsService.instance.track(AnalyticsEvents.appOpen, params: const {}),
  );
  await FishingContextStore.instance.init();
  await AppLocaleStore.instance.init();
  try {
    await RevenueCatService.instance.configure();
  } catch (_) {
    // RC indisponível em dev sem keys — app continua com SubscriptionStore local.
  }
  await SubscriptionStore.instance.init();
  SubscriptionAuthBridge.init();
  if (kDebugMode && RevenueCatService.instance.isSdkReady) {
    final d = await RevenueCatService.instance.diagnostics();
    debugPrint(
      '[AQUANAUTIX][RC] offering=${d.offeringId ?? "—"} packages=${d.packageCount}',
    );
  }
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const AquanautixApp());
}
