import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';

/// Sticky footer: ink fill, hairline top border, optional note above the CTA.
class StickyCta extends StatelessWidget {
  const StickyCta({super.key, required this.child, this.note});

  final Widget child;
  final String? note;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.ink,
          border: Border(top: BorderSide(color: AppColors.goldDim)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (note != null) ...[Text(note!, style: InkText.small), const SizedBox(height: 8)],
                child,
              ],
            ),
          ),
        ),
      );
}
