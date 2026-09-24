import 'package:flutter/material.dart';

import '../../../../core/l10n/aqx_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/weather_data.dart';
import 'greeting_header.dart';
import 'oracle_index_gauge.dart';
import 'solunar_progress_bar.dart';

/// Hero de decisão piscatória — foto local + índice + métricas + previsão 5 dias.
class WeatherCard extends StatelessWidget {
  const WeatherCard({
    super.key,
    required this.weather,
    required this.t,
    required this.updatedAt,
    required this.greetingLine,
    this.onLocationTap,
    this.onRefresh,
  });

  final WeatherData weather;
  final AqxL10n t;
  final DateTime updatedAt;
  final String greetingLine;
  final VoidCallback? onLocationTap;
  final VoidCallback? onRefresh;

  static const _heroImage = 'assets/marketing/catches/home_hero_fishing.png';

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

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

  static Color _scoreColor(int score) {
    if (score >= 65) return AppColors.green;
    if (score >= 45) return AppColors.amber;
    return const Color(0xFFFF4C4C);
  }

  static String _scoreLabel(AqxL10n t, int score) {
    if (score >= 65) return t.es ? 'BUENA' : 'BOA';
    if (score >= 45) return t.homeIndexModerate;
    return t.es ? 'DÉBIL' : 'FRACA';
  }

