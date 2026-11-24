import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone/data/sample_data.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

class MonthlyScreen extends StatelessWidget {
  const MonthlyScreen({super.key});

  void _openDay(BuildContext context, int d) {
    final g = monthGoodDays.contains(d);
    final c = monthCareDays.contains(d);
    final txt = g
        ? 'A good day for signing papers and travel.'
        : c
            ? 'A take-care day: rest, and avoid big purchases.'
            : 'An ordinary day. Keep to your usual plans.';
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$d November 2026', style: InkText.h2),
          const SizedBox(height: 6),
          Text(txt, style: InkText.body()),
          const SizedBox(height: 8),
          const Wrap(spacing: 8, children: [ExampleBadge(), SourceBadge(label: SourceBadge.calculated)]),
          const SizedBox(height: 12),
          GhostButton(label: 'Close', onPressed: () => Navigator.of(ctx).pop()),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const wd = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return InkstoneScaffold(
      children: [
        _Seg(selected: 1, onDay: () => context.go(Routes.today), onYear: () => context.go(Routes.yearly)),
        const SizedBox(height: 10),
        const ScreenTitle(title: todayMonthYear, example: true),
        const SizedBox(height: 4),
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.good)),
          Text('Good day', style: InkText.small),
          const SizedBox(width: 4),
          Container(width: 10, height: 2, color: AppColors.care),
          Text('Take care', style: InkText.small),
          const SizedBox(width: 4),
          Text('Tap a day.', style: InkText.small),
        ]),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (final w in wd)
              Center(child: Text(w, style: InkText.body(size: 12, color: AppColors.gold2))),
            for (var i = 0; i < monthLeadingBlanks; i++) const SizedBox.shrink(),
            for (var d = 1; d <= monthDays; d++) _DayCell(day: d, onTap: () => _openDay(context, d)),
          ],
        ),
        const SizedBox(height: 12),
        MidnightButton(label: 'Open a day', onPressed: () => _openDay(context, todayDay)),
        InkstoneCard(
          title: 'Month outlook',
          source: SourceBadge.calculated,
          child: Column(children: [
            for (var i = 0; i < monthOutlook.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                    border: i == 0 ? null : const Border(top: BorderSide(color: AppColors.hairline))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 70, child: Text(monthOutlook[i].$1, style: InkText.body(weight: FontWeight.w600))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(monthOutlook[i].$2, style: InkText.body(height: 1.4))),
                ]),
              ),
          ]),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.onTap});
  final int day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = monthGoodDays.contains(day);
    final c = monthCareDays.contains(day);
    final t = day == todayDay;
    return Semantics(
      button: true,
      label: '$day November${g ? ', good day' : ''}${c ? ', take care' : ''}${t ? ', today' : ''}',
      child: Material(
        color: t ? AppColors.gold.withValues(alpha: 0.14) : const Color(0x8C0B1026),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: t ? AppColors.gold2 : Colors.transparent)),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: ExcludeSemantics(
            child: Stack(alignment: Alignment.center, children: [
              Text('$day', style: InkText.body(size: 15, weight: FontWeight.w600)),
              if (g)
                Positioned(
                    bottom: 5,
                    child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.good))),
              if (c) Positioned(bottom: 4, child: Container(width: 10, height: 2, color: AppColors.care)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  // ignore: unused_element_parameter
  const _Seg({required this.selected, this.onDay, this.onMonth, this.onYear});
  final int selected;
  final VoidCallback? onDay;
  final VoidCallback? onMonth;
  final VoidCallback? onYear;

  @override
  Widget build(BuildContext context) {
    final labels = ['Day', 'Month', 'Year'];
    final taps = [onDay, onMonth, onYear];
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xE00B1026),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.goldDim),
      ),
      child: Row(children: [
        for (var i = 0; i < 3; i++)
          Expanded(
            child: Semantics(
              button: true,
              selected: i == selected,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: i == selected ? null : taps[i],
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: i == selected
                      ? BoxDecoration(
                          color: AppColors.silver.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)))
                      : null,
                  child: Text(labels[i],
                      style: InkText.body(
                          size: 15,
                          weight: FontWeight.w600,
                          color: i == selected ? AppColors.ivory : AppColors.ivory2,
                          height: 1.2)),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
