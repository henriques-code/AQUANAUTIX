import 'package:flutter/material.dart';

import '../_shared.dart';

/// Accordion — meteorologia completa, grelha 6, gráfico 12h, previsão 5 dias.
class OracleConditionsCollapsible extends StatefulWidget {
  const OracleConditionsCollapsible({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.initiallyExpanded = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<OracleConditionsCollapsible> createState() =>
      _OracleConditionsCollapsibleState();
}

class _OracleConditionsCollapsibleState
    extends State<OracleConditionsCollapsible> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0A1520),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kHint.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.title} · ${widget.subtitle}',
                        style: ibm(12, c: kHint),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      _open
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: kCyan.withValues(alpha: 0.8),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_open) ...[
            Divider(height: 1, color: kCyan.withValues(alpha: 0.1)),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
              child: widget.child,
            ),
          ],
        ],
      ),
    );
  }
}
