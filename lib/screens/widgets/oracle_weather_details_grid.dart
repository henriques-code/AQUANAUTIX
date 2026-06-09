import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/tides/weather_details_snapshot.dart';

/// Grelha «Detalhes de meteorologia» — cartões brancos (referência preview.webp).
class OracleWeatherDetailsGrid extends StatefulWidget {
  const OracleWeatherDetailsGrid({
    super.key,
    required this.data,
    this.loading = false,
    this.loadFailed = false,
    this.onRetry,
    this.collapsible = true,
    this.initiallyExpanded = false,
  });

  final WeatherDetailsSnapshot? data;
  final bool loading;
  final bool loadFailed;
  final VoidCallback? onRetry;
  final bool collapsible;
  final bool initiallyExpanded;

  static const cardBg = Color(0xFFFFFFFF);
  static const titleColor = Color(0xFF2C3E50);
  static const bodyColor = Color(0xFF7A8B99);
  static const valueColor = Color(0xFF1A1A1A);
  static const chartBlue = Color(0xFF5B9BD5);
  static const chartLine = Color(0xFF4FC3F7);

  @override
  State<OracleWeatherDetailsGrid> createState() =>
      OracleWeatherDetailsGridState();
}

class OracleWeatherDetailsGridState extends State<OracleWeatherDetailsGrid> {
  late bool _expanded;

  void expandAccordion() {
    if (!mounted) return;
    if (!_expanded) setState(() => _expanded = true);
  }

  @override
  void initState() {
    super.initState();
    _expanded = !widget.collapsible || widget.initiallyExpanded;
  }

  static const _titleColor = OracleWeatherDetailsGrid.titleColor;
  static const _bodyColor = OracleWeatherDetailsGrid.bodyColor;
  static const _valueColor = OracleWeatherDetailsGrid.valueColor;
  static const _chartBlue = OracleWeatherDetailsGrid.chartBlue;
  static const _chartLine = OracleWeatherDetailsGrid.chartLine;

  TextStyle _body(double size, {Color? color, FontWeight? fw}) =>
      GoogleFonts.ibmPlexSans(
        fontSize: size,
        fontWeight: fw ?? FontWeight.w400,
        color: color ?? _bodyColor,
        height: 1.3,
      );

  TextStyle _value(double size, {FontWeight fw = FontWeight.w700}) =>
      GoogleFonts.ibmPlexSans(
        fontSize: size,
        fontWeight: fw,
        color: _valueColor,
        height: 1.0,
      );

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final timeLabel = d != null
        ? '${d.fetchedAt.hour.toString().padLeft(2, '0')}:'
            '${d.fetchedAt.minute.toString().padLeft(2, '0')}'
        : '--:--';

