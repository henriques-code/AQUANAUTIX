import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Gera PNG a partir de um [RepaintBoundary] e abre o sheet de partilha do SO.
abstract final class VisionShareService {
  static Future<Uint8List?> capturePng(GlobalKey boundaryKey,
      {double pixelRatio = 3.0}) async {
    final ctx = boundaryKey.currentContext;
    if (ctx == null) return null;
    final boundary = ctx.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return null;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  static Future<bool> sharePngBytes(
    Uint8List pngBytes, {
    String? shareText,
  }) async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/aquanautix_vision_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(path);
    await file.writeAsBytes(pngBytes, flush: true);
    final result = await Share.shareXFiles(
      [XFile(path, mimeType: 'image/png', name: 'aquanautix_vision.png')],
      text: shareText ??
          'Identificado com AQUANAUTIX — Oráculo de pesca ibérico 🎣\nhttps://aquanautix.vercel.app',
    );
    return result.status == ShareResultStatus.success ||
        result.status == ShareResultStatus.dismissed;
  }
}
