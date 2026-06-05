import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/l10n/aqx_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/aqua_card.dart';
import '../../domain/entities/weather_data.dart';
import 'conditions_metric_card.dart';
import 'location_header.dart';
import 'solunar_progress_bar.dart';

/// Módulo de Condições Actuais — design Midnight Deep Sea.
class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key, required this.weather, required this.t});

  final WeatherData weather;
  final AqxL10n t;

  static String _solunarBadgeLabel(int score) {
    if (score >= 70) return 'Major';
    if (score >= 40) return 'Minor';
    return 'Inativo';
  }

  static Color _solunarBadgeColor(int score) {
    if (score >= 70) return AppColors.green;
    if (score >= 40) return AppColors.amber;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasTide = weather.tideHeight > 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Moldura reduzida: width 0.8, shadow mais contida
        border: Border.all(color: const Color(0xFF2563EB), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.22),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: AquaCard(
        borderRadius: 16,
        borderAlpha: 0.0,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Localização ──────────────────────────────────────────────
            LocationHeader(location: weather.location),
            const SizedBox(height: AppSpacing.xs),
            Divider(height: 1, color: AppColors.accent.withValues(alpha: 0.12)),
            const SizedBox(height: AppSpacing.xs),

            // ── Temperatura + ícone de condição ───────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${weather.temperature.round()}',
                            style: AppTextStyles.orbitron(36, fw: FontWeight.w700),
                          ),
                          Text(
                            '°C',
                            style: AppTextStyles.orbitron(
                              18,
                              fw: FontWeight.w400,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        weather.condition,
                        style: AppTextStyles.ibmSans(12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (weather.pressure != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${weather.pressure} mb',
                          style: AppTextStyles.ibmSans(
                            10,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Ícone de condição com fundo circular
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      weather.conditionIcon,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),
            Divider(height: 1, color: AppColors.accent.withValues(alpha: 0.12)),
            const SizedBox(height: AppSpacing.sm),

            // ── Grid 2×2 de métricas ──────────────────────────────────────
            // CrossAxisAlignment.stretch: os dois cards em cada Row ficam
            // à mesma altura (a mais alta), separador fixo no fundo.
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Vento — com bússola animada por baixo da velocidade
                Expanded(
                  child: ConditionsMetricCard(
                    icon: const Icon(
                      Icons.air_rounded,
                      size: 22,
                      color: AppColors.accent,
                    ),
                    label: t.homeStatWind,
                    value: '${weather.windSpeed.round()} km/h',
                    bottomWidget: _WindCompassMini(direction: weather.windDir),
                    semanticLabel:
                        '${t.homeStatWind}: ${weather.windSpeed.round()} km/h'
                        '${weather.windDir != null ? " ${weather.windDir}" : ""}',
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                // Ondas
                Expanded(
                  child: ConditionsMetricCard(
                    icon: const Icon(
                      Icons.waves_rounded,
                      size: 22,
                      color: AppColors.accent,
                    ),
                    label: t.homeStatWaves,
                    value: '≈ ${weather.waveHeight.toStringAsFixed(1)} m',
                    semanticLabel:
                        '${t.homeStatWaves}: ${weather.waveHeight.toStringAsFixed(1)} m',
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xs),

            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Maré
                Expanded(
                  child: AnimatedOpacity(
                    opacity: hasTide ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: ConditionsMetricCard(
                      icon: Icon(
                        weather.tideRising
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 22,
                        color: weather.tideRising ? AppColors.accent : AppColors.amber,
                      ),
                      label: t.homeStatTide,
                      value: '≈ ${weather.tideHeight.toStringAsFixed(1)} m',
                      subValue: weather.tideRising
                          ? (t.es ? '↑ Creciente' : '↑ Enchente')
                          : (t.es ? '↓ Vaciante' : '↓ Vazante'),
                      subValueColor:
                          weather.tideRising ? AppColors.accent : AppColors.amber,
                      semanticLabel:
                          '${t.homeStatTide}: ${weather.tideHeight.toStringAsFixed(1)} m, '
                          '${weather.tideRising ? "Enchente" : "Vazante"}',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                // Lua
                Expanded(
                  child: ConditionsMetricCard(
                    icon: const Icon(
                      Icons.nightlight_round,
                      size: 22,
                      color: AppColors.amber,
                    ),
                    label: t.homeStatMoon,
                    value: weather.moonPhase,
                    subValue: _solunarBadgeLabel(weather.solunarScore),
                    subValueColor: _solunarBadgeColor(weather.solunarScore),
                    semanticLabel: '${t.homeStatMoon}: ${weather.moonPhase}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),
            Divider(height: 1, color: AppColors.accent.withValues(alpha: 0.10)),
            const SizedBox(height: AppSpacing.sm),

            // ── Barra de actividade solunar ───────────────────────────────
            SolunarProgressBar(
              score: weather.solunarScore,
              qualityLabel: t.scoreLabel(weather.solunarScore),
              weakLabel: t.es ? 'DÉBIL' : 'FRACA',
              excellentLabel: 'EXCELENTE',
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .slideY(begin: 0.05, end: 0, duration: 500.ms, curve: Curves.easeOutCubic);
  }
}

// ── Bússola animada (card de vento) ───────────────────────────────────────────

class _WindCompassMini extends StatelessWidget {
  const _WindCompassMini({this.direction});

  final String? direction;

  static const double _size = 44.0;

  static double _dirToRadians(String dir) {
    const degMap = {
      'N': 0.0, 'NNE': 22.5, 'NE': 45.0, 'ENE': 67.5,
      'E': 90.0, 'ESE': 112.5, 'SE': 135.0, 'SSE': 157.5,
      'S': 180.0, 'SSW': 202.5, 'SW': 225.0, 'WSW': 247.5,
      'W': 270.0, 'WNW': 292.5, 'NW': 315.0, 'NNW': 337.5,
    };
    final deg = degMap[dir.toUpperCase()] ?? 0.0;
    return deg * math.pi / 180;
  }

  static const _cardinalStyle = TextStyle(
    fontSize: 7,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  @override
  Widget build(BuildContext context) {
    final dir = direction ?? 'N';

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Círculo de fundo
          Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.background,
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.22),
              ),
            ),
          ),

          // Labels cardinais
          Positioned(
            top: 2,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'N',
                style: _cardinalStyle.copyWith(color: AppColors.accent),
              ),
            ),
          ),
          Positioned(
            bottom: 2,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'S',
                style: _cardinalStyle.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
          Positioned(
            right: 3,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                'E',
                style: _cardinalStyle.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
          Positioned(
            left: 3,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                'W',
                style: _cardinalStyle.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),

          // Agulha rotativa
          Transform.rotate(
            angle: _dirToRadians(dir),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Metade norte — cyan com glow
                Container(
                  width: 2,
                  height: 11,
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(2)),
                    color: AppColors.accent,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.55),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
                // Metade sul — apagada
                Container(
                  width: 2,
                  height: 11,
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(bottom: Radius.circular(2)),
                    color: AppColors.textSecondary.withValues(alpha: 0.28),
                  ),
                ),
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat(period: 4000.ms))
              .shimmer(
                duration: 1400.ms,
                color: AppColors.accent.withValues(alpha: 0.45),
              ),

          // Pivô central
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