    if (widget.collapsible) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Meteorologia completa · $timeLabel',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.accent,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: _gridBody(d, timeLabel),
              ),
          ],
        ),
      );
    }

    return _gridBody(d, timeLabel, showHeader: true);
  }

  Widget _gridBody(
    WeatherDetailsSnapshot? d,
    String timeLabel, {
    bool showHeader = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
          Text(
            'Detalhes de meteorologia $timeLabel',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (widget.loading && d == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 2,
              ),
            ),
          )
        else if (d == null)
          _emptyState(widget.loadFailed)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 600 ? 4 : 2;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: cols == 4 ? 0.82 : 0.68,
                children: _cards(d),
              );
            },
          ),
      ],
    );
  }

  Widget _emptyState(bool failed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(
            failed ? Icons.cloud_off_rounded : Icons.cloud_download_rounded,
            color: AppColors.textSecondary,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            failed
                ? 'Não foi possível carregar a meteorologia.'
                : 'Meteorologia a preparar…',
            style: _body(13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Puxa para baixo para actualizar',
            style: _body(11, color: AppColors.accent.withValues(alpha: 0.85)),
          ),
          if (widget.onRetry != null) ...[
            const SizedBox(height: 10),
            TextButton(onPressed: widget.onRetry, child: Text('Tentar novamente', style: _body(13, color: AppColors.accent, fw: FontWeight.w600))),
          ],
        ],
      ),
    );
  }

  List<Widget> _cards(WeatherDetailsSnapshot d) {
    final tempTrend = WeatherDetailsSnapshot.tempTrendLabel(d.tempSparkline);
    final presTrend = WeatherDetailsSnapshot.pressureTrendLabel(d.pressureSparkline);
    final windBf = WeatherDetailsSnapshot.beaufortPt(d.windSpeedKmh);
    final cloudLbl = WeatherDetailsSnapshot.cloudLabelPt(d.cloudPct);
    final uvLbl = WeatherDetailsSnapshot.uvLabelPt(d.uvIndex);
    final aqiLbl = WeatherDetailsSnapshot.aqiLabelPt(d.aqi);
    final pollenLbl = WeatherDetailsSnapshot.pollenLabelPt(d.pollenGrass);
    final tidePhase = d.tidePhasePt.isNotEmpty
        ? d.tidePhasePt
        : WeatherDetailsSnapshot.tidePhaseFromTrend(
            d.tideTrendPt,
            d.tideSparkline,
          );
    final currentLbl = WeatherDetailsSnapshot.currentLabelPt(d.oceanCurrentMs);
    final currentKmh = WeatherDetailsSnapshot.currentKmh(d.oceanCurrentMs);
    final timeStr =
        '${d.fetchedAt.hour.toString().padLeft(2, '0')}:${d.fetchedAt.minute.toString().padLeft(2, '0')}';

    return [
      // ── Temperatura ──────────────────────────────────────────────
      _RefCard(
        title: 'Temperatura',
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 44,
              child: CustomPaint(
                painter: _SparklinePainter(d.tempSparkline, _chartLine, filled: true),
                size: const Size(double.infinity, 44),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Text(
                d.airTempC != null ? '${d.airTempC!.round()}°' : '—',
                style: _value(32),
              ),
            ),
          ],
        ),
        status: tempTrend,
        statusKind: _StatusKind.yellow,
        description:
            'A temperatura está $tempTrend${d.airTempC != null ? ' aos ${d.airTempC!.round()}°' : ''}. Amanhã estará mais quente.',
      ),

      // ── Sensação térmica ─────────────────────────────────────────
      _RefCard(
        title: 'Sensação térmica',
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 40,
              child: CustomPaint(
                painter: _SparklinePainter(d.tempSparkline, _chartBlue),
                size: const Size(double.infinity, 40),
              ),
            ),
            Positioned(
              left: 0,
              bottom: 14,
              child: Text(
                d.feelsLikeC != null ? '${d.feelsLikeC!.round()}°' : '—',
                style: _value(30),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 18,
              child: Text(
                d.airTempC != null ? '${d.airTempC!.round()}°' : '',
                style: _value(14, fw: FontWeight.w500),
              ),
            ),
          ],
        ),
        status: (d.feelsLikeC ?? 0) > (d.airTempC ?? 0) + 2 ? 'Quente' : 'Normal',
        statusKind: _StatusKind.blueInfo,
        description:
            'A humidade faz com que pareça mais quente do que a temperatura real.',
      ),

      // ── Nebulosidade total ───────────────────────────────────────
      _RefCard(
        title: 'Nebulosidade total',
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 82,
              width: 82,
              child: CustomPaint(
                painter: _CloudCoverPainter(
                  cloudPct: d.cloudPct ?? 0,
                  isClear: cloudLbl == 'Sol',
                ),
                child: Center(
                  child: Text(
                    cloudLbl == 'Sol' ? 'Sol' : '${d.cloudPct?.round() ?? 0}%',
                    style: _value(cloudLbl == 'Sol' ? 16 : 20),
                  ),
                ),
              ),
            ),
          ],
        ),
        status: '$cloudLbl (${d.cloudPct?.round() ?? 0}%)',
        statusKind: cloudLbl == 'Sol' ? _StatusKind.orange : _StatusKind.yellow,
        description:
            'O céu irá limpar-se. Amanhã haverá menos nebulosidade.',
      ),

      // ── Precipitação ─────────────────────────────────────────────
      _RefCard(
        title: 'Precipitação',
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${(d.precipNext24hMm ?? 0).toStringAsFixed(0)} mm',
              style: _value(26),
              textAlign: TextAlign.center,
            ),
            Text(
              'Nas próximas 24h',
              style: _body(10, color: const Color(0xFF0277BD), fw: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: CustomPaint(
                  painter: _PrecipChartPainter(mm: d.precipNext24hMm ?? 0),
                ),
              ),
            ),
          ],
        ),
        status: (d.precipNext24hMm ?? 0) < 0.5 ? 'Sem Precipitação' : 'Chuva prevista',
        statusKind: _StatusKind.yellow,
        description: (d.precipNext24hMm ?? 0) < 0.5
            ? 'Não se prevê chuva nas próximas 24 horas.'
            : 'Prevê-se ${d.precipNext24hMm!.toStringAsFixed(1)} mm de chuva.',
      ),

      // ── Vento ────────────────────────────────────────────────────
      _RefCard(
        title: 'Vento',
        body: LayoutBuilder(
          builder: (context, constraints) {
            final compass = math.min(72.0, constraints.maxWidth * 0.52);
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: compass,
                        height: compass,
                        child: CustomPaint(
                          painter: _CompassPainter(d.windDirDeg ?? 0),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Velocidade', style: _body(9)),
                          Text(
                            '${d.windSpeedKmh?.round() ?? '—'} km/h',
                            style: _value(13),
                          ),
                          const SizedBox(height: 4),
                          Text('Rajadas', style: _body(9)),
                          Text(
                            '${d.windGustKmh?.round() ?? '—'} km/h',
                            style: _value(13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        status: 'Força: ${windBf.force} (${windBf.label})',
        statusKind: _StatusKind.yellow,
        description:
            'O vento médio é de ${d.windSpeedKmh?.round() ?? '—'} km/h de ${WeatherDetailsSnapshot.windCardinalPt(d.windDirDeg)}.',
      ),

      // ── Humidade ─────────────────────────────────────────────────
      _RefCard(
        title: 'Humidade',
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 50,
              width: double.infinity,
              child: CustomPaint(
                painter: _HumidityBarsPainter(
                  values: d.humiditySparkline.isNotEmpty
                      ? d.humiditySparkline
                      : [d.humidityPct ?? 50],
                  current: d.humidityPct ?? 50,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${d.humidityPct?.round() ?? '—'}% Humidade Relativa',
              style: _value(12),
              textAlign: TextAlign.center,
            ),
            Text(
              '${d.dewPointC?.round() ?? '—'}° Ponto de orvalho',
              style: _body(10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        status: 'Normal',
        statusKind: _StatusKind.yellow,
        description:
            'A humidade actual é ${d.humidityPct?.round() ?? '—'}%, dentro do esperado.',
      ),

      // ── UV ───────────────────────────────────────────────────────
      _RefCard(
        title: 'UV',
        body: SizedBox(
          height: 58,
          child: CustomPaint(
            painter: _SemiGaugePainter(
              value: ((d.uvIndex ?? 0) / 11).clamp(0.0, 1.0),
              display: d.uvIndex?.round().toString() ?? '—',
            ),
            child: Align(
              alignment: const Alignment(0, 0.35),
              child: Text(
                d.uvIndex?.round().toString() ?? '—',
                style: _value(16),
              ),
            ),
          ),
        ),
        status: uvLbl,
        statusKind: _StatusKind.yellow,
        description: d.uvMaxTomorrow != null
            ? 'O nível máximo de UV amanhã será ${d.uvMaxTomorrow!.round()}.'
            : 'Índice UV na hora actual.',
      ),

      // ── IQA ──────────────────────────────────────────────────────
      _RefCard(
        title: 'IQA',
        body: LayoutBuilder(
          builder: (context, constraints) {
            final size = math.min(constraints.maxWidth, constraints.maxHeight) * 0.92;
            return Center(
              child: SizedBox(
                width: size,
                height: size,
                child: CustomPaint(
                  painter: _IqaRingPainter(
                    value: ((d.aqi ?? 0) / 100).clamp(0.0, 1.0),
                    aqi: d.aqi ?? 0,
                  ),
                  child: Center(
                    child: Text(
                      d.aqi?.toString() ?? '—',
                      style: _value(size * 0.28),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        status: aqiLbl,
        statusKind: _StatusKind.blueInfo,
        description: 'A qualidade do ar está a piorar devido ao ozono (O₃).',
      ),

      // ── Pólen ────────────────────────────────────────────────────
      _RefCard(
        title: 'Pólen',
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 52,
              width: double.infinity,
              child: CustomPaint(
                painter: _SemiGaugePainter(
                  value: ((d.pollenGrass ?? 0) / 100).clamp(0.0, 1.0),
                  display: d.pollenGrass?.round().toString() ?? '—',
                  pollen: true,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      d.pollenGrass?.round().toString() ?? '—',
                      style: _value(16),
                    ),
                  ),
                ),
              ),
            ),
            Text(
              'Alergia principal: Relva',
              style: _body(9),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        status: pollenLbl,
        statusKind: _StatusKind.yellow,
        description: 'O nível de pólen de relva será $pollenLbl amanhã.',
      ),

      // ── Visibilidade ─────────────────────────────────────────────
      _RefCard(
        title: 'Visibilidade',
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 44,
              width: double.infinity,
              child: CustomPaint(
                painter: _VisibilityPyramidPainter(d.visibilityKm ?? 10),
                size: const Size(double.infinity, 44),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${d.visibilityKm?.toStringAsFixed(0) ?? '—'} km',
              style: _value(24),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        status: (d.visibilityKm ?? 0) >= 8 ? 'Excelente' : 'Moderada',
        statusKind: _StatusKind.blueInfo,
        description:
            'A visibilidade será ${(d.visibilityKm ?? 0) >= 8 ? 'semelhante' : 'ligeiramente inferior'} amanhã.',
      ),

      // ── Pressão ──────────────────────────────────────────────────
      _RefCard(
        title: 'Pressão',
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 36,
              child: CustomPaint(
                painter: _SparklinePainter(d.pressureSparkline, _chartBlue),
                size: const Size(double.infinity, 36),
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${d.pressureHpa?.round() ?? '—'} mb $timeStr',
                    style: _value(12),
                  ),
                  Text('(Agora)', style: _body(9)),
                ],
              ),
            ),
          ],
        ),
        status: presTrend,
        statusKind: _StatusKind.blueInfo,
        description: 'A pressão irá subir lentamente nas próximas 3 horas.',
      ),

      // ── Sol ──────────────────────────────────────────────────────
      _RefCard(
        title: 'Sol',
        body: SizedBox(
          height: 72,
          child: CustomPaint(
            painter: _SunPathPainter(
              sunrise: d.sunrise,
              sunset: d.sunset,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _daylightLong(d.sunrise, d.sunset),
                  style: _body(10, color: _titleColor, fw: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_fmtTime(d.sunrise)} Nascer…', style: _body(8)),
                    Text('${_fmtTime(d.sunset)} Pôr do…', style: _body(8)),
                  ],
                ),
              ],
            ),
          ),
        ),
        hideStatus: true,
        description: '',
      ),

      // ── Lua (trajeto) ────────────────────────────────────────────
      _RefCard(
        title: 'Lua',
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 86,
              width: double.infinity,
              child: CustomPaint(
                painter: _MoonPathPainter(
                  phase: d.moonPct / 100.0,
                  illumination: d.moonPct / 100.0,
                ),
              ),
            ),
            Text(
              '${d.moonPct}% iluminada',
              style: _body(10, color: const Color(0xFF3949AB), fw: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            if (d.moonPhaseLabel.isNotEmpty)
              Text(
                d.moonPhaseLabel,
                style: _body(9, color: const Color(0xFF7986CB)),
                textAlign: TextAlign.center,
              ),
          ],
        ),
        hideStatus: true,
        description: '',
      ),

      // ── Fase da Lua ──────────────────────────────────────────────
      _RefCard(
        title: 'Fase da Lua',
        body: LayoutBuilder(
          builder: (context, constraints) {
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: SizedBox(
                width: constraints.maxWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: CustomPaint(
                        painter: _MoonCrescentPainter(d.moonPct / 100.0),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${d.moonPct}%', style: _value(20)),
                    Text('Fase da lua', style: _body(9)),
                  ],
                ),
              ),
            );
          },
        ),
        status: d.moonPhaseLabel.isNotEmpty ? d.moonPhaseLabel : 'Lua',
        statusKind: _StatusKind.yellow,
        description: 'Fase lunar ${d.moonPct}% iluminada.',
      ),

      // ── Marés ────────────────────────────────────────────────────
      _RefCard(
        title: 'Marés',
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isRising = tidePhase == 'Enchente';
            final isFalling = tidePhase == 'Vazante';
            final phaseColor = isRising
                ? const Color(0xFF00C853)
                : isFalling
                    ? const Color(0xFFFF6D00)
                    : const Color(0xFF5C6BC0);
            final phaseLabel = isRising
                ? '↑ Enchente'
                : isFalling
                    ? '↓ Vazante'
                    : tidePhase;
            final heightVal = d.tideHeightM;
            final heightStr = heightVal != null && heightVal != 0
                ? '${heightVal.toStringAsFixed(2)} m'
                : '—';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(heightStr, style: _value(15)),
                    if (d.tideRangeM != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        'Amp. ${d.tideRangeM!.toStringAsFixed(1)} m',
                        style: _body(9, color: const Color(0xFF607D8B)),
                      ),
                    ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: phaseColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: phaseColor.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        phaseLabel,
                        style: _body(8, color: phaseColor, fw: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Expanded(
                  child: CustomPaint(
                    painter: _TideChartPainter(
                      phase: tidePhase,
                      sparkline: d.tideSparkline,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        status: tidePhase,
        statusKind: tidePhase == 'Enchente'
            ? _StatusKind.blueInfo
            : tidePhase == 'Vazante'
                ? _StatusKind.orange
                : _StatusKind.yellow,
        description: d.tideRangeM != null
            ? 'Amplitude ~${d.tideRangeM!.toStringAsFixed(1)} m · Praia exposta / Mar alto.'
            : 'Cota MSL na costa · praia e mar em fase ${tidePhase.toLowerCase()}.',
      ),

      // ── Correntes ────────────────────────────────────────────────
      _RefCard(
        title: 'Correntes',
        body: LayoutBuilder(
          builder: (context, constraints) {
            final size = math.min(constraints.maxWidth, constraints.maxHeight);
            return Center(
              child: SizedBox(
                width: size,
                height: size * 0.92,
                child: CustomPaint(
                  painter: _OceanCurrentPainter(
                    velocityMs: d.oceanCurrentMs ?? 0,
                    dirDeg: d.oceanCurrentDirDeg ?? 0,
                    sparkline: d.currentSparkline,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentKmh != null
                              ? '${currentKmh.toStringAsFixed(1)} km/h'
                              : '—',
                          style: _value(18),
                        ),
                        Text(
                          WeatherDetailsSnapshot.windCardinalPt(
                            d.oceanCurrentDirDeg,
                          ),
                          style: _body(
                            10,
                            color: const Color(0xFF00E5FF),
                            fw: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        status: currentLbl,
        statusKind: _StatusKind.blueInfo,
        description:
            'Corrente oceânica ${currentLbl.toLowerCase()} de ${WeatherDetailsSnapshot.windCardinalPt(d.oceanCurrentDirDeg)}.',
      ),
    ];
  }

  String _fmtTime(DateTime? t) {
    if (t == null) return '—';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _daylightLong(DateTime? sr, DateTime? ss) {
    if (sr == null || ss == null) return '';
    final d = ss.difference(sr);
    return '${d.inHours} horas ${d.inMinutes % 60} minutos';
  }
}

// ── Tipos de badge de estado (como na referência) ─────────────────────────────

enum _StatusKind { yellow, orange, blueInfo }

// ── Cartão branco — estrutura idêntica à referência ─────────────────────────

class _RefCard extends StatelessWidget {
  const _RefCard({
    required this.title,
    required this.body,
    this.status = '',
    this.statusKind = _StatusKind.yellow,
    this.description = '',
    this.hideStatus = false,
  });

  final String title;
  final Widget body;
  final String status;
  final _StatusKind statusKind;
  final String description;
  final bool hideStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: OracleWeatherDetailsGrid.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: OracleWeatherDetailsGrid.titleColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Expanded(child: body),
          if (!hideStatus && status.isNotEmpty) ...[
            const SizedBox(height: 6),
            _StatusBadge(label: status, kind: statusKind),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              description,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 10,
                color: OracleWeatherDetailsGrid.bodyColor,
                height: 1.35,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.kind});
  final String label;
  final _StatusKind kind;

  Color get _bg {
    switch (kind) {
      case _StatusKind.orange:
        return const Color(0xFFFF9800);
      case _StatusKind.blueInfo:
        return const Color(0xFF2196F3);
      case _StatusKind.yellow:
        return const Color(0xFFFFC107);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: _bg, shape: BoxShape.circle),
          child: Icon(
            kind == _StatusKind.blueInfo ? Icons.info : Icons.circle,
            size: kind == _StatusKind.blueInfo ? 10 : 6,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: OracleWeatherDetailsGrid.titleColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Custom painters ──────────────────────────────────────────────────────────

void _paint3dBarFace(
  Canvas canvas,
  RRect front,
  Color base, {
  double depth = 5,
}) {
  final r = Rect.fromLTRB(front.left, front.top, front.right, front.bottom);
  final side = Path()
    ..moveTo(r.right, r.top + 4)
    ..lineTo(r.right + depth, r.top)
    ..lineTo(r.right + depth, r.bottom)
    ..lineTo(r.right, r.bottom - 2)
    ..close();
  canvas.drawPath(
    side,
    Paint()..color = Color.lerp(base, Colors.black, 0.35)!,
  );
  canvas.drawRRect(
    front,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(base, Colors.white, 0.35)!,
          base,
          Color.lerp(base, Colors.black, 0.15)!,
        ],
      ).createShader(r),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(r.left, r.top, r.width, math.min(5.0, r.height * 0.18)),
      front.tlRadius,
    ),
    Paint()..color = Colors.white.withValues(alpha: 0.42),
  );
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values, this.color, {this.filled = false});
  final List<double> values;
  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      // linha plana decorativa
      final y = size.height * 0.5;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = color.withValues(alpha: 0.4)
          ..strokeWidth = 2,
      );
      return;
    }
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV).abs() < 0.01 ? 1.0 : maxV - minV;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - ((values[i] - minV) / range) * (size.height - 6) - 3;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    // Sombra 3D (ribbon deslocado)
    final shadow = Path.from(path)..shift(const Offset(2.5, 3));
    canvas.drawPath(
      shadow,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    if (filled) {
      final fill = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.28),
              color.withValues(alpha: 0.04),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(color, Colors.white, 0.4)!,
            color,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.5))
        ..strokeWidth = 2.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values || old.filled != filled;
}

class _CloudCoverPainter extends CustomPainter {
  _CloudCoverPainter({required this.cloudPct, this.isClear = false});
  final double cloudPct;
  final bool isClear;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;

    // Esfera 3D — sombra base
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx + 3, c.dy + r * 0.55),
        width: r * 1.5,
        height: r * 0.35,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );

    // Céu radial vibrante (esfera)
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: isClear
              ? [const Color(0xFFFFF176), const Color(0xFF4FC3F7), const Color(0xFF29B6F6)]
              : [
                  const Color(0xFFE1F5FE),
                  const Color(0xFF81D4FA),
                  const Color(0xFF039BE5),
                ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // Brilho especular
    canvas.drawCircle(
      Offset(c.dx - r * 0.28, c.dy - r * 0.32),
      r * 0.18,
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );

    // Glow exterior
    canvas.drawCircle(
      c,
      r + 2,
      Paint()
        ..color = (isClear ? const Color(0xFFFFD54F) : const Color(0xFF4FC3F7))
            .withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    if (isClear || cloudPct < 25) {
      // Raios de sol
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        final inner = r * 0.55;
        final outer = r * 0.88;
        canvas.drawLine(
          Offset(c.dx + inner * math.cos(a), c.dy + inner * math.sin(a)),
          Offset(c.dx + outer * math.cos(a), c.dy + outer * math.sin(a)),
          Paint()
            ..color = const Color(0xFFFFD54F).withValues(alpha: 0.85)
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.drawCircle(c, r * 0.28, Paint()..color = const Color(0xFFFFEB3B));
      canvas.drawCircle(
        c,
        r * 0.28,
        Paint()
          ..color = const Color(0xFFFF8F00)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Nuvens (opacidade conforme nebulosidade)
    final cloudAlpha = (cloudPct / 100).clamp(0.15, 0.95);
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: cloudAlpha);
    void drawCloud(Offset o, double scale) {
      canvas.drawCircle(Offset(o.dx - 8 * scale, o.dy), 7 * scale, cloudPaint);
      canvas.drawCircle(Offset(o.dx + 8 * scale, o.dy), 8 * scale, cloudPaint);
      canvas.drawCircle(Offset(o.dx, o.dy - 5 * scale), 9 * scale, cloudPaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: o, width: 28 * scale, height: 10 * scale),
          Radius.circular(5 * scale),
        ),
        cloudPaint,
      );
    }

    if (!isClear) {
      drawCloud(Offset(c.dx - 6, c.dy + 4), 1.1);
      if (cloudPct > 40) drawCloud(Offset(c.dx + 10, c.dy - 2), 0.85);
      if (cloudPct > 65) {
        final shadow = Paint()..color = const Color(0xFF90A4AE).withValues(alpha: 0.35);
        canvas.drawCircle(Offset(c.dx, c.dy + 8), r * 0.5, shadow);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CloudCoverPainter old) =>
      old.cloudPct != cloudPct || old.isClear != isClear;
}

class _PrecipChartPainter extends CustomPainter {
  _PrecipChartPainter({required this.mm});
  final double mm;

  @override
  void paint(Canvas canvas, Size size) {
    final hasRain = mm >= 0.5;
    final norm = (mm / 15).clamp(0.12, 1.0);
    final baseY = size.height * 0.92;

    // Fundo ondulado — água viva
    final wave = Path()
      ..moveTo(0, baseY)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * (hasRain ? 0.55 : 0.68),
        size.width * 0.55,
        baseY,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * (hasRain ? 0.78 : 0.62),
        size.width,
        baseY,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      wave,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF4FC3F7),
            Color(0xFF0288D1),
            Color(0xFF01579B),
          ],
          stops: [0.0, 0.45, 1.0],
        ).createShader(Rect.fromLTWH(0, size.height * 0.35, size.width, size.height * 0.65)),
    );

    // Barras saturadas (24h)
    const n = 8;
    final barW = size.width / (n * 2.0);
    final gap = barW * 0.65;
    final totalW = n * barW + (n - 1) * gap;
    var x = (size.width - totalW) / 2;
    for (var i = 0; i < n; i++) {
      final t = i / (n - 1);
      final h = size.height * 0.72 * (hasRain ? norm * (0.35 + 0.65 * t) : 0.18 + 0.08 * i);
      final color = Color.lerp(
        const Color(0xFF29B6F6),
        const Color(0xFF0D47A1),
        t,
      )!;
      final top = baseY - h;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barW, h),
        const Radius.circular(4),
      );
      _paint3dBarFace(canvas, rect, color, depth: 4);
      x += barW + gap;
    }

    // Gotas / brilho
    final dropPaint = Paint()..color = const Color(0xFF00B0FF);
    if (hasRain) {
      for (final (dx, dy) in [(0.18, 0.08), (0.42, 0.14), (0.65, 0.06), (0.82, 0.12)]) {
        final p = Offset(size.width * dx, size.height * dy);
        canvas.drawOval(Rect.fromCenter(center: p, width: 4, height: 7), dropPaint);
      }
    } else {
      // Sol reflexo no mar seco
      canvas.drawCircle(
        Offset(size.width * 0.82, size.height * 0.12),
        5,
        Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PrecipChartPainter old) => old.mm != mm;
}

class _HumidityBarsPainter extends CustomPainter {
  _HumidityBarsPainter({required this.values, required this.current});
  final List<double> values;
  final double current;

  @override
  void paint(Canvas canvas, Size size) {
    final data = values.length >= 8
        ? values.sublist(values.length - 8)
        : (values.length < 8
            ? [...List.filled(8 - values.length, current), ...values]
            : values);
    final maxV = data.reduce(math.max).clamp(40.0, 100.0);
    const n = 8;
    final barW = size.width / (n * 1.8);
    final gap = barW * 0.55;
    final totalW = n * barW + (n - 1) * gap;
    var x = (size.width - totalW) / 2;

    for (var i = 0; i < n; i++) {
      final h = (data[i] / maxV) * size.height * 0.92;
      final t = i / (n - 1);
      final color = Color.lerp(
        const Color(0xFF4FC3F7),
        const Color(0xFF0D47A1),
        t,
      )!;
      final isLast = i == n - 1;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - h, barW, h),
        const Radius.circular(3),
      );
      if (isLast) {
        canvas.drawRRect(
          rect.shift(const Offset(0, 2)),
          Paint()
            ..color = color.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }
      _paint3dBarFace(
        canvas,
        rect,
        isLast ? color : color.withValues(alpha: 0.82),
        depth: isLast ? 5 : 3.5,
      );
      x += barW + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _HumidityBarsPainter old) =>
      old.values != values || old.current != current;
}

class _CompassPainter extends CustomPainter {
  _CompassPainter(this.deg);
  final int deg;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;

    // Sombra / profundidade
    canvas.drawCircle(
      Offset(c.dx + 1.5, c.dy + 2),
      r,
      Paint()..color = const Color(0xFF263238).withValues(alpha: 0.12),
    );

    // Face da bússola — gradiente creme
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFFDE7),
            const Color(0xFFECEFF1),
            const Color(0xFFB0BEC5),
          ],
          stops: const [0.2, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Anel metálico exterior
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = SweepGradient(
          colors: const [
            Color(0xFF90A4AE),
            Color(0xFFECEFF1),
            Color(0xFF78909C),
            Color(0xFFCFD8DC),
            Color(0xFF90A4AE),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Marcas intermédias (16 pontos)
    for (var i = 0; i < 16; i++) {
      final a = (i * math.pi / 8) - math.pi / 2;
      final isMajor = i % 4 == 0;
      final inner = r - (isMajor ? 14 : 9);
      final outer = r - 3;
      canvas.drawLine(
        Offset(c.dx + inner * math.cos(a), c.dy + inner * math.sin(a)),
        Offset(c.dx + outer * math.cos(a), c.dy + outer * math.sin(a)),
        Paint()
          ..color = isMajor ? const Color(0xFF455A64) : const Color(0xFF90A4AE)
          ..strokeWidth = isMajor ? 2 : 1,
      );
    }

    // Pontos cardeais coloridos
    const cardinals = ['N', 'L', 'S', 'O'];
    const cardColors = [
      Color(0xFFE53935),
      Color(0xFF1E88E5),
      Color(0xFF546E7A),
      Color(0xFF43A047),
    ];
    for (var i = 0; i < 4; i++) {
      final a = (i * math.pi / 2) - math.pi / 2;
      final p = Offset(c.dx + (r - 16) * math.cos(a), c.dy + (r - 16) * math.sin(a));
      final tp = TextPainter(
        text: TextSpan(
          text: cardinals[i],
          style: TextStyle(
            fontSize: i == 0 ? 10 : 8,
            fontWeight: FontWeight.w800,
            color: cardColors[i],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - tp.height / 2));
    }

    // Seta de vento (de onde vem)
    final rad = (deg - 90) * math.pi / 180;
    final arrowLen = r - 18;
    final tip = Offset(c.dx + arrowLen * math.cos(rad), c.dy + arrowLen * math.sin(rad));
    final perp = rad + math.pi / 2;
    final wing = 7.0;
    final arrow = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        c.dx + (arrowLen - 14) * math.cos(rad) + wing * math.cos(perp),
        c.dy + (arrowLen - 14) * math.sin(rad) + wing * math.sin(perp),
      )
      ..lineTo(
        c.dx + (arrowLen - 14) * math.cos(rad) - wing * math.cos(perp),
        c.dy + (arrowLen - 14) * math.sin(rad) - wing * math.sin(perp),
      )
      ..close();
    canvas.drawPath(
      arrow,
      Paint()
        ..shader = LinearGradient(
          colors: [const Color(0xFF00E676), const Color(0xFF00C853)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Sector suave (origem do vento)
    final sector = Path()
      ..moveTo(c.dx, c.dy)
      ..arcTo(Rect.fromCircle(center: c, radius: r - 6), rad - 0.35, 0.7, false)
      ..close();
    canvas.drawPath(
      sector,
      Paint()..color = const Color(0xFF00E676).withValues(alpha: 0.28),
    );

    // Centro — pino metálico
    canvas.drawCircle(c, 5, Paint()..color = const Color(0xFF37474F));
    canvas.drawCircle(
      c,
      5,
      Paint()
        ..color = const Color(0xFFB0BEC5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(c, 2, Paint()..color = const Color(0xFFECEFF1));
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) => old.deg != deg;
}

class _SemiGaugePainter extends CustomPainter {
  _SemiGaugePainter({
    required this.value,
    required this.display,
    this.pollen = false,
  });
  final double value;
  final String display;
  final bool pollen;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.92);
    final r = size.width / 2 - 6;
    const start = math.pi;
    const sweep = math.pi;
    final rect = Rect.fromCircle(center: c, radius: r);

    final colors = pollen
        ? [const Color(0xFF66BB6A), const Color(0xFFFFEB3B), const Color(0xFFFF5722)]
        : [
            const Color(0xFF66BB6A),
            const Color(0xFFFFEB3B),
            const Color(0xFFFF9800),
            const Color(0xFFE91E63),
            const Color(0xFF9C27B0),
          ];

    // Sombra 3D do arco
    for (var i = 0; i < colors.length; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(c.dx + 2, c.dy + 3), radius: r),
        start + sweep * i / colors.length,
        sweep / colors.length,
        false,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.12)
          ..strokeWidth = 9
          ..style = PaintingStyle.stroke,
      );
    }
    for (var i = 0; i < colors.length; i++) {
      canvas.drawArc(
        rect,
        start + sweep * i / colors.length,
        sweep / colors.length,
        false,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Color.lerp(colors[i], Colors.white, 0.35)!,
              colors[i],
            ],
          ).createShader(rect)
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Marcador 3D
    final angle = start + sweep * value.clamp(0.0, 1.0);
    final tip = Offset(c.dx + r * math.cos(angle), c.dy + r * math.sin(angle));
    canvas.drawCircle(
      Offset(tip.dx + 1.5, tip.dy + 2),
      6,
      Paint()..color = Colors.black.withValues(alpha: 0.2),
    );
    canvas.drawCircle(tip, 6, Paint()..color = const Color(0xFF37474F));
    canvas.drawCircle(
      Offset(tip.dx - 1, tip.dy - 1),
      3,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _SemiGaugePainter old) =>
      old.value != value || old.pollen != pollen;
}

class _IqaRingPainter extends CustomPainter {
  _IqaRingPainter({required this.value, this.aqi = 0});
  final double value;
  final int aqi;

  Color _aqiColor(double v) {
    if (v < 0.2) return const Color(0xFF00E676);
    if (v < 0.4) return const Color(0xFF76FF03);
    if (v < 0.6) return const Color(0xFFFFEA00);
    if (v < 0.8) return const Color(0xFFFF6D00);
    return const Color(0xFFFF1744);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final stroke = size.width * 0.11;
    final r = size.width / 2 - stroke / 2 - 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    final markerColor = _aqiColor(value);

    // Centro vivo
    canvas.drawCircle(
      c,
      r - stroke * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [
            markerColor.withValues(alpha: 0.35),
            markerColor.withValues(alpha: 0.12),
            Colors.white,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Glow duplo exterior
    for (final (alpha, w) in [(0.28, 0.55), (0.14, 0.9)]) {
      canvas.drawCircle(
        c,
        r + stroke * w,
        Paint()
          ..color = markerColor.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 0.35,
      );
    }

    // Pista completa — cores saturadas
    const segs = 5;
    final segColors = [
      const Color(0xFF00E676),
      const Color(0xFF76FF03),
      const Color(0xFFFFEA00),
      const Color(0xFFFF6D00),
      const Color(0xFFFF1744),
    ];
    for (var i = 0; i < segs; i++) {
      canvas.drawArc(
        rect,
        -math.pi / 2 + i * 2 * math.pi / segs,
        2 * math.pi / segs - 0.05,
        false,
        Paint()
          ..color = segColors[i].withValues(alpha: 0.38)
          ..strokeWidth = stroke
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt,
      );
    }

    // Arco activo — máxima saturação
    for (var i = 0; i < segs; i++) {
      final frac = value * segs;
      if (i >= frac.ceil()) break;
      final sweep = i < frac.floor()
          ? 2 * math.pi / segs - 0.05
          : (frac - i) * 2 * math.pi / segs;
      canvas.drawArc(
        rect,
        -math.pi / 2 + i * 2 * math.pi / segs,
        sweep,
        false,
        Paint()
          ..color = segColors[i]
          ..strokeWidth = stroke + 1
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Marcador com halo forte
    final angle = -math.pi / 2 + 2 * math.pi * value;
    final tip = Offset(c.dx + r * math.cos(angle), c.dy + r * math.sin(angle));
    canvas.drawCircle(
      tip,
      stroke * 0.45,
      Paint()
        ..color = markerColor.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(tip, stroke * 0.32, Paint()..color = markerColor);
    canvas.drawCircle(
      tip,
      stroke * 0.32,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(tip, stroke * 0.1, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _IqaRingPainter old) =>
      old.value != value || old.aqi != aqi;
}

class _VisibilityPyramidPainter extends CustomPainter {
  _VisibilityPyramidPainter(this.km);
  final double km;

  @override
  void paint(Canvas canvas, Size size) {
    final norm = (km / 10).clamp(0.3, 1.0);
    const layers = 6;
    for (var i = 0; i < layers; i++) {
      final t = i / (layers - 1);
      final w = size.width * (0.25 + 0.12 * i);
      final h = 6.0 * norm;
      final left = (size.width - w) / 2;
      final top = size.height - (layers - i) * (h + 2);
      final color = Color.lerp(
        const Color(0xFFC8E6C9),
        const Color(0xFF2E7D32),
        t,
      )!;
      _paint3dBarFace(
        canvas,
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, w, h),
          const Radius.circular(2),
        ),
        color,
        depth: 3 + i * 0.4,
      );
    }
    // Horizonte 3D
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.35),
      Offset(size.width * 0.92, size.height * 0.35),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF81D4FA), Color(0xFFE1F5FE), Color(0xFF81D4FA)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, 4))
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _VisibilityPyramidPainter old) => old.km != km;
}

class _SunPathPainter extends CustomPainter {
  _SunPathPainter({this.sunrise, this.sunset});
  final DateTime? sunrise;
  final DateTime? sunset;

  @override
  void paint(Canvas canvas, Size size) {
    final baseY = size.height * 0.55;
    final c = Offset(size.width / 2, baseY);
    final r = size.width / 2 - 8;

    // Linha horizonte
    canvas.drawLine(
      Offset(4, baseY),
      Offset(size.width - 4, baseY),
      Paint()
        ..color = const Color(0xFFE0E0E0)
        ..strokeWidth = 1,
    );

    // Arco gradiente (nascer → meio-dia → pôr)
    const colors = [
      Color(0xFFFFEB3B),
      Color(0xFFFF9800),
      Color(0xFFE91E63),
      Color(0xFF9C27B0),
    ];
    for (var i = 0; i < colors.length; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        math.pi + math.pi * i / colors.length,
        math.pi / colors.length,
        false,
        Paint()
          ..color = colors[i]
          ..strokeWidth = 5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Sol no ponto actual (meio do arco)
    final sunX = c.dx;
    final sunY = c.dy - r;
    canvas.drawCircle(
      Offset(sunX, sunY),
      6,
      Paint()..color = const Color(0xFFFFEB3B),
    );
    canvas.drawCircle(
      Offset(sunX, sunY),
      6,
      Paint()
        ..color = const Color(0xFFFF9800)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _SunPathPainter old) => false;
}

class _MoonPathPainter extends CustomPainter {
  _MoonPathPainter({required this.phase, this.illumination = 0.5});
  final double phase;
  final double illumination;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width / 2 - 10, size.height * 0.42);
    // Centra o arco verticalmente no cartão
    final baseY = size.height / 2 + r / 2;
    final c = Offset(size.width / 2, baseY);
    final rect = Rect.fromCircle(center: c, radius: r);

    // Céu nocturno suave (gradiente)
    final skyRect = Rect.fromLTWH(0, 0, size.width, baseY);
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFEDE7F6),
          Color(0xFFE8EAF6),
          Color(0x00FFFFFF),
        ],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    // Estrelas decorativas
    final stars = [
      (0.15, 0.18, 1.2),
      (0.28, 0.32, 1.0),
      (0.72, 0.14, 1.4),
      (0.85, 0.28, 1.0),
      (0.55, 0.22, 0.9),
    ];
    for (final (sx, sy, sr) in stars) {
      canvas.drawCircle(
        Offset(size.width * sx, size.height * sy),
        sr,
        Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.75),
      );
    }

    // Horizonte
    canvas.drawLine(
      Offset(2, baseY),
      Offset(size.width - 2, baseY),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x00B39DDB), Color(0xFF9575CD), Color(0x00B39DDB)],
        ).createShader(Rect.fromLTWH(0, baseY - 1, size.width, 2))
        ..strokeWidth = 1.5,
    );

    // Arco gradiente (prata → índigo → violeta)
    const arcColors = [
      Color(0xFFB0BEC5),
      Color(0xFF9FA8DA),
      Color(0xFF7986CB),
      Color(0xFF5C6BC0),
      Color(0xFF3949AB),
    ];
    for (var i = 0; i < arcColors.length; i++) {
      canvas.drawArc(
        rect,
        math.pi + math.pi * i / arcColors.length,
        math.pi / arcColors.length,
        false,
        Paint()
          ..color = arcColors[i]
          ..strokeWidth = 5.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Posição da lua no arco
    final angle = math.pi + math.pi * phase.clamp(0.0, 1.0);
    final moon = Offset(c.dx + r * math.cos(angle), c.dy + r * math.sin(angle));
    const moonR = 11.0;

    // Glow
    canvas.drawCircle(
      moon,
      moonR + 6,
      Paint()
        ..color = const Color(0xFFFFE082).withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      moon,
      moonR + 3,
      Paint()
        ..color = const Color(0xFFB39DDB).withValues(alpha: 0.45),
    );

    // Disco lunar — base escura + face iluminada
    canvas.drawCircle(moon, moonR, Paint()..color = const Color(0xFF455A64));
    final lit = Path()..addOval(Rect.fromCircle(center: moon, radius: moonR));
    final shadowR = moonR * 0.9;
    final shadowOffset = shadowR * (1 - 2 * illumination.clamp(0.08, 0.95));
    final shadow = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(moon.dx + shadowOffset, moon.dy),
        radius: shadowR,
      ));
    final litFace = Path.combine(PathOperation.difference, lit, shadow);
    canvas.drawPath(
      litFace,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF9C4),
            const Color(0xFFFFD54F),
            const Color(0xFFFFB300),
          ],
        ).createShader(Rect.fromCircle(center: moon, radius: moonR)),
    );
    canvas.drawCircle(
      moon,
      moonR,
      Paint()
        ..color = const Color(0xFF5C6BC0).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Crateras subtis
    canvas.drawCircle(
      Offset(moon.dx - 3, moon.dy - 2),
      1.5,
      Paint()..color = const Color(0xFF6D4C41).withValues(alpha: 0.25),
    );
    canvas.drawCircle(
      Offset(moon.dx + 2, moon.dy + 3),
      1.0,
      Paint()..color = const Color(0xFF6D4C41).withValues(alpha: 0.2),
    );
  }

  @override
  bool shouldRepaint(covariant _MoonPathPainter old) =>
      old.phase != phase || old.illumination != illumination;
}

