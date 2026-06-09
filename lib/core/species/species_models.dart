import 'package:flutter/foundation.dart';

/// Registo da base local (`assets/data/species_ibero.json` schema v2).
@immutable
class SpeciesRecord {
  const SpeciesRecord({
    required this.id,
    required this.emoji,
    required this.nomePT,
    required this.nomeES,
    required this.cientifico,
    required this.minPT,
    required this.minES,
    required this.quotaPT,
    required this.quotaES,
    required this.vedaPT,
    required this.vedaES,
    required this.isco,
    required this.tecnica,
    required this.habitat,
    required this.vedaAtiva,
    this.photoUrl = '',
  });

  final String id;
  final String emoji;
  final String nomePT;
  final String nomeES;
  final String cientifico;
  final String minPT;
  final String minES;
  final String quotaPT;
  final String quotaES;
  final String vedaPT;
  final String vedaES;
  final List<String> isco;
  final List<String> tecnica;
  /// `COSTA` ou `RIO`.
  final String habitat;
  final bool vedaAtiva;
  final String photoUrl;

  /// Compat legado — preferir [nomeFor].
  String get nome => nomePT;

  /// Compat legado — preferir [quotaFor].
  String get quota => quotaPT;

  /// Compat legado — preferir [vedaFor].
  String get epoca => vedaPT;

  String nomeFor({required bool es}) =>
      es && nomeES.isNotEmpty ? nomeES : nomePT;

  String quotaFor({required bool es}) =>
      es && quotaES.isNotEmpty ? quotaES : quotaPT;

  String vedaFor({required bool es}) =>
      es && vedaES.isNotEmpty ? vedaES : vedaPT;

  String get iscoDisplay =>
      isco.isEmpty ? '—' : isco.take(3).join(' · ');

  String get tecnicaDisplay =>
      tecnica.isEmpty ? '—' : tecnica.take(3).join(' · ');

  static List<String> _stringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    if (raw is String && raw.isNotEmpty) return [raw];
    return const [];
  }

  factory SpeciesRecord.fromJson(Map<String, dynamic> j) {
    final nomePt = j['nomePT'] as String? ?? j['nome'] as String? ?? '';
    final nomeEs = j['nomeES'] as String? ?? '';
    return SpeciesRecord(
      id: j['id'] as String,
      emoji: j['emoji'] as String? ?? '🐟',
      nomePT: nomePt,
      nomeES: nomeEs.isNotEmpty ? nomeEs : nomePt,
      cientifico: j['cientifico'] as String? ?? '',
      minPT: j['minPT'] as String? ?? '—',
      minES: j['minES'] as String? ?? '—',
      quotaPT: j['quotaPT'] as String? ?? j['quota'] as String? ?? '—',
      quotaES: j['quotaES'] as String? ?? '—',
      vedaPT: j['vedaPT'] as String? ?? j['epoca'] as String? ?? '',
      vedaES: j['vedaES'] as String? ?? '',
      isco: _stringList(j['isco']),
      tecnica: _stringList(j['tecnica']),
      habitat: j['habitat'] as String? ?? 'COSTA',
      vedaAtiva: j['vedaAtiva'] as bool? ?? false,
      photoUrl: j['photoUrl'] as String? ?? '',
    );
  }
}
