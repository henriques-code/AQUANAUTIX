import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

import 'map_tile_cache_service.dart';

/// TileProvider com leitura de disco + gravação em cache (spots favoritos).
class CachingTileProvider extends TileProvider {
  CachingTileProvider({
    required this.cacheId,
    Map<String, String>? headers,
    http.Client? httpClient,
  })  : _headers = headers != null ? Map<String, String>.from(headers) : {},
        _client = httpClient ?? http.Client();

  final String cacheId;
  final Map<String, String> _headers;
  final http.Client _client;

  @override
  Map<String, String> get headers => Map<String, String>.from(_headers);

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return _CachedTileImage(
      url: url,
      cacheId: cacheId,
      z: coordinates.z,
      x: coordinates.x,
      y: coordinates.y,
      headers: _headers,
      client: _client,
    );
  }
}

class _CachedTileImage extends ImageProvider<_CachedTileImage> {
  const _CachedTileImage({
    required this.url,
    required this.cacheId,
    required this.z,
    required this.x,
    required this.y,
    required this.headers,
    required this.client,
  });

  final String url;
  final String cacheId;
  final int z;
  final int x;
  final int y;
  final Map<String, String> headers;
  final http.Client client;

  @override
  Future<_CachedTileImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _CachedTileImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
    );
  }

  Future<ui.Codec> _loadAsync(
    _CachedTileImage key,
    ImageDecoderCallback decode,
  ) async {
    final cache = MapTileCacheService.instance;
    final file = await cache.tileFile(
      cacheId: key.cacheId,
      z: key.z,
      x: key.x,
      y: key.y,
    );
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) {
        final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
        return decode(buffer);
      }
    }

    final res = await client.get(Uri.parse(key.url), headers: key.headers);
    if (res.statusCode != 200 || res.bodyBytes.isEmpty) {
      throw Exception('Tile ${key.z}/${key.x}/${key.y} HTTP ${res.statusCode}');
    }
    try {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(res.bodyBytes, flush: true);
    } catch (_) {}

    final buffer = await ui.ImmutableBuffer.fromUint8List(res.bodyBytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    return other is _CachedTileImage &&
        other.url == url &&
        other.z == z &&
        other.x == x &&
        other.y == y;
  }

  @override
  int get hashCode => Object.hash(url, z, x, y);
}
