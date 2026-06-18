import 'species_catalog.dart';
import 'species_models.dart';
import 'oracle_rig_plan.dart';

/// P3 — isco, cana e técnica a partir de `species_ibero.json` + condições actuais.
class OracleRigRecommendation {
  OracleRigRecommendation._();

  static const _uiCodeToCatalogId = <String, String>{
    'ROBALO': 'dicentrarchus_labrax',
    'SARGO': 'diplodus_sargus',
    'DOURADA': 'sparus_aurata',
    'CORVINA': 'argyrosomus_regius',
    'LINGUADO': 'solea_solea',
    'RAIA': 'raja_clavata',
    'BARBO': 'luciobarbus_bocagei',
    'ACHIGA': 'micropterus_salmoides',
  };

  /// Síncrono após [SpeciesCatalog.ensureLoaded] (main / Oráculo init).
  static OracleRigPlan recommend({
    required String speciesCode,
    required bool isRio,
    String? tideTrendPt,
    double? waterTempC,
  }) {
    final catalog = SpeciesCatalog.instance;
    if (catalog.isLoaded) {
      final record = _resolveRecord(catalog, speciesCode, isRio: isRio);
      if (record != null) {
        return _fromRecord(
          record,
          isRio: isRio,
          tideTrendPt: tideTrendPt,
          waterTempC: waterTempC,
        );
      }
    }
    return _fallback(speciesCode, isRio: isRio);
  }

  static SpeciesRecord? _resolveRecord(
    SpeciesCatalog catalog,
    String code, {
    required bool isRio,
  }) {
    final upper = code.toUpperCase();
    final id = _uiCodeToCatalogId[upper];
    if (id != null) {
      final hit = catalog.byId(id);
      if (hit != null) return hit;
    }
    for (final s in catalog.all) {
      if (s.nomePT.toUpperCase() == upper) return s;
      if (s.nomeES.toUpperCase() == upper) return s;
    }
    if (isRio) {
      for (final s in catalog.all) {
        if (s.habitat == 'RIO') return s;
      }
    }
    return null;
  }

  static OracleRigPlan _fromRecord(
    SpeciesRecord s, {
    required bool isRio,
    String? tideTrendPt,
    double? waterTempC,
  }) {
    return OracleRigPlan(
      bait: _pickBait(s, tideTrendPt: tideTrendPt, waterTempC: waterTempC),
      rod: _formatRod(s.cana),
      technique: _pickTechnique(s, isRio: isRio, tideTrendPt: tideTrendPt),
      distance: _distanceHint(s, isRio: isRio),
      fromCatalog: true,
    );
  }

  static String _pickBait(
    SpeciesRecord s, {
    String? tideTrendPt,
    double? waterTempC,
  }) {
    final iscos = s.isco;
    if (iscos.isEmpty) return 'Isco natural';

    final trend = (tideTrendPt ?? '').toLowerCase();
    final enchente =
        trend.contains('enchente') || trend.contains('subindo') || trend.contains('sube');
    final vazante =
        trend.contains('vazante') || trend.contains('descendo') || trend.contains('baja');
    final mare = s.mareMelhor.toLowerCase();

    if (enchente && mare.contains('enchente') && iscos.length >= 2) {
      return '${iscos[0]} + ${iscos[1]}';
    }
    if (vazante && mare.contains('vazante') && iscos.length >= 2) {
      return '${iscos[1]} + ${iscos[0]}';
    }

    // Água fria — preferir iscos naturais (primeiros da lista).
    if (waterTempC != null && waterTempC < 14 && iscos.length >= 2) {
      return '${iscos[0]} + ${iscos[1]}';
    }

    return iscos.take(2).join(' + ');
  }

  static String _pickTechnique(
    SpeciesRecord s, {
    required bool isRio,
    String? tideTrendPt,
  }) {
    final tecs = s.tecnica;
    if (tecs.isEmpty) return isRio ? 'Fundo rio' : 'Spinning';

    if (isRio) {
      for (final t in tecs) {
        final l = t.toLowerCase();
        if (l.contains('rio') || l.contains('float')) return t;
      }
    }

    final trend = (tideTrendPt ?? '').toLowerCase();
    final nightBias = trend.isEmpty;
    if (nightBias) {
      for (final t in tecs) {
        if (t.toLowerCase().contains('surf')) return t;
      }
    }

    return tecs.first;
  }

  static String _formatRod(String cana) {
    if (cana.isEmpty) return '—';
    final main = cana.split('/').first.trim();
    return main
        .replaceAll('–', '–')
        .replaceAllMapped(
          RegExp(r'(\d)\s*ft\b', caseSensitive: false),
          (m) => '${m[1]} ft',
        );
  }

  static String _distanceHint(SpeciesRecord s, {required bool isRio}) {
    if (isRio) return 'Corrente moderada';
    if (s.tecnica.any((t) => t.toLowerCase().contains('surf'))) {
      return '40–80 m';
    }
    if (s.tecnica.any((t) => t.toLowerCase().contains('rocha'))) {
      return '20–35 m junto à pedra';
    }
    return 'Zona costeira';
  }

  static OracleRigPlan _fallback(String code, {required bool isRio}) {
    switch (code.toUpperCase()) {
      case 'SARGO':
        return const OracleRigPlan(
          bait: 'Caranguejo + Mexilhão',
          rod: 'Rock 3–4m',
          technique: 'Rocha / Float',
          distance: '20–35m junto à pedra',
        );
      case 'DOURADA':
        return const OracleRigPlan(
          bait: 'Minhoca + Amêijoa',
          rod: 'Surf 3.9m',
          technique: 'Surfcasting',
          distance: '60–90m fundo limpo',
        );
      case 'CORVINA':
        return const OracleRigPlan(
          bait: 'Rapala + Isco natural',
          rod: 'Fundo 4m',
          technique: 'Fundo / Espera',
          distance: 'Canal / rebentação',
        );
      case 'LINGUADO':
        return const OracleRigPlan(
          bait: 'Minhoca + Amêijoa',
          rod: 'Surf 4m',
          technique: 'Fundo praia',
          distance: '50–80m em areão',
        );
      case 'RAIA':
        return const OracleRigPlan(
          bait: 'Sardinha + Arenque',
          rod: 'Surf pesado 4.2m',
          technique: 'Fundo arenoso',
          distance: '80m+',
        );
      case 'ACHIGA':
        return const OracleRigPlan(
          bait: 'Shad + Jig',
          rod: 'Bait 7ft',
          technique: 'Spinning / Topwater',
          distance: 'Margem estruturada',
        );
      case 'BARBO':
        return const OracleRigPlan(
          bait: 'Milho + Minhoca',
          rod: 'Rio 3.6m',
          technique: 'Fundo rio / Float',
          distance: 'Corrente lenta',
        );
      case 'ROBALO':
      default:
        if (isRio) {
          return const OracleRigPlan(
            bait: 'Milho + Minhoca',
            rod: 'Rio 3.6m',
            technique: 'Fundo rio / Float',
            distance: 'Corrente lenta',
          );
        }
        return const OracleRigPlan(
          bait: 'Minhoca + Shad 14cm',
          rod: 'Rock 3.3m',
          technique: 'Surfcasting',
          distance: '40–60m do rochedo',
        );
    }
  }
}
