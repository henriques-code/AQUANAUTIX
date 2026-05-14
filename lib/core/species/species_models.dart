import 'package:flutter/foundation.dart';

/// Registo da base local (`assets/data/species_ibero.json`).
@immutable
class SpeciesRecord {
  const SpeciesRecord({
    required this.id,
    required this.emoji,
    required this.nome,
    required this.cientifico,
    required this.minPT,
    required this.minES,
    required this.quota,
    required this.epoca,
    required this.isco,
    required this.tecnica,
    required this.habitat,
    required this.vedaAtiva,
  });

  final String id;
  final String emoji;
  final String nome;
  final String cientifico;
  final String minPT;
  final String minES;
  final String quota;
  final String epoca;
  final String isco;
  final String tecnica;
  /// `COSTA` ou `RIO`.
  final String habitat;
  final bool vedaAtiva;

  factory SpeciesRecord.fromJson(Map<String, dynamic> j) {
    return SpeciesRecord(
      id: j['id'] as String,
      emoji: j['emoji'] as String,
      nome: j['nome'] as String,
      cientifico: j['cientifico'] as String,
      minPT: j['minPT'] as String,
      minES: j['minES'] as String,
      quota: j['quota'] as String,
      epoca: j['epoca'] as String,
      isco: j['isco'] as String,
      tecnica: j['tecnica'] as String,
      habitat: j['habitat'] as String,
      vedaAtiva: j['vedaAtiva'] as bool? ?? false,
    );
  }
}
