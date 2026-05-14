import 'dart:convert';
import 'dart:ui';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_bootstrap.dart';

class AppInsights {
  final String legalStatusTitle;
  final String legalStatusDetail;
  final String legalSource;
  final String legalUpdatedLabel;

  final String privacyTitle;
  final String privacyDetail;

  final String complianceTitle;
  final String complianceDetail;
  final bool complianceOk;

  final int confidenceScore;
  final String confidenceDetail;

  const AppInsights({
    required this.legalStatusTitle,
    required this.legalStatusDetail,
    required this.legalSource,
    required this.legalUpdatedLabel,
    required this.privacyTitle,
    required this.privacyDetail,
    required this.complianceTitle,
    required this.complianceDetail,
    required this.complianceOk,
    required this.confidenceScore,
    required this.confidenceDetail,
  });
}

class AppInsightsService {
  AppInsightsService._();
  static final AppInsightsService instance = AppInsightsService._();

  final Map<String, Future<AppInsights>> _cacheByScope = {};

  Future<AppInsights> load({
    String? country,
    String region = 'ALL',
    String species = 'ALL',
  }) {
    final effectiveCountry = (country ?? _countryFromLocale()).toUpperCase();
    final effectiveRegion = region.toUpperCase();
    final effectiveSpecies = species.toUpperCase();
    final key = '$effectiveCountry|$effectiveRegion|$effectiveSpecies';
    return _cacheByScope.putIfAbsent(
      key,
      () => _loadInternal(
        country: effectiveCountry,
        region: effectiveRegion,
        species: effectiveSpecies,
      ),
    );
  }

  Future<AppInsights> _loadInternal({
    required String country,
    required String region,
    required String species,
  }) async {
    final fallback = fallbackData;
    final SupabaseClient? client = supabaseClientOrNull;
    if (client == null) return fallback;

    try {
      final scopedRows = await client.rpc(
        'get_app_insights_v2',
        params: {
          'p_country': country,
          'p_region': region,
          'p_species': species,
        },
      );

      if (scopedRows.isNotEmpty) {
        final scoped = _selectBestScopedRows(
          List<Map<String, dynamic>>.from(scopedRows),
          region: region,
          species: species,
        );
        return AppInsights(
          legalStatusTitle: _readScopedString(
            scoped,
            'legal_check',
            'title',
            fallback.legalStatusTitle,
          ),
          legalStatusDetail: _readScopedString(
            scoped,
            'legal_check',
            'detail',
            fallback.legalStatusDetail,
          ),
          legalSource: _readScopedString(
            scoped,
            'legal_check',
            'source',
            fallback.legalSource,
          ),
          legalUpdatedLabel: _readScopedString(
            scoped,
            'legal_check',
            'updated_label',
            fallback.legalUpdatedLabel,
          ),
          privacyTitle: _readScopedString(
            scoped,
            'privacy',
            'title',
            fallback.privacyTitle,
          ),
          privacyDetail: _readScopedString(
            scoped,
            'privacy',
            'detail',
            fallback.privacyDetail,
          ),
          complianceTitle: _readScopedString(
            scoped,
            'compliance',
            'title',
            fallback.complianceTitle,
          ),
          complianceDetail: _readScopedString(
            scoped,
            'compliance',
            'detail',
            fallback.complianceDetail,
          ),
          complianceOk: _readScopedBool(
            scoped,
            'compliance',
            'ok',
            fallback.complianceOk,
          ),
          confidenceScore: _readScopedInt(
            scoped,
            'confidence',
            'score',
            fallback.confidenceScore,
          ),
          confidenceDetail: _readScopedString(
            scoped,
            'confidence',
            'detail',
            fallback.confidenceDetail,
          ),
        );
      }

      final rows = await client
          .from('app_insights')
          .select('key, value')
          .inFilter('key', const [
            'legal_check',
            'privacy',
            'compliance',
            'confidence',
          ]);

      if (rows.isEmpty) return fallback;

      final map = <String, dynamic>{};
      for (final r in rows) {
        final k = r['key'] as String?;
        final v = r['value'];
        if (k != null) map[k] = v;
      }

      return AppInsights(
        legalStatusTitle:
            _readString(map, 'legal_check', 'title', fallback.legalStatusTitle),
        legalStatusDetail:
            _readString(map, 'legal_check', 'detail', fallback.legalStatusDetail),
        legalSource: _readString(map, 'legal_check', 'source', fallback.legalSource),
        legalUpdatedLabel:
            _readString(map, 'legal_check', 'updated', fallback.legalUpdatedLabel),
        privacyTitle: _readString(map, 'privacy', 'title', fallback.privacyTitle),
        privacyDetail: _readString(map, 'privacy', 'detail', fallback.privacyDetail),
        complianceTitle:
            _readString(map, 'compliance', 'title', fallback.complianceTitle),
        complianceDetail:
            _readString(map, 'compliance', 'detail', fallback.complianceDetail),
        complianceOk:
            _readBool(map, 'compliance', 'ok', fallback.complianceOk),
        confidenceScore:
            _readInt(map, 'confidence', 'score', fallback.confidenceScore),
        confidenceDetail:
            _readString(map, 'confidence', 'detail', fallback.confidenceDetail),
      );
    } catch (_) {
      return fallback;
    }
  }

