import 'marine_bundle.dart';
import 'tide_analysis.dart';

bool _prefersSlackWater(String species) {
  switch (species.toUpperCase()) {
    case 'LINGUADO':
    case 'DOURADA':
    case 'SARGO':
    case 'RAIA':
      return true;
    default:
      return false;
  }
}

/// Derivada central (m/h) ~ movimento de água.
double _flowRate(List<MarineHourPoint> day, int i) {
  if (i <= 0 || i >= day.length - 1) return 0;
  final dt = day[i + 1].time.difference(day[i - 1].time).inMinutes / 60.0;
  if (dt <= 0) return 0;
  return (day[i + 1].seaLevelMslM - day[i - 1].seaLevelMslM) / dt;
}

/// Melhor hora (0–23) para a espécie alvo no dia; null se dados insuficientes.
int? bestHourForSpecies(List<MarineHourPoint> day, String species) {
  if (day.length < 4) return null;
  final slack = _prefersSlackWater(species);
  var bestI = 1;
  var bestV = slack ? double.infinity : double.negativeInfinity;
  for (var i = 1; i < day.length - 1; i++) {
    final fr = _flowRate(day, i).abs();
    final h = day[i].time.hour;
    double dawnDusk = 1;
    if ((h >= 5 && h <= 8) || (h >= 18 && h <= 21)) dawnDusk = 1.12;

    if (slack) {
      final score = fr / dawnDusk;
      if (score < bestV) {
        bestV = score;
        bestI = i;
      }
    } else {
      final score = fr * dawnDusk;
      if (score > bestV) {
        bestV = score;
        bestI = i;
      }
    }
  }
  return day[bestI].time.hour;
}

String speciesTideSummary(String species, List<TideExtremum> extrema) {
  if (extrema.length < 2) {
    return 'Maré: dados insuficientes para recomendar janela.';
  }
  final a = extrema[0];
  final b = extrema[1];
  final phase = tidePhaseBetween(a, b) ?? 'Maré';
  final slack = _prefersSlackWater(species);
  if (slack) {
    return '$species costuma responder melhor perto de vau-mar (água mais parada). '
        'Entre ${a.labelPt} e ${b.labelPt}: $phase.';
  }
  return '$species costuma preferir água a mover-se (corrente de maré). '
      'Procura picos de movimento longe de vau-mar; fase actual entre eventos: $phase.';
}
