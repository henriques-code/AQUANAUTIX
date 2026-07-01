import 'package:flutter/material.dart';

import '../../../../core/l10n/aqx_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/weather_data.dart';
import 'greeting_header.dart';
import 'oracle_index_gauge.dart';

/// Hero de condições — foto de fundo + gauge circular (mockup Início).
class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key, required this.weather, required this.t});

  final WeatherData weather;
  final AqxL10n t;

  static const _heroImage =
      'https://images.unsplash.com/photo-1555881400-74d7acaacd8b?w=800&q=80';

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
    final hasTide = weather.hasTide;
    final tideSubValue = weather.tideRising
        ? (t.es ? '↑ Enchente' : '↑ Enchente')
        : (t.es ? '↓ Vazante' : '↓ Vazante');
    final tideColor = weather.tideRising ? AppColors.accent : AppColors.amber;
    final indexLabel = indexGaugeLabel(t, weather.solunarScore);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              _heroImage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A2840), Color(0xFF071428)],
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${weather.temperature.round()}',
                                  style: AppTextStyles.orbitron(42, fw: FontWeight.w700),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    '°C',
                                    style: AppTextStyles.orbitron(
                                      16,
                                      fw: FontWeight.w400,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  weather.conditionIcon,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    weather.condition,
                                    style: AppTextStyles.ibmSans(
                                      12,
                                      color: AppColors.textPrimary.withValues(alpha: 0.9),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      OracleIndexGauge(
                        score: weather.solunarScore,
                        label: '${t.homeIndexLabel} $indexLabel',
                        size: 88,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroMetric(
                          icon: Icons.air_rounded,
                          label: t.homeStatWind,
                          value: '${weather.windSpeed.round()} km/h',
                          sub: weather.windDir ?? '—',
                        ),
                      ),
                      Expanded(
                        child: _HeroMetric(
                          icon: Icons.waves_rounded,
                          label: t.homeStatWaves,
                          value: '≈ ${weather.waveHeight.toStringAsFixed(1)} m',
                        ),
                      ),
                      Expanded(
                        child: Opacity(
                          opacity: hasTide ? 1 : 0.35,
                          child: _HeroMetric(
                            icon: weather.tideRising
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            label: t.homeStatTide,
                            value: '≈ ${weather.tideHeight.toStringAsFixed(1)} m',
                            sub: tideSubValue,
                            subColor: tideColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _HeroMetric(
                          icon: Icons.nightlight_round,
                          label: t.homeStatMoon,
                          value: weather.moonPhase,
                          sub: _solunarBadgeLabel(weather.solunarScore),
                          subColor: _solunarBadgeColor(weather.solunarScore),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
    this.subColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  final Color? subColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.accent),
        const SizedBox(height: 3),
        Text(
          label.toUpperCase(),
          style: AppTextStyles.ibmSans(8, color: AppColors.textSecondary, ls: 0.2),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.ibmSans(10, fw: FontWeight.w700),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (sub != null) ...[
          Text(
            sub!,
            style: AppTextStyles.ibmSans(
              8,
              color: subColor ?? AppColors.textSecondary,
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
