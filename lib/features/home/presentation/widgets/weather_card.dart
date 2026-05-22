import 'package:flutter/material.dart';

import '../../../../core/l10n/aqx_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/aqua_card.dart';
import '../../domain/entities/weather_data.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key, required this.weather, required this.t});

  final WeatherData weather;
  final AqxL10n t;

  static String _solunarRating(int score) {
    if (score >= 70) return 'Major';
    if (score >= 40) return 'Minor';
    return 'Inativo';
  }

  static Widget _buildSolunarBadge(String rating) {
    final color = rating == 'Major'
        ? const Color(0xFF39FF14)
        : rating == 'Minor'
            ? const Color(0xFFF3C64D)
            : Colors.white38;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '◉ SOLUNAR $rating',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: AquaCard(
        borderRadius: 16,
        borderAlpha: 0.0,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 18, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        weather.location,
                        style: AppTextStyles.ibmSans(13, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(weather.conditionIcon, style: const TextStyle(fontSize: 48)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${weather.temperature.round()}°C', style: AppTextStyles.orbitron(42, fw: FontWeight.w700)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  weather.condition,
                  style: AppTextStyles.ibmSans(14, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.accent.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: _StatCol(label: t.homeStatWind, icon: Icons.air_rounded, value: '${weather.windSpeed.round()} km/h ${weather.windDir ?? ''}'.trim()),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  child: _StatCol(label: t.homeStatWaves, icon: Icons.waves_rounded, value: '${weather.waveHeight.toStringAsFixed(1)} m'),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  child: _StatCol(
                    label: t.homeStatTide,
                    icon: weather.tideRising ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    value: '${weather.tideHeight.toStringAsFixed(1)} m',
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 96,
                  child: Column(
                    children: [
                      _StatCol(
                        label: t.homeStatMoon,
                        icon: Icons.nightlight_round,
                        value: '${weather.moonIcon} ${weather.moonPhase}',
                        rawIcon: false,
                      ),
                      const SizedBox(height: 6),
                      _buildSolunarBadge(_solunarRating(weather.solunarScore)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 76,
                  child: _StatCol(
                    label: 'Pressão',
                    icon: Icons.speed_rounded,
                    value: '${weather.pressure ?? 1021} mb',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(height: 1, color: AppColors.accent.withValues(alpha: 0.10)),
          const SizedBox(height: 10),
          _SolunarBar(score: weather.solunarScore, label: t.homeStatSolunar, qualityLabel: t.scoreLabel(weather.solunarScore)),
        ],
      ),
      ),
    );
  }
}

class _SolunarBar extends StatelessWidget {
  const _SolunarBar({
    required this.score,
    required this.label,
    required this.qualityLabel,
  });

  final int score;
  final String label;
  final String qualityLabel;

  Color get _barColor {
    if (score >= 75) return const Color(0xFFF3C64D);
    if (score >= 50) return AppColors.accent;
    return AppColors.accent.withValues(alpha: 0.45);
  }

  @override
  Widget build(BuildContext context) {
    final fraction = (score / 100).clamp(0.0, 1.0);
    return Row(
      children: [
        Icon(Icons.auto_awesome_rounded, size: 13, color: _barColor),
        const SizedBox(width: 5),
        Text(
          label.toUpperCase(),
          style: AppTextStyles.ibmSans(10, color: AppColors.textSecondary, fw: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 5,
              backgroundColor: AppColors.accent.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(_barColor),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$score',
          style: AppTextStyles.orbitron(13, fw: FontWeight.w700),
        ),
        const SizedBox(width: 4),
        Text(
          qualityLabel,
          style: AppTextStyles.ibmSans(10, color: _barColor, fw: FontWeight.w600),
        ),
      ],
    );
  }
}

class _StatCol extends StatelessWidget {
  const _StatCol({
    required this.label,
    required this.icon,
    required this.value,
    this.rawIcon = true,
  });

  final String label;
  final IconData icon;
  final String value;
  final bool rawIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.ibmSans(11, color: AppColors.textSecondary, fw: FontWeight.w500)),
        const SizedBox(height: 4),
        if (rawIcon)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.accent.withValues(alpha: 0.85)),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.ibmSans(13, fw: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          )
        else
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppTextStyles.ibmSans(12, fw: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
