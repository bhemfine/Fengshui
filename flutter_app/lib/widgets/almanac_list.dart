import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';

/// Two columns: "Good for (宜)" mint, "Avoid (忌)" apricot.
class AlmanacList extends StatelessWidget {
  const AlmanacList({super.key, required this.goodFor, required this.avoid});

  final List<String> goodFor;
  final List<String> avoid;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _Col(title: 'Good for (宜)', items: goodFor, color: AppColors.good, good: true)),
          const SizedBox(width: 10),
          Expanded(child: _Col(title: 'Avoid (忌)', items: avoid, color: AppColors.care, good: false)),
        ],
      );
}

class _Col extends StatelessWidget {
  const _Col({required this.title, required this.items, required this.color, required this.good});
  final String title;
  final List<String> items;
  final Color color;
  final bool good;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: InkText.display(size: 18, color: color)),
          const SizedBox(height: 4),
          for (final s in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, right: 8),
                    child: good
                        ? Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle))
                        : Icon(Icons.change_history, size: 8, color: color),
                  ),
                  Expanded(child: Text(s, style: InkText.body(height: 1.5))),
                ],
              ),
            ),
        ],
      );
}
