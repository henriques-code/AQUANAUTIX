import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../supabase_bootstrap.dart';
import 'analytics_context.dart';

/// Envio para Supabase `analytics_events` + log local.
///
/// [AnalyticsEvents] define o naming final Sprint 1 (snake_case).
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  Future<void> track(
    String eventName, {
    Map<String, dynamic> params = const {},
  }) async {
    final merged = <String, dynamic>{
      ...AnalyticsContext.baseParams(),
      ...params,
    };

    final payload = <String, dynamic>{
      'event_name': eventName,
      'params': merged,
      'source': 'flutter_app',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    debugPrint('[AQUANAUTIX][analytics] $eventName ${jsonEncode(merged)}');

    final client = supabaseClientOrNull;
    if (client == null) return;
    try {
      await client.from('analytics_events').insert(payload);
    } catch (_) {
      // Fail-safe: analytics must never break UX.
    }
  }
}

/// Taxonomia Sprint 1 — não renomear à-toa (queries / dashboards dependem disto).
class AnalyticsEvents {
  // ── Ciclo de vida / retenção ─────────────────────────────
  static const appOpen = 'app_open';

  // ── Activação / onboarding ────────────────────────────────
  static const onboardingComplete = 'onboarding_complete';

  // ── Funil monetização ─────────────────────────────────────
  static const paywallView = 'paywall_view';
  static const paywallDismiss = 'paywall_dismiss';
  static const paywallPlanSelected = 'paywall_plan_selected';
  static const trialStart = 'trial_start';
  static const purchaseSuccess = 'purchase_success';
  static const subscriptionChanged = 'subscription_changed';

  // ── North star (produto) ─────────────────────────────────
  static const northStarOracleView = 'north_star_oracle_view';

  // ── Navegação / módulos ───────────────────────────────────
  static const missionStarted = 'mission_started';
  static const missionCompleted = 'mission_completed';
  static const tabChange = 'tab_change';
  static const moduleOpen = 'module_open';
  static const growthDashboardView = 'growth_dashboard_view';

  static const assistantOpen = 'assistant_open';
  static const assistantPhotoSend = 'assistant_photo_send';
  static const assistantVoiceUsed = 'assistant_voice_used';
  static const mapToOracle = 'map_to_oracle';
  static const tidesCalendarOpen = 'tides_calendar_open';
  static const tidesGpsRefresh = 'tides_gps_refresh';
  static const tidesPortSelected = 'tides_port_selected';
  static const tidesOffsetSet = 'tides_offset_set';
  static const baitRadarOpen = 'bait_radar_open';
  static const baitRadarSearch = 'bait_radar_search';
  static const recfishingIntroView = 'recfishing_intro_view';
  static const recfishingIntroComplete = 'recfishing_intro_complete';
  static const recfishingLogbookLink = 'recfishing_logbook_link_open';
}
