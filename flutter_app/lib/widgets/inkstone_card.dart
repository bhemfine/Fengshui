import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';
import 'example_badge.dart';

/// Panel card: radius 18, goldDim hairline, optional title + badges.
class InkstoneCard extends StatelessWidget {
  const InkstoneCard({
    super.key,
    required this.child,
    this.title,
    this.example = false,
    this.source,
    this.onTap,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 14),
    this.margin = const EdgeInsets.only(top: 12),
    this.borderColor,
  });

  final Widget child;
  final String? title;
  final bool example;
  final String? source;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    Widget content = child;
    if (title != null || example || source != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (title != null) Text(title!, style: InkText.h2),
              if (example) const ExampleBadge(),
              if (source != null) SourceBadge(label: source!),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      );
    }
    return Padding(
      padding: margin,
      child: Material(
        color: AppColors.cardFill,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: borderColor ?? AppColors.goldDim),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: SizedBox(width: double.infinity, child: content)),
        ),
      ),
    );
  }
}
