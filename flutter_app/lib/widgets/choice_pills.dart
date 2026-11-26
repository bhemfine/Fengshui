import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';

/// Single-choice pills in the B3 style: hairline gold edge, filled when picked.
class ChoicePills<T> extends StatelessWidget {
  const ChoicePills({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.isSelected,
  });

  final List<(T, String)> options;
  final T? selected;
  final ValueChanged<T> onSelected;

  /// Override for multi-select use.
  final bool Function(T value)? isSelected;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (v, label) in options)
            InkPill(
              label: label,
              selected: isSelected?.call(v) ?? v == selected,
              onTap: () => onSelected(v),
            ),
        ],
      );
}

class InkPill extends StatelessWidget {
  const InkPill({super.key, required this.label, required this.selected, this.onTap, this.color});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Accent for the selected state (defaults to champagne gold).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.gold2;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? accent.withValues(alpha: 0.16) : AppColors.field,
        shape: StadiumBorder(side: BorderSide(color: selected ? accent : AppColors.goldDim)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: InkText.body(
                      size: 15,
                      color: selected ? AppColors.ivory : AppColors.ivory2,
                      weight: selected ? FontWeight.w600 : FontWeight.w400)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small tag such as a school label ("Classical", "Black Hat").
class InkTag extends StatelessWidget {
  const InkTag({super.key, required this.label, this.color = AppColors.gold});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Text(label, style: InkText.body(size: 12, color: color, height: 1.3)),
      );
}

/// Label + child block used by forms.
class FieldBlock extends StatelessWidget {
  const FieldBlock({super.key, required this.label, required this.child, this.hint});
  final String label;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: InkText.body(size: 15, color: AppColors.ivory2)),
          if (hint != null) Text(hint!, style: InkText.caption),
          const SizedBox(height: 8),
          child,
        ]),
      );
}
