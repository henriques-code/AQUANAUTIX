/// P3 — recomendação isco + cana + técnica por espécie, habitat, maré e época.
class BaitRecommendation {
  const BaitRecommendation({
    required this.bait,
    required this.rodType,
    required this.technique,
    required this.techniqueDesc,
    required this.confidence,
  });

  final String bait;
  final String rodType;
  final String technique;
  final String techniqueDesc;
  final int confidence;
}

class _SpeciesRig {
  const _SpeciesRig({
    required this.bait,
    required this.rodType,
    required this.technique,
    required this.techniqueDesc,
    required this.isRioSpecies,
    this.bestMonths = const [],
    this.preferEnchente = false,
    this.preferVazante = false,
  });

  final String bait;
  final String rodType;
  final String technique;
  final String techniqueDesc;
  final bool isRioSpecies;
  final List<int> bestMonths;
  final bool preferEnchente;
  final bool preferVazante;
}

class BaitTechniqueService {
  BaitTechniqueService._();

  static const _table = <String, _SpeciesRig>{
    'robalo': _SpeciesRig(
      bait: 'Lula / borracha',
      rodType: 'Spinning 9–12 ft',
      technique: 'Spinning',
      techniqueDesc:
          'Costa rochosa, artificial 5–40 g, pesca activa e exploratória.',
      isRioSpecies: false,
      bestMonths: [3, 4, 5, 9, 10, 11],
      preferEnchente: true,
    ),
    'dourada': _SpeciesRig(
      bait: 'Minhoca / amêijoa',
      rodType: 'Surf 3.9–4.2 m',
      technique: 'Surfcasting',
      techniqueDesc:
          'Lançamento de praia, pesos 60–200 g, linha 0.28–0.35, distâncias >60 m.',
      isRioSpecies: false,
      bestMonths: [4, 5, 6, 9, 10],
      preferVazante: true,
    ),
    'sargo': _SpeciesRig(
      bait: 'Caranguejo / mexilhão',
      rodType: 'Rock 3–4 m',
      technique: 'Rocha / Float',
      techniqueDesc:
          'Linha fina, anzol pequeno, precisão junto à pedra ou bóia a meio fundo.',
      isRioSpecies: false,
      bestMonths: [5, 6, 7, 8, 9],
      preferEnchente: true,
    ),
    'corvina': _SpeciesRig(
      bait: 'Calamar',
      rodType: 'Bottom 4 m',
      technique: 'Fundo',
      techniqueDesc:
          'Isco natural estático, chumbada, anzol duplo, espera no canal ou rebentação.',
      isRioSpecies: false,
      bestMonths: [1, 2, 11, 12],
      preferVazante: true,
    ),
    'achiga': _SpeciesRig(
      bait: 'Jig / shad',
      rodType: 'Bait 6–8 ft',
      technique: 'Spinning / Topwater',
      techniqueDesc:
          'Margem estruturada: jig ou shad; ao amanhecer, popper na superfície.',
      isRioSpecies: true,
      bestMonths: [3, 4, 5, 6, 9, 10],
    ),
    'carpa': _SpeciesRig(
      bait: 'Milho / boilies',
      rodType: 'Carpa 3.6 m',
      technique: 'Carpfishing',
      techniqueDesc:
          'Boilies e method feeder, montagem à distância, espera activa em lago ou barragem.',
      isRioSpecies: true,
      bestMonths: [4, 5, 6, 7, 8, 9],
    ),
    'barbo': _SpeciesRig(
      bait: 'Milho / minhoca',
      rodType: 'Rio 3–4 m',
      technique: 'Fundo rio',
      techniqueDesc:
          'Fundo em corrente lenta, chumbada fixa ou corrida, isco natural no leito.',
      isRioSpecies: true,
      bestMonths: [3, 4, 5, 6, 9, 10],
      preferEnchente: true,
    ),
    'truta': _SpeciesRig(
      bait: 'Mosca / spinner',
      rodType: 'Spinning 2.1 m',
      technique: 'Fly / Spinning',
      techniqueDesc:
          'Rio vivo: mosca seca/molhada ou spinner em corrente; lançamento técnico.',
      isRioSpecies: true,
      bestMonths: [3, 4, 5, 10, 11],
    ),
    'linguado': _SpeciesRig(
      bait: 'Minhoca / amêijoa',
      rodType: 'Surf 3.6 m',
      technique: 'Fundo praia',
      techniqueDesc:
          'Fundo em areão, 50–80 m, isco natural estático com espera prolongada.',
      isRioSpecies: false,
      bestMonths: [4, 5, 6, 9, 10],
      preferVazante: true,
    ),
    'enguia': _SpeciesRig(
      bait: 'Minhoca / minhocão',
      rodType: 'Bottom 3 m',
      technique: 'Noite fundo',
      techniqueDesc:
          'Fundo estático à noite, isco grande, linha resistente junto à margem.',
      isRioSpecies: true,
      bestMonths: [6, 7, 8, 9],
    ),
  };

  static String _norm(String name) => name
      .toLowerCase()
      .trim()
      .replaceAll('ã', 'a')
      .replaceAll('á', 'a')
      .replaceAll('ú', 'u')
      .replaceAll('í', 'i');

  static BaitRecommendation recommend({
    required String targetSpecies,
    required bool isRio,
    required int month,
    required String tideState,
  }) {
    final key = _norm(targetSpecies);
    final rig = _table[key] ?? _table['robalo']!;

    var confidence = 72;
    if (rig.bestMonths.contains(month)) confidence += 12;
    if (rig.isRioSpecies == isRio) confidence += 8;

    final tide = tideState.toLowerCase();
    final enchente =
        tide.contains('enchente') || tide.contains('subindo') || tide.contains('sube');
    final vazante =
        tide.contains('vazante') || tide.contains('descendo') || tide.contains('baja');
    if (!isRio) {
      if (rig.preferEnchente && enchente) confidence += 8;
      if (rig.preferVazante && vazante) confidence += 8;
    }

    return BaitRecommendation(
      bait: rig.bait,
      rodType: rig.rodType,
      technique: rig.technique,
      techniqueDesc: rig.techniqueDesc,
      confidence: confidence.clamp(55, 98),
    );
  }
}
