import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/l10n/aqx_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/aqua_card.dart';
import '../../domain/entities/weather_data.dart';
import 'location_header.dart';
import 'solunar_progress_bar.dart';

/// Módulo de Condições Actuais — layout compacto de linha única.
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
    final tideSubValue = weather.tideRising
        ? (t.es ? '↑ Creciente' : '↑ Enchente')
        : (t.es ? '↓ Vaciante' : '↓ Vazante');
    final tideColor = weather.tideRising ? AppColors.accent : AppColors.amber;

    return AquaCard(
      borderRadius: 16,
      borderAlpha: 0.18,
      padding: const EdgeInsets.fromLTRB(AppSpacing.xs, 6, AppSpacing.xs, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Localização + hora ────────────────────────────────────────
          LocationHeader(location: weather.location),
          const SizedBox(height: 4),
          Divider(height: 1, color: AppColors.accent.withValues(alpha: 0.12)),
          const SizedBox(height: 5),

          // ── Temperatura + condição (linha única) ──────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${weather.temperature.round()}',
                      style: AppTextStyles.orbitron(26, fw: FontWeight.w700),
                    ),
                    Text(
                      '°C',
                      style: AppTextStyles.orbitron(
                        13,
                        fw: FontWeight.w400,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        weather.condition,
                        style: AppTextStyles.ibmSans(
                          10,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                weather.conditionIcon,
                style: const TextStyle(fontSize: 22),
              ),
            ],
          ),

          const SizedBox(height: 5),
          Divider(height: 1, color: AppColors.accent.withValues(alpha: 0.12)),
          const SizedBox(height: 5),

          // ── 4 métricas alinhadas numa linha ──────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Vento — direcção como sub-valor (sem bússola inline)
              Expanded(
                child: _CompactMetric(
                  icon: const Icon(
                    Icons.air_rounded,
                    size: 16,
                    color: AppColors.accent,
                  ),
                  label: t.homeStatWind,
                  value: '${weather.windSpeed.round()} km/h',
                  subValue: weather.windDir,
                ),
              ),
              _vDiv(),
              // Ondas
              Expanded(
                child: _CompactMetric(
                  icon: const Icon(
                    Icons.waves_rounded,
                    size: 16,
                    color: AppColors.accent,
                  ),
                  label: t.homeStatWaves,
                  value: '≈ ${weather.waveHeight.toStringAsFixed(1)} m',
                ),
              ),
              _vDiv(),
              // Maré
              Expanded(
                child: AnimatedOpacity(
                  opacity: hasTide ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: _CompactMetric(
                    icon: Icon(
                      weather.tideRising
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 16,
                      color: tideColor,
                    ),
                    label: t.homeStatTide,
                    value: '≈ ${weather.tideHeight.toStringAsFixed(1)} m',
                    subValue: tideSubValue,
                    subValueColor: tideColor,
                  ),
                ),
              ),
              _vDiv(),
              // Lua
              Expanded(
                child: _CompactMetric(
                  icon: const Icon(
                    Icons.nightlight_round,
                    size: 16,
                    color: AppColors.amber,
                  ),
                  label: t.homeStatMoon,
                  value: weather.moonPhase,
                  subValue: _solunarBadgeLabel(weather.solunarScore),
                  subValueColor: _solunarBadgeColor(weather.solunarScore),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),
          Divider(height: 1, color: AppColors.accent.withValues(alpha: 0.10)),
          const SizedBox(height: 4),

          // ── Barra solunar ─────────────────────────────────────────────
          SolunarProgressBar(
            score: weather.solunarScore,
            qualityLabel: t.scoreLabel(weather.solunarScore),
            weakLabel: t.es ? 'DÉBIL' : 'FRACA',
            excellentLabel: 'EXCELENTE',
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .slideY(begin: 0.04, end: 0, duration: 500.ms, curve: Curves.easeOutCubic);
  }

  /// Divisor vertical entre colunas de métricas.
  static Widget _vDiv() => Container(
        width: 0.5,
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: AppColors.accent.withValues(alpha: 0.15),
      );
}

// ── Métrica compacta (coluna única sem bordas) ────────────────────────────────

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
    this.subValueColor,
  });

  final Widget icon;
  final String label;
  final String value;
  final String? subValue;
  final Color? subValueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        icon,
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: AppTextStyles.ibmSans(
            9,
            color: AppColors.textSecondary,
            fw: FontWeight.w600,
            ls: 0.3,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTextStyles.orbitron(13, fw: FontWeight.w700),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subValue != null) ...[
          const SizedBox(height: 2),
          Text(
            subValue!,
            style: AppTextStyles.ibmSans(
              9,
              color: subValueColor ?? AppColors.accent,
              fw: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