class _MoonCrescentPainter extends CustomPainter {
  _MoonCrescentPainter(this.phase);
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 2;

    // Glow âmbar
    canvas.drawCircle(
      c,
      r + 5,
      Paint()
        ..color = const Color(0xFFF3C64D).withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Disco base (lado escuro)
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF455A64));

    // Porção iluminada (crescente) — amarelo reforçado
    final lit = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    final shadowOffset = r * (1 - 2 * phase.clamp(0.05, 0.95));
    final shadow = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(c.dx + shadowOffset, c.dy),
        radius: r * 0.92,
      ));
    final moon = Path.combine(PathOperation.difference, lit, shadow);
    canvas.drawPath(
      moon,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.25),
          colors: const [
            Color(0xFFFFF8E1),
            Color(0xFFF3C64D),
            Color(0xFFFFB300),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Crateras subtis
    canvas.drawCircle(
      Offset(c.dx - r * 0.22, c.dy - r * 0.15),
      r * 0.08,
      Paint()..color = const Color(0xFFE65100).withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      Offset(c.dx + r * 0.18, c.dy + r * 0.2),
      r * 0.05,
      Paint()..color = const Color(0xFFE65100).withValues(alpha: 0.14),
    );

    // Contorno
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0xFFFFB300).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _MoonCrescentPainter old) => old.phase != phase;
}

