import 'package:aquanautix/core/species/species_compliance.dart';
import 'package:aquanautix/core/species/species_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseMinCm extrai centímetros', () {
    expect(SpeciesCompliance.parseMinCm('36cm'), 36);
    expect(SpeciesCompliance.parseMinCm('32 cm'), 32);
    expect(SpeciesCompliance.parseMinCm('Sem mínimo geral'), null);
    expect(SpeciesCompliance.parseMinCm('—'), null);
  });

  test('robalo 42 cm legal em PT e ES', () {
    const s = SpeciesRecord(
      id: 'dicentrarchus_labrax',
      emoji: '🐟',
      nome: 'Robalo',
      cientifico: 'Dicentrarchus labrax',
      minPT: '36cm',
      minES: '36cm',
      quota: '5/dia',
      epoca: 'Aberto',
      isco: '—',
      tecnica: '—',
      habitat: 'COSTA',
      vedaAtiva: false,
    );
    final pt = SpeciesCompliance.evaluateLength(
      species: s,
      country: 'PT',
      measuredLengthCm: 42,
    );
    expect(pt.kind, SizeComplianceKind.legal);
    final es = SpeciesCompliance.evaluateLength(
      species: s,
      country: 'ES',
      measuredLengthCm: 35,
    );
    expect(es.kind, SizeComplianceKind.belowMinimum);
  });
}