  static String _readString(
    Map<String, dynamic> root,
    String section,
    String key,
    String fallback,
  ) {
    final v = _sectionValue(root, section, key);
    if (v is String && v.trim().isNotEmpty) return v;
    return fallback;
  }

  static bool _readBool(
    Map<String, dynamic> root,
    String section,
    String key,
    bool fallback,
  ) {
    final v = _sectionValue(root, section, key);
    if (v is bool) return v;
    return fallback;
  }

  static int _readInt(
    Map<String, dynamic> root,
    String section,
    String key,
    int fallback,
  ) {
    final v = _sectionValue(root, section, key);
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static dynamic _sectionValue(
    Map<String, dynamic> root,
    String section,
    String key,
  ) {
    final dynamic raw = root[section];
    Map<String, dynamic>? data;
    if (raw is Map<String, dynamic>) {
      data = raw;
    } else if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) data = decoded;
    }
    return data?[key];
  }

  static String _countryFromLocale() {
    final code = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    if (code == 'es') return 'ES';
    return 'PT';
  }

  static Map<String, Map<String, dynamic>> _selectBestScopedRows(
    List<Map<String, dynamic>> rows, {
    required String region,
    required String species,
  }) {
    int rank(Map<String, dynamic> row) {
      final rowRegion = (row['region'] as String? ?? 'ALL').toUpperCase();
      final rowSpecies = (row['species'] as String? ?? 'ALL').toUpperCase();
      int score = 0;
      if (rowRegion == region.toUpperCase()) score += 2;
      if (rowSpecies == species.toUpperCase()) score += 1;
      return score;
    }

    final best = <String, Map<String, dynamic>>{};
    final bestRank = <String, int>{};

    for (final row in rows) {
      final type = row['insight_type'] as String?;
      if (type == null) continue;
      final r = rank(row);
      final current = bestRank[type] ?? -1;
      if (r >= current) {
        best[type] = row;
        bestRank[type] = r;
      }
    }
    return best;
  }

  static String _readScopedString(
    Map<String, Map<String, dynamic>> scoped,
    String type,
    String key,
    String fallback,
  ) {
    final v = scoped[type]?[key];
    if (v is String && v.trim().isNotEmpty) return v;
    return fallback;
  }

  static bool _readScopedBool(
    Map<String, Map<String, dynamic>> scoped,
    String type,
    String key,
    bool fallback,
  ) {
    final v = scoped[type]?[key];
    if (v is bool) return v;
    return fallback;
  }

  static int _readScopedInt(
    Map<String, Map<String, dynamic>> scoped,
    String type,
    String key,
    int fallback,
  ) {
    final v = scoped[type]?[key];
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static AppInsights get fallbackData {
    return const AppInsights(
      legalStatusTitle: 'CHECK LEGAL PRÉ-MISSÃO',
      legalStatusDetail:
          'Sem alertas críticos para esta janela. Tamanho mínimo e limites verificados.',
      legalSource: 'DGRM + MAPA',
      legalUpdatedLabel: 'Atualizado há 2h',
      privacyTitle: 'PRIVACIDADE DIFERENCIAL ATIVA',
      privacyDetail:
          'Partilha pública com zona fuzzificada + atraso temporal. Spot exato mantém-se privado.',
      complianceTitle: 'COMPLIANCE & REPORTE UE',
      complianceDetail:
          '3 capturas desta semana com dados completos para reporte eletrónico.',
      complianceOk: true,
      confidenceScore: 86,
      confidenceDetail:
          'Baseado em maré, vento, histórico local e feedback da tua atividade.',
    );
  }
}