/// Curva de maré 2D — preenchimento gradiente, eixo ALTA/MÉDIA/BAIXA, PM/BM/AGORA.
class _TideChartPainter extends CustomPainter {
  _TideChartPainter({
    required this.phase,
    required this.sparkline,
  });

  final String phase;
  final List<double> sparkline;

  static const _cyan = Color(0xFF00E5FF);
  static const _deep = Color(0xFF01579B);

  void _text(
    Canvas canvas,
    String text,
    Offset at, {
    required Color color,
    double size = 9,
    FontWeight fw = FontWeight.w700,
    TextAlign align = TextAlign.left,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: size, fontWeight: fw, color: color, height: 1),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = at.dx;
    if (align == TextAlign.center) dx -= tp.width / 2;
    if (align == TextAlign.right) dx -= tp.width;
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  List<double> _resample(int n) {
    final raw = sparkline.length >= 4
        ? sparkline
        : List<double>.generate(12, (i) {
            final t = i / 11;
            return math.sin(t * math.pi * 2 - math.pi / 2);
          });
    final out = <double>[];
    for (var i = 0; i < n; i++) {
      final t = i / (n - 1);
      final f = t * (raw.length - 1);
      final i0 = f.floor().clamp(0, raw.length - 1);
      final i1 = (i0 + 1).clamp(0, raw.length - 1);
      final frac = f - i0;
      out.add(raw[i0] * (1 - frac) + raw[i1] * frac);
    }
    return out;
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cpX = (p0.dx + p1.dx) / 2;
      path.cubicTo(cpX, p0.dy, cpX, p1.dy, p1.dx, p1.dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const chartL = 2.0;
    final chartR = w - 30;
    const chartT = 2.0;
    final chartB = h - 4;
    final chartW = chartR - chartL;
    final chartH = chartB - chartT;

    final bgRect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(10)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8F4FD), Color(0xFFB3E5FC), Color(0xFF4DD0E1)],
        ).createShader(bgRect),
    );

    final data = _resample(40);
    final minV = data.reduce(math.min);
    final maxV = data.reduce(math.max);
    final span = (maxV - minV).clamp(0.08, 6.0);

    double yAt(int i) {
      final norm = ((data[i] - minV) / span).clamp(0.0, 1.0);
      return chartB - norm * chartH * 0.82 - chartH * 0.06;
    }

    double xAt(int i) => chartL + (i / (data.length - 1)) * chartW;
    final points = List.generate(data.length, (i) => Offset(xAt(i), yAt(i)));

    // Faixa praia
    final beachH = chartH * 0.07;
    canvas.drawRect(
      Rect.fromLTWH(chartL, chartB - beachH, chartW, beachH + 6),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFE082), Color(0xFFF3C64D), Color(0xFFE6A817)],
        ).createShader(Rect.fromLTWH(chartL, chartB - beachH, chartW, beachH)),
    );

    // Grelha + eixo direito
    const levels = ['ALTA', 'MÉDIA', 'BAIXA'];
    const levelColors = [Color(0xFF01579B), Color(0xFF00838F), Color(0xFF6D4C41)];
    for (var i = 0; i < 3; i++) {
      final t = 1.0 - i / 2.0;
      final gy = chartB - t * chartH * 0.82 - chartH * 0.06;
      canvas.drawLine(
        Offset(chartL, gy),
        Offset(chartR, gy),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..strokeWidth = 0.9,
      );
      _text(
        canvas,
        levels[i],
        Offset(w - 3, gy),
        color: levelColors[i],
        size: 7,
        fw: FontWeight.w800,
        align: TextAlign.right,
      );
    }

    // Preenchimento sob a curva
    final fillPath = _smoothPath(points)
      ..lineTo(points.last.dx, chartB)
      ..lineTo(points.first.dx, chartB)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _cyan.withValues(alpha: 0.6),
            const Color(0xFF0288D1).withValues(alpha: 0.78),
            _deep.withValues(alpha: 0.92),
          ],
        ).createShader(Rect.fromLTWH(chartL, chartT, chartW, chartH)),
    );

    // Glow + crista
    final linePath = _smoothPath(points);
    canvas.drawPath(
      linePath,
      Paint()
        ..color = _cyan.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    // PM / BM
    var pmI = 0;
    var bmI = 0;
    for (var i = 1; i < data.length; i++) {
      if (data[i] >= data[pmI]) pmI = i;
      if (data[i] <= data[bmI]) bmI = i;
    }

    void drawMarker(int idx, String label, Color color) {
      final p = points[idx];
      canvas.drawCircle(p, 9, Paint()..color = color.withValues(alpha: 0.22));
      canvas.drawCircle(p, 5.5, Paint()..color = color);
      canvas.drawCircle(
        Offset(p.dx - 1.5, p.dy - 1.5),
        2,
        Paint()..color = Colors.white,
      );
      _text(
        canvas,
        label,
        Offset(p.dx, p.dy - 11),
        color: color,
        size: 8,
        fw: FontWeight.w900,
        align: TextAlign.center,
      );
    }

    drawMarker(pmI, 'PM', const Color(0xFF00C853));
    drawMarker(bmI, 'BM', const Color(0xFFFF6D00));

    // AGORA
    final nowI = sparkline.isNotEmpty
        ? data.length - 1
        : (data.length * 0.65).round().clamp(0, data.length - 1);
    final nowP = points[nowI];
    canvas.drawLine(
      Offset(nowP.dx, chartB - beachH),
      Offset(nowP.dx, nowP.dy - 3),
      Paint()
        ..color = const Color(0xFFFF1744).withValues(alpha: 0.45)
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      nowP,
      8,
      Paint()..color = const Color(0xFFFF1744).withValues(alpha: 0.28),
    );
    canvas.drawCircle(nowP, 5, Paint()..color = const Color(0xFFFF1744));
    _text(
      canvas,
      'agora',
      Offset(nowP.dx, nowP.dy + 10),
      color: const Color(0xFFFF1744),
      size: 7,
      fw: FontWeight.w800,
      align: TextAlign.center,
    );
  }

  @override
  bool shouldRepaint(covariant _TideChartPainter old) =>
      old.phase != phase || old.sparkline != sparkline;
}