  @override
  Widget build(BuildContext context) {
    final hasTide = weather.hasTide;
    final tideSubValue = weather.tideRising
        ? (t.es ? '↑ Enchente' : '↑ Enchente')
        : (t.es ? '↓ Vazante' : '↓ Vazante');
    final tideColor = weather.tideRising ? AppColors.accent : AppColors.amber;
    final indexLabel = indexGaugeLabel(t, weather.solunarScore);
    final indexColor = _scoreColor(weather.solunarScore);
    final verdict = homeFishingVerdict(t, weather.solunarScore);

    final highTideLabel = weather.highTideTime != null
        ? _formatTime(weather.highTideTime!)
        : '—';
    final highTideValue = weather.highTideHeightM != null
        ? '${weather.highTideHeightM!.toStringAsFixed(1)} m'
        : '—';

    final pressureValue = weather.pressure != null
        ? '${weather.pressure} hPa'
        : '—';
    final pressureSub = weather.pressureTrendDown == null
        ? null
        : (weather.pressureTrendDown! ? '↓' : '↑');

    final sunsetLabel =
        weather.sunset != null ? _formatTime(weather.sunset!) : '—';

    final rec = weather.recommendation;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage(_heroImage),
            fit: BoxFit.cover,
            onError: (_, __) {},
          ),
          color: const Color(0xFF071428),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.5),
                Colors.black.withValues(alpha: 0.84),
                const Color(0xFF000814).withValues(alpha: 0.97),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        greetingLine,
                        style: AppTextStyles.orbitron(18, fw: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _LocationPill(
                      location: weather.location,
                      onTap: onLocationTap,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _DecisionVerdictBar(verdict: verdict),
                const SizedBox(height: 12),
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
                    Column(
                      children: [
                        OracleIndexGauge(
                          score: weather.solunarScore,
                          label: '',
                          size: 88,
                        ),
                        Text(
                          '${t.homeIndexLabel} $indexLabel'.toUpperCase(),
                          style: AppTextStyles.ibmSans(
                            8,
                            fw: FontWeight.w700,
                            ls: 0.4,
                            color: indexColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _HeroMetric(
                        icon: Icons.water_drop_outlined,
                        label: t.es ? 'TEMP. AGUA' : 'TEMP. ÁGUA',
                        value: weather.waterTempC != null
                            ? '${weather.waterTempC!.round()}°C'
                            : '—',
                      ),
                    ),
                    Expanded(
                      child: _HeroMetric(
                        icon: Icons.vertical_align_top_rounded,
                        label: t.es ? 'PLEAMAR' : 'PREIA-MAR',
                        value: highTideLabel,
                        sub: highTideValue,
                        subColor: AppColors.accent,
                      ),
                    ),
                    Expanded(
                      child: _HeroMetric(
                        icon: Icons.speed_rounded,
                        label: t.es ? 'PRESION' : 'PRESSÃO',
                        value: pressureValue,
                        sub: pressureSub,
                        subColor: weather.pressureTrendDown == true
                            ? AppColors.amber
                            : AppColors.green,
                      ),
                    ),
                    Expanded(
                      child: _HeroMetric(
                        icon: Icons.wb_twilight_rounded,
                        label: t.es ? 'PUESTA SOL' : 'PÔR SOL',
                        value: sunsetLabel,
                      ),
                    ),
                  ],
                ),
                if (weather.fiveDayForecast.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    t.es ? 'PRÓXIMOS 5 DÍAS' : 'PRÓXIMOS 5 DIAS',
                    style: AppTextStyles.ibmSans(10, fw: FontWeight.w700, ls: 0.8),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var i = 0; i < weather.fiveDayForecast.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: _DayChip(
                            chip: weather.fiveDayForecast[i],
                            label: _scoreLabel(t, weather.fiveDayForecast[i].score),
                            color: _scoreColor(weather.fiveDayForecast[i].score),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                if (rec != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.track_changes_rounded,
                            size: 18, color: AppColors.accent.withValues(alpha: 0.9)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.es ? 'RECOMENDACIÓN AHORA' : 'RECOMENDAÇÃO AGORA',
                                style: AppTextStyles.ibmSans(
                                  9,
                                  fw: FontWeight.w700,
                                  ls: 0.6,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                rec.headline,
                                style: AppTextStyles.ibmSans(13, fw: FontWeight.w700),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                rec.detail,
                                style: AppTextStyles.ibmSans(11, color: AppColors.textSecondary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                rec.footer,
                                style: AppTextStyles.ibmSans(
                                  10,
                                  color: AppColors.accent.withValues(alpha: 0.85),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.homeSectionActivity,
                        style: AppTextStyles.orbitron(12, fw: FontWeight.w700, ls: 0.3),
                      ),
                    ),
                    Text(
                      '${t.homeUpdated} ${_formatTime(updatedAt)}',
                      style: AppTextStyles.ibmSans(10, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onRefresh,
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 16,
                        color: AppColors.textPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SolunarProgressBar(
                  score: weather.solunarScore,
                  qualityLabel: '',
                  showScoreBadge: false,
                  weakLabel: t.es ? 'DÉBIL' : 'FRACA',
                  excellentLabel: 'EXCELENTE',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.location, this.onTap});

  final String location;
  final VoidCallback? onTap;

  String get _display =>
      location.replaceAll(' · ', ', ').replaceAll(' | ', ', ');

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.place_outlined, size: 14, color: AppColors.accent),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  _display,
                  style: AppTextStyles.ibmSans(11, fw: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DecisionVerdictBar extends StatelessWidget {
  const _DecisionVerdictBar({required this.verdict});

  final HomeFishingVerdict verdict;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: verdict.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: verdict.color.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Icon(verdict.icon, color: verdict.color, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verdict.headline,
                  style: AppTextStyles.orbitron(13, fw: FontWeight.w700, color: verdict.color),
                ),
                const SizedBox(height: 2),
                Text(
                  verdict.subtitle,
                  style: AppTextStyles.ibmSans(11, color: AppColors.textPrimary.withValues(alpha: 0.88)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.chip,
    required this.label,
    required this.color,
  });

  final HomeDayForecastChip chip;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: chip.isHighlighted
            ? AppColors.accent.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: chip.isHighlighted
              ? AppColors.accent.withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Text(chip.dayLabel, style: AppTextStyles.ibmSans(9, fw: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            '${chip.score}',
            style: AppTextStyles.orbitron(16, fw: FontWeight.w900),
          ),
          Text(
            label,
            style: AppTextStyles.ibmSans(8, fw: FontWeight.w700, color: color),
          ),
        ],
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
