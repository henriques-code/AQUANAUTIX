import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Serviço de notificações locais para a Janela de Ouro.
///
/// PRO  — alarme diário agendado para as 07:00, com score e local actuais.
/// FREE — máximo 1 notificação por semana (gatilho de upgrade).
class GoldenWindowNotificationService {
  GoldenWindowNotificationService._();
  static final GoldenWindowNotificationService instance =
      GoldenWindowNotificationService._();

  // ─── constantes ─────────────────────────────────────────────────────────────
  static const _channelId = 'aqx_golden_window';
  static const _channelName = 'Janela de Ouro';
  static const _notifId = 1001;
  static const _prefEnabled = 'notif_gw_enabled';
  static const _prefLastFreeMs = 'notif_gw_last_free_ms';
  static const _weekMs = 7 * 24 * 60 * 60 * 1000;

  // ─── estado ─────────────────────────────────────────────────────────────────
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _enabled = false;

  bool get isEnabled => _enabled;

  // ─── inicialização ──────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );

    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefEnabled) ?? false;
    _initialized = true;
  }

  // notificação tocada — a navegação é tratada pela app ao abrir
  static void _onTap(NotificationResponse _) {}

  // ─── permissão ──────────────────────────────────────────────────────────────
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true; // outras plataformas — assumir OK
  }

  // ─── activar alerta ─────────────────────────────────────────────────────────
  /// Solicita permissão e agenda notificação diária às 07:00.
  ///
  /// [placeHint]      — nome curto do local (ex.: "Sesimbra", "Praia da Rocha")
  /// [scoreEstimate]  — score oráculo calculado no momento
  /// [bestHour]       — melhor hora estimada (ex.: "07:15")
  /// [isPro]          — determina frequência: PRO=diária, FREE=1x/semana
  ///
  /// Retorna `true` se o agendamento foi bem-sucedido.
  Future<bool> requestAndSchedule({
    required String placeHint,
    required int scoreEstimate,
    required String bestHour,
    required bool isPro,
  }) async {
    if (kIsWeb) return false;

    // gate FREE — máximo 1x por semana
    if (!isPro) {
      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt(_prefLastFreeMs) ?? 0;
      final elapsed = DateTime.now().millisecondsSinceEpoch - lastMs;
      if (elapsed < _weekMs) return false;
    }

    final granted = await requestPermission();
    if (!granted) return false;

    await _scheduleDaily(
      placeHint: placeHint,
      scoreEstimate: scoreEstimate,
      bestHour: bestHour,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, true);
    if (!isPro) {
      await prefs.setInt(
          _prefLastFreeMs, DateTime.now().millisecondsSinceEpoch);
    }
    _enabled = true;
    return true;
  }

  // ─── cancelar ───────────────────────────────────────────────────────────────
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, false);
    _enabled = false;
  }

  // ─── agendamento interno ────────────────────────────────────────────────────
  Future<void> _scheduleDaily({
    required String placeHint,
    required int scoreEstimate,
    required String bestHour,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    // próximo 07:00 (hoje se ainda não passou; amanhã caso contrário)
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 7, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Alertas da Janela de Ouro — AQUANAUTIX',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      ticker: 'Janela de Ouro',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.zonedSchedule(
      id: _notifId,
      title: '⚡ Janela de Ouro · $placeHint',
      body: 'Score $scoreEstimate — melhor hora às $bestHour · Abre o Oráculo →',
      scheduledDate: scheduled,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
