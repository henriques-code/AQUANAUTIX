import 'dart:convert';

import '../species/species_catalog.dart';
import '../supabase_bootstrap.dart';
import 'vision_scan_result.dart';

/// Vision: identifica peixe + medidas estimadas via Edge Function `vision-scan`
/// (Supabase → OpenAI server-side) e cruza com [SpeciesCatalog].
///
/// A chave OpenAI nunca existe no cliente — vive apenas no ambiente da Edge
/// Function (`OPENAI_API_KEY` como secret do projeto Supabase).
class VisionScanService {
  VisionScanService._();
  static final VisionScanService instance = VisionScanService._();

  /// Analisa imagem (JPEG/PNG/WebP). Requer Supabase configurado.
  Future<VisionScanResult> analyzeImageBytes({
    required List<int> imageBytes,
    required String mimeType,
  }) async {
    final client = supabaseClientOrNull;
    if (client == null) {
      throw StateError('Supabase não configurado');
    }
    await SpeciesCatalog.instance.ensureLoaded();

    final b64 = base64Encode(imageBytes);

    final res = await client.functions.invoke(
      'vision-scan',
      body: {
        'image_base64': b64,
        'mime_type': mimeType,
      },
    );

    if (res.status != 200 || res.data == null) {
      throw Exception('Vision Edge Function HTTP ${res.status}');
    }

    final map = res.data is String
        ? jsonDecode(res.data as String) as Map<String, dynamic>
        : Map<String, dynamic>.from(res.data as Map);

    final scientific = (map['scientific_name'] as String?)?.trim();
    final length = _readDouble(map['length_cm']);
    final weight = _readDouble(map['weight_kg']);
    final conf = (map['confidence_0_100'] as num?)?.round().clamp(0, 100) ?? 50;

    final matched = SpeciesCatalog.instance.matchByScientific(scientific);

    return VisionScanResult(
      matchedSpecies: matched,
      rawScientific: scientific,
      lengthCm: length,
      weightKg: weight,
      confidence: conf,
      usedFallbackDemo: false,
    );
  }

  static double? _readDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.'));
    return null;
  }
}