/// Correntes oceânicas — fluxo 3D com setas vivas.
class _OceanCurrentPainter extends CustomPainter {
  _OceanCurrentPainter({
    required this.velocityMs,
    required this.dirDeg,
    required this.sparkline,
  });

  final double velocityMs;
  final int dirDeg;
  final List<double> sparkline;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 4;

    // Fundo oceano profundo
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0xFF00B8D4),
            Color(0xFF0277BD),
            Color(0xFF004D73),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Anéis de profundidade 3D
    for (var i = 3; i >= 1; i--) {
      canvas.drawCircle(
        c,
        r * (0.35 + i * 0.18),
        Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.08 + i * 0.04)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Faixas de corrente curvas
    final rad = (dirDeg - 90) * math.pi / 180;
    for (var lane = -2; lane <= 2; lane++) {
      final offset = lane * r * 0.14;
      final perp = rad + math.pi / 2;
      final start = Offset(
        c.dx - r * 0.55 * math.cos(rad) + offset * math.cos(perp),
        c.dy - r * 0.55 * math.sin(rad) + offset * math.sin(perp),
      );
      final end = Offset(
        c.dx + r * 0.55 * math.cos(rad) + offset * math.cos(perp),
        c.dy + r * 0.55 * math.sin(rad) + offset * math.sin(perp),
      );
      final mid = Offset(
        (start.dx + end.dx) / 2 + 8 * math.cos(perp),
        (start.dy + end.dy) / 2 + 8 * math.sin(perp),
      );
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);
      final alpha = (0.35 + velocityMs * 0.4).clamp(0.25, 0.85);
      canvas.drawPath(
        path,
        Paint()
          ..color = Color.lerp(
            const Color(0xFF00E5FF),
            const Color(0xFF00BFA5),
            lane.abs() / 2,
          )!
              .withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + velocityMs.clamp(0, 1),
      );
      _drawArrowHead(canvas, end, rad, const Color(0xFF00E676).withValues(alpha: alpha));
    }

    // Seta principal
    final mainLen = r * (0.35 + velocityMs.clamp(0, 1.2) * 0.25);
    final tip = Offset(c.dx + mainLen * math.cos(rad), c.dy + mainLen * math.sin(rad));
    canvas.drawLine(
      c,
      tip,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF00E676), Color(0xFF00BFA5)],
        ).createShader(Rect.fromCircle(center: c, radius: r))
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    _drawArrowHead(canvas, tip, rad, const Color(0xFF00E676));

    // Glow central
    canvas.drawCircle(
      c,
      r * 0.18,
      Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Mini sparkline velocidade
    if (sparkline.length >= 3) {
      final maxV = sparkline.reduce(math.max).clamp(0.05, 2.0);
      final path = Path();
      final baseY = c.dy + r * 0.72;
      final chartW = r * 0.9;
      for (var i = 0; i < sparkline.length; i++) {
        final t = i / (sparkline.length - 1);
        final x = c.dx - chartW / 2 + chartW * t;
        final y = baseY - sparkline[i] / maxV * 12;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFFFEA00).withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }
  }

  void _drawArrowHead(Canvas canvas, Offset tip, double rad, Color color) {
    final perp = rad + math.pi / 2;
    const wing = 6.0;
    final back = Offset(tip.dx - 12 * math.cos(rad), tip.dy - 12 * math.sin(rad));
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(back.dx + wing * math.cos(perp), back.dy + wing * math.sin(perp))
        ..lineTo(back.dx - wing * math.cos(perp), back.dy - wing * math.sin(perp))
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _OceanCurrentPainter old) =>
      old.velocityMs != velocityMs ||
      old.dirDeg != dirDeg ||
      old.sparkline != sparkline;
}
