import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/aqx_l10n.dart';
import '../../core/vision/vision_share_payload.dart';
import '../../core/vision/vision_share_service.dart';
import '../../core/widgets/aqx_ghost_mode_badge.dart';
import '../_shared.dart';
import 'vision_share_card.dart';

/// Sheet de pré-visualização + partilha real (SO) do resultado Vision.
Future<void> showVisionShareSheet(
  BuildContext context, {
  required VisionSharePayload payload,
}) async {
  final t = aqxL10nOf(context);
  final boundaryKey = GlobalKey();
  var sharing = false;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> doShare() async {
            if (sharing) return;
            setSheetState(() => sharing = true);
            HapticFeedback.mediumImpact();
            try {
              await Future.delayed(const Duration(milliseconds: 80));
              final png = await VisionShareService.capturePng(boundaryKey);
              if (png == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        t.es
                            ? 'No se pudo generar la imagen'
                            : 'Não foi possível gerar a imagem',
                        style: ibm(13),
                      ),
                    ),
                  );
                }
                return;
              }
              await VisionShareService.sharePngBytes(
                png,
                shareText: t.es
                    ? 'Identificado con AQUANAUTIX 🎣'
                    : 'Identificado com AQUANAUTIX 🎣',
              );
              if (context.mounted) Navigator.pop(context);
            } finally {
              if (context.mounted) setSheetState(() => sharing = false);
            }
          }

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kHint.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    t.es ? 'COMPARTIR CAPTURA' : 'PARTILHAR CAPTURA',
                    style: orb(11, c: kCyan, ls: 1.2),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: RepaintBoundary(
                      key: boundaryKey,
                      child: VisionShareCard(payload: payload),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AqxGhostModeBadge(size: 11, showPill: false),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          t.es
                              ? 'Zona aproximada · sin coordenadas exactas'
                              : 'Zona aproximada · sem coordenadas exactas',
                          style: mono(9, c: kHint),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: sharing ? null : doShare,
                      style: FilledButton.styleFrom(
                        backgroundColor: kCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: sharing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.share_outlined, size: 18),
                      label: Text(
                        sharing
                            ? (t.es ? 'PREPARANDO...' : 'A PREPARAR...')
                            : (t.es ? 'COMPARTIR' : 'PARTILHAR'),
                        style: orb(9, c: Colors.black, fw: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
