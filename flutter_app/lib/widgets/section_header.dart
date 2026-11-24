import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';
import 'example_badge.dart';

/// Section heading (display 22, goldHi) with optional badges.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.example = false,
    this.source,
    this.trailing,
    this.padding = const EdgeInsets.only(top: 16, bottom: 4),
  });

  final String title;
  final bool example;
  final String? source;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(title, style: InkText.h2),
                  if (example) const ExampleBadge(),
                  if (source != null) SourceBadge(label: source!),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

/// Page title (h1, 30px) with the short gold rule underneath.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle({super.key, required this.title, this.example = false, this.subtitle, this.center = false, this.size = 30});

  final String title;
  final bool example;
  final String? subtitle;
  final bool center;
  final double size;

  @override
  Widget build(BuildContext context) {
    final align = center ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: center ? WrapAlignment.center : WrapAlignment.start,
          children: [
            Text(title, style: InkText.display(size: size, height: 1.1), textAlign: center ? TextAlign.center : null),
            if (example) const ExampleBadge(),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: 44,
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.gold, Color(0x00BFA577)]),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!,
              textAlign: center ? TextAlign.center : null,
              style: InkText.body(color: AppColors.ivory2)),
        ],
      ],
    );
  }
}
