import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'oracle_cache_models.dart';

/// Cache persistente do Oráculo (72 h) em disco — modo praia offline.
class OracleCacheRepository {
  OracleCacheRepository._();
  static final OracleCacheRepository instance = OracleCacheRepository._();

  static const cacheTtl = Duration(hours: 72);
  static const maxZones = 5;

  Directory? _root;

  Future<Directory> _dir() async {
    if (_root != null) return _root!;
    final base = await getApplicationDocumentsDirectory();
    _root = Directory('${base.path}/oracle_cache/zones');
    if (!await _root!.exists()) {
      await _root!.create(recursive: true);
    }
    return _root!;
  }

  Future<File> _entryFile(String zoneKey) async {
    final d = await _dir();
    return File('${d.path}/$zoneKey.json');
  }

  Future<File> _manifestFile() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/oracle_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/manifest.json');
  }

  Future<Map<String, dynamic>?> readCostaJson({
    required double lat,
    required double lon,
    required String lang,
    required bool isPlanning,
    bool allowExpired = true,
  }) async {
    final key = oracleCacheZoneKey(
      lat: lat,
      lon: lon,
      lang: lang,
      isPlanning: isPlanning,
    );
    try {
      final file = await _entryFile(key);
      if (!await file.exists()) return null;
      final j = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if (!allowExpired) {
        final meta = OracleCacheMeta.fromJson(j['meta'] as Map<String, dynamic>);
        if (meta.isExpired) return null;
      }
      return j;
    } catch (e) {
      if (kDebugMode) debugPrint('[OracleCache] read falhou $key: $e');
      return null;
    }
  }

  Future<void> writeCostaJson({
    required OracleCacheMeta meta,
    required Map<String, dynamic> payload,
  }) async {
    final key = oracleCacheZoneKey(
      lat: meta.lat,
      lon: meta.lon,
      lang: meta.lang,
      isPlanning: meta.isPlanning,
    );
    try {
      final file = await _entryFile(key);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(payload),
        flush: true,
      );
      await _updateManifest(key, meta);
      await _enforceMaxZones();
    } catch (e) {
      if (kDebugMode) debugPrint('[OracleCache] write falhou $key: $e');
    }
  }

  Future<void> _updateManifest(String key, OracleCacheMeta meta) async {
    final manifest = await _readManifest();
    manifest.removeWhere((e) => e['key'] == key);
    manifest.add({
      'key': key,
      'lat': meta.lat,
      'lon': meta.lon,
      'label': meta.label,
      'fetchedAt': meta.fetchedAt.toIso8601String(),
      'validUntil': meta.validUntil.toIso8601String(),
      'priority': meta.priority,
    });
    final f = await _manifestFile();
    await f.writeAsString(jsonEncode({'zones': manifest}), flush: true);
  }

  Future<List<Map<String, dynamic>>> _readManifest() async {
    try {
      final f = await _manifestFile();
      if (!await f.exists()) return [];
      final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return (j['zones'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
    } catch (_) {
      return [];
    }
  }

  Future<void> _enforceMaxZones() async {
    final manifest = await _readManifest();
    if (manifest.length <= maxZones) return;
    manifest.sort((a, b) {
      // Evict oldest normal zones first; keep favorites until last.
      final pa = a['priority'] == 'favorite' ? 1 : 0;
      final pb = b['priority'] == 'favorite' ? 1 : 0;
      if (pa != pb) return pa.compareTo(pb);
      return DateTime.parse(a['fetchedAt'] as String)
          .compareTo(DateTime.parse(b['fetchedAt'] as String));
    });
    while (manifest.length > maxZones) {
      final removed = manifest.removeAt(0);
      final key = removed['key'] as String;
      try {
        final file = await _entryFile(key);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    final f = await _manifestFile();
    await f.writeAsString(jsonEncode({'zones': manifest}), flush: true);
  }

  Future<void> purgeExpired() async {
    final manifest = await _readManifest();
    final kept = <Map<String, dynamic>>[];
    for (final e in manifest) {
      final validUntil = DateTime.tryParse(e['validUntil'] as String? ?? '');
      final key = e['key'] as String;
      if (validUntil != null && DateTime.now().isAfter(validUntil)) {
        try {
          final file = await _entryFile(key);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      } else {
        kept.add(e);
      }
    }
    final f = await _manifestFile();
    await f.writeAsString(jsonEncode({'zones': kept}), flush: true);
  }

  Future<List<({double lat, double lon, String label})>> listZones() async {
    final manifest = await _readManifest();
    return manifest
        .map(
          (e) => (
            lat: (e['lat'] as num).toDouble(),
            lon: (e['lon'] as num).toDouble(),
            label: e['label'] as String? ?? '',
          ),
        )
        .toList();
  }

  Future<Map<String, dynamic>?> readLatestJson() async {
    final manifest = await _readManifest();
    if (manifest.isEmpty) return null;
    manifest.sort(
      (a, b) => DateTime.parse(b['fetchedAt'] as String)
          .compareTo(DateTime.parse(a['fetchedAt'] as String)),
    );
    final key = manifest.first['key'] as String;
    try {
      final file = await _entryFile(key);
      if (!await file.exists()) return null;
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
