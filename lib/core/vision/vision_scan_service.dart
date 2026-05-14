import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/openai_config.dart';
import '../species/species_catalog.dart';
import 'vision_scan_result.dart';

/// Vision GPT‑4o: identifica peixe + medidas estimadas; cruza com [SpeciesCatalog].
class VisionScanService {
  VisionScanService._();
  static final VisionScanService instance = VisionScanService._();

  final http.Client _client = http.Client();

  static const _endpoint = 'https://api.openai.com/v1/chat/completions';

  /// Analisa imagem (JPEG/PNG). Requer `OPENAI_API_KEY`.
  Future<VisionScanResult> analyzeImageBytes({
    required List<int> imageBytes,
    required String mimeType,
  }) async {
    if (!isOpenAiConfigured) {
      throw StateError('OPENAI_API_KEY em falta');
    }
    await SpeciesCatalog.instance.ensureLoaded();

    final b64 = base64Encode(imageBytes);
    final dataUrl = 'data:$mimeType;base64,$b64';

    const system = '''
És o motor de visão AQUANAUTIX. Identifica peixes do Atlântico NE / ibérico em contexto de pesca desportiva.
Responde APENAS com um objeto JSON válido (sem markdown), chaves exactas:
{"scientific_name":"","length_cm":null,"weight_kg":null,"confidence_0_100":0}

Regras:
- scientific_name: nome binomial latim quando possível (ex.: Dicentrarchus labrax). Se incerto, melhor esforço.
- length_cm: comprimento total estimado em cm, ou null se impossível.
- weight_kg: massa estimada em kg, ou null se impossível.
- confidence_0_100: 0–100 coerente com a nitidez da foto e incerteza.
''';

    final body = <String, dynamic>{
      'model': openAiChatModel,
      'response_format': const {'type': 'json_object'},
      'max_tokens': 400,
      'temperature': 0.25,
      'messages': [
        {'role': 'system', 'content': system},
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text':
                  'Analisa esta fotografia de peixe (captura ou na areia/rocha). Devolve só o JSON pedido.',
            },
            {
              'type': 'image_url',
              'image_url': {'url': dataUrl},
            },
          ],
        },
      ],
    };

    final res = await _client.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $openAiApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception('OpenAI Vision HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>?;
    final msg = choices?.isNotEmpty == true
        ? (choices!.first as Map<String, dynamic>)['message'] as Map<String, dynamic>?
        : null;
    final content = msg?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw Exception('Resposta Vision vazia');
    }

    final map = jsonDecode(content.trim()) as Map<String, dynamic>;
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
