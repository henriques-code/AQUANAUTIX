import 'dart:convert';

import 'package:flutter/services.dart';

import 'species_models.dart';

/// Catálogo singleton carregado a partir de `assets/data/species_ibero.json`.
class SpeciesCatalog {
  SpeciesCatalog._();
  static final SpeciesCatalog instance = SpeciesCatalog._();

  static const assetPath = 'assets/data/species_ibero.json';

  List<SpeciesRecord> _list = const [];
  Map<String, SpeciesRecord> _byId = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  List<SpeciesRecord> get all => List.unmodifiable(_list);

  SpeciesRecord? byId(String id) => _byId[id];

  /// Cruza nome científico da IA com o catálogo (variantes com `/`, binómio).
  SpeciesRecord? matchByScientific(String? scientific) {
    if (!_loaded || scientific == null) return null;
    final raw = scientific.trim();
    if (raw.isEmpty) return null;
    final n = raw.toLowerCase();

    SpeciesRecord? exactBinomial() {
      for (final s in _list) {
        for (final part in s.cientifico.split('/')) {
          final p = part.trim().toLowerCase();
          if (p.isEmpty) continue;
          if (p == n || n == p.split(RegExp(r'\s+')).take(2).join(' ')) return s;
        }
      }
      return null;
    }

    final hit = exactBinomial();
    if (hit != null) return hit;

    String binomial(String s) {
      final parts = s.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) return '${parts[0]} ${parts[1]}'.toLowerCase();
      return parts.first.toLowerCase();
    }

    final aiBio = binomial(n);
    for (final s in _list) {
      for (final part in s.cientifico.split('/')) {
        final cb = binomial(part);
        if (cb.isNotEmpty && (n.contains(cb) || cb.contains(aiBio))) return s;
      }
    }
    return null;
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString(assetPath);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final arr = map['species'] as List<dynamic>;
    _list = arr.map((e) => SpeciesRecord.fromJson(e as Map<String, dynamic>)).toList();
    _byId = {for (final s in _list) s.id: s};
    _loaded = true;
  }

  /// Para testes / hot-reload de dados.
  void resetForTest() {
    _list = const [];
    _byId = {};
    _loaded = false;
  }
}
