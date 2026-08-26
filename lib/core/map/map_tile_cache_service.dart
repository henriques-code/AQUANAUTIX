import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Cache de tiles do mapa para spots favoritos (modo praia offline).
class MapTileCacheService {
  MapTileCacheService._();
  static final MapTileCacheService instance = MapTileCacheService._();

  static const maxTilesPerSpot = 48;
  static const cacheTtl = Duration(days: 14);

  Directory? _root;
  final http.Client _client = http.Client();

  Future<Directory> _dir() async {
    if (_root != null) return _root!;
    final base = await getApplicationDocumentsDirectory();
    _root = Directory('${base.path}/map_tiles');
    if (!await _root!.exists()) await _root!.create(recursive: true);
    return _root!;
  }

  String cacheIdForUrl(String urlTemplate) {
    return urlTemplate.hashCode.toRadixString(16);
  }

  Future<File> tileFile({
    required String cacheId,
    required int z,
    required int x,
    required int y,
  }) async {
    final d = await _dir();
    final dir = Directory('${d.path}/$cacheId/$z');
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/${x}_$y.png');
  }

  Future<bool> hasTile({
    required String cacheId,
    required int z,
    required int x,
    required int y,
  }) async {
    final f = await tileFile(cacheId: cacheId, z: z, x: x, y: y);
    if (!await f.exists()) return false;
    final age = DateTime.now().difference(await f.lastModified());
    if (age > cacheTtl) {
      try {
        await f.delete();
      } catch (_) {}
      return false;
    }
    return true;
  }

  String buildUrl({
    required String urlTemplate,
    required int z,
    required int x,
    required int y,
  }) {
    return urlTemplate
        .replaceAll('{z}', '$z')
        .replaceAll('{x}', '$x')
        .replaceAll('{y}', '$y');
  }

  /// Descarrega grelha de tiles ArcGIS/OSM à volta de um spot.
  Future<void> prefetchAroundSpot({
    required double lat,
    required double lon,
    required String urlTemplate,
    int minZoom = 11,
    int maxZoom = 14,
    double radiusDeg = 0.04,
  }) async {
    final cacheId = cacheIdForUrl(urlTemplate);
    var count = 0;
    for (var z = minZoom; z <= maxZoom; z++) {
      final minX = _lonToTileX(lon - radiusDeg, z);
      final maxX = _lonToTileX(lon + radiusDeg, z);
      final minY = _latToTileY(lat + radiusDeg, z);
      final maxY = _latToTileY(lat - radiusDeg, z);
      for (var x = minX; x <= maxX; x++) {
        for (var y = minY; y <= maxY; y++) {
          if (count >= maxTilesPerSpot) return;
          final exists = await hasTile(cacheId: cacheId, z: z, x: x, y: y);
          if (exists) continue;
          final url = buildUrl(urlTemplate: urlTemplate, z: z, x: x, y: y);
          try {
            final res = await _client
                .get(Uri.parse(url))
                .timeout(const Duration(seconds: 12));
            if (res.statusCode != 200 || res.bodyBytes.isEmpty) continue;
            final file = await tileFile(cacheId: cacheId, z: z, x: x, y: y);
            await file.writeAsBytes(res.bodyBytes, flush: true);
            count++;
          } catch (e) {
            if (kDebugMode) debugPrint('[MapTileCache] $z/$x/$y: $e');
          }
        }
      }
    }
  }

  Future<void> prefetchSavedSpots({
    required List<({double lat, double lon})> spots,
    required String urlTemplate,
  }) async {
    for (final s in spots) {
      await prefetchAroundSpot(
        lat: s.lat,
        lon: s.lon,
        urlTemplate: urlTemplate,
      );
    }
  }

  int _lonToTileX(double lon, int z) {
    final n = 1 << z;
    return ((lon + 180.0) / 360.0 * n).floor().clamp(0, n - 1);
  }

  int _latToTileY(double lat, int z) {
    final n = 1 << z;
    final latRad = lat * math.pi / 180.0;
    final y = (1.0 -
            math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) /
        2.0 *
        n;
    return y.floor().clamp(0, n - 1);
  }
}
