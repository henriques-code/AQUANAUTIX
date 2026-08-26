import 'package:flutter/material.dart';

/// Fotos de espécies: bundle local (`assets/species/{id}.jpg`) com fallback à rede.
class SpeciesPhoto {
  SpeciesPhoto._();

  static const bundleDir = 'assets/species';

  static String bundledAsset(String id) => '$bundleDir/$id.jpg';

  static ImageProvider provider({
    required String id,
    required String photoUrl,
  }) {
    return AssetImage(bundledAsset(id));
  }

  /// Prioridade: asset local → URL remota → [placeholder].
  static Widget image({
    required String id,
    required String photoUrl,
    required String emoji,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? loading,
  }) {
    final placeholder = _EmojiPlaceholder(emoji: emoji, width: width, height: height);

    return Image.asset(
      bundledAsset(id),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) {
        if (photoUrl.isEmpty) return placeholder;
        return Image.network(
          photoUrl,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return loading ??
                Container(
                  width: width,
                  height: height,
                  color: const Color(0xFF0D1F35),
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                );
          },
          errorBuilder: (_, __, ___) => placeholder,
        );
      },
    );
  }
}

class _EmojiPlaceholder extends StatelessWidget {
  const _EmojiPlaceholder({
    required this.emoji,
    this.width,
    this.height,
  });

  final String emoji;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF0D1F35),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 48)),
    );
  }
}
