import 'package:flutter/material.dart';

import '../_shared.dart';
import '../../core/state/subscription_store.dart';

/// Card FOMO horizontal — lock + spot PRO + botão trial.
class OracleProSpotTeaser extends StatelessWidget {
  const OracleProSpotTeaser({
    super.key,
    required this.distanceLabel,
    required this.scoreLine,
    required this.unlockLabel,
    required this.speciesLabel,
    required this.onUnlock,
    this.source = 'oraculo_pro_spot',
  });

  final String distanceLabel;
  final String scoreLine;
  final String unlockLabel;
  final String speciesLabel;
  final VoidCallback onUnlock;
  final String source;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SubscriptionState>(
      valueListenable: SubscriptionStore.instance.value,
      builder: (context, sub, _) {
        if (sub.hasProEntitlement) return const SizedBox.shrink();

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onUnlock,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kAmber.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_rounded,
                        size: 16, color: kBg.withValues(alpha: 0.85)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          distanceLabel,
                          style: ibm(13, c: Colors.white, fw: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        _ProScoreRichText(line: scoreLine),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kAmber),
                      color: Colors.transparent,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('👑', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          unlockLabel,
                          style: ibm(10, c: kAmber, fw: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProScoreRichText extends StatelessWidget {
  const _ProScoreRichText({required this.line});

  final String line;

  @override
  Widget build(BuildContext context) {
    final scoreMatch = RegExp(r'Score (\d+)').firstMatch(line);
    final timeMatch = RegExp(r'(\d{2}:\d{2})').firstMatch(line);
    if (scoreMatch == null) {
      return Text(line, style: ibm(11, c: kHint));
    }
    final score = scoreMatch.group(1)!;
    final before = line.substring(0, scoreMatch.start);
    final mid = line.substring(scoreMatch.end, timeMatch?.start ?? line.length);
    final time = timeMatch?.group(1);
    final after = time != null ? line.substring(timeMatch!.end) : '';

    return RichText(
      text: TextSpan(
        style: ibm(11, c: kHint),
        children: [
          TextSpan(text: before),
          const TextSpan(text: 'Score '),
          TextSpan(
            text: score,
            style: ibm(11, c: kAmber, fw: FontWeight.w800),
          ),
          TextSpan(text: mid),
          if (time != null)
            TextSpan(
              text: time,
              style: ibm(11, c: kAmber, fw: FontWeight.w800),
            ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}
