import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';

/// Outlined champagne pill reading "EXAMPLE" (or custom label).
class ExampleBadge extends StatelessWidget {
  const ExampleBadge({super.key, this.label = 'Example'});
  final String label;

  @override
  Widget build(BuildContext context) => _Pill(label: label, color: AppColors.gold2, border: AppColors.goldDim);
}

/// Quieter source marker: Calculated / Read from your photo / From Master Tan.
class SourceBadge extends StatelessWidget {
  const SourceBadge({super.key, required this.label});
  final String label;

  static const calculated = 'Calculated';
  static const photo = 'Read from your photo';
  static const masterTan = 'From Master Tan';

  @override
  Widget build(BuildContext context) =>
      _Pill(label: label, color: AppColors.silver, border: AppColors.silver.withValues(alpha: 0.3));
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.border});
  final String label;
  final Color color;
  final Color border;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(label.toUpperCase(),
            style: InkText.body(size: 11, weight: FontWeight.w600, color: color, height: 1.4, letterSpacing: 0.9)),
      );
}

/// Toggleable pill chip (filters, time slots).
class InkChip extends StatelessWidget {
  const InkChip({super.key, required this.label, this.selected = false, this.onTap});
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? AppColors.gold2 : AppColors.cardFill,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? AppColors.gold2 : AppColors.goldDim),
              ),
              child: Text(label,
                  style: InkText.body(
                      size: 15, weight: FontWeight.w600, color: selected ? AppColors.ink : AppColors.ivory2, height: 1.3)),
            ),
          ),
        ),
      );
}
