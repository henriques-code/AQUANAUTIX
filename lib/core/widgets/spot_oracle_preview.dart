import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tides/oracle_data_service.dart';
import '../tides/spot_oracle_snapshot.dart';
import 'oracle_score_ring.dart';

const _kCard = Color(0xFF071428);
const _kCyan = Color(0xFF00F5FF);
const _kHint = Color(0xFF8AADBE);

/// Bloco Oráculo reutilizável para sheets de spot (sem depender do mapa).
class SpotOraclePreview extends StatefulWidget {
  const SpotOraclePreview({
    super.key,
    required this.lat,
    required this.lon,
    this.species,
    this.country,
    this.isRiver,
    this.compact = false,
    this.snapshot,
  });

  final double lat;
  final double lon;
  final String? species;
  final String? country;
  final bool? isRiver;
  final bool compact;

  /// Se fornecido, evita novo fetch (útil quando o caller já tem dados).
  final SpotOracleSnapshot? snapshot;

  @override
  State<SpotOraclePreview> createState() => _SpotOraclePreviewState();
}

class _SpotOraclePreviewState extends State<SpotOraclePreview> {
  SpotOracleSnapshot? _data;
  Object? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.snapshot != null) {
      _data = widget.snapshot;
    } else {
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant SpotOraclePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.snapshot != null) {
      setState(() {
        _data = widget.snapshot;
        _error = null;
        _loading = false;
      });
      return;
    }
    if (oldWidget.lat != widget.lat ||
        oldWidget.lon != widget.lon ||
        oldWidget.isRiver != widget.isRiver) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snap = await OracleDataService.instance.fetchForSpot(
        lat: widget.lat,
        lon: widget.lon,
        species: widget.species,
        country: widget.country,
        isRiver: widget.isRiver,
      );
      if (!mounted) return;
      setState(() {
        _data = snap;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: _kCyan),
          ),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Oráculo indisponível',
          style: GoogleFonts.ibmPlexSans(fontSize: 12, color: _kHint),
        ),
      );
    }

    final snap = _data;
    if (snap == null) return const SizedBox.shrink();

    if (widget.compact) {
      return Row(
        children: [
          OracleScoreRing(score: snap.score, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snap.statusLabel,
                  style: GoogleFonts.orbitron(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _kCyan,
                  ),
                ),
                Text(
                  snap.windowHours,
                  style: GoogleFonts.shareTechMono(fontSize: 10, color: _kHint),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kCyan.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OracleScoreRing(score: snap.score, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ORÁCULO DO SPOT',
                      style: GoogleFonts.shareTechMono(
                        fontSize: 9,
                        color: _kCyan,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      snap.statusLabel,
                      style: GoogleFonts.orbitron(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      snap.windowHours,
                      style: GoogleFonts.shareTechMono(fontSize: 11, color: _kHint),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!snap.isRiver && snap.tideHeightM != null)
                _condChip(
                  snap.isRiver ? 'Nível' : 'Maré',
                  snap.tideTrendPt.isNotEmpty
                      ? '${snap.tideHeightM!.toStringAsFixed(1)}m · ${snap.tideTrendPt}'
                      : '${snap.tideHeightM!.toStringAsFixed(1)}m',
                ),
              if (snap.tempC != null)
                _condChip('Temp', '${snap.tempC!.round()}°C${snap.tempTrendPt.isNotEmpty ? ' · ${snap.tempTrendPt}' : ''}'),
              _condChip('Lua', '${snap.moonPct}%${snap.moonPhaseShortPt.isNotEmpty ? ' · ${snap.moonPhaseShortPt}' : ''}'),
              if (snap.pressureTrendPt.isNotEmpty)
                _condChip('Pressão', snap.pressureTrendPt),
            ],
          ),
        ],
      ),
    );
  }

  Widget _condChip(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF020A14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kCyan.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: GoogleFonts.shareTechMono(fontSize: 9, color: _kHint)),
            Text(
              value,
              style: GoogleFonts.ibmPlexSans(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
}
