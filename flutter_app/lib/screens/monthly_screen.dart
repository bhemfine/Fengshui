import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone_engine/inkstone_engine.dart' as eng;
import 'package:inkstone/data/content_repo.dart';
import 'package:inkstone/data/household.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// The month for the main user: each day's score from the engine (almanac + BaZi).
class MonthlyScreen extends StatelessWidget {
  const MonthlyScreen({super.key, this.now});
  final DateTime? now;

  static const goodScore = 70;
  static const careScore = 40;

  @override
  Widget build(BuildContext context) {
    final n = now ?? DateTime.now();
    final me = mainUser;
    final chart = eng.computeBazi(birthLocal: me.birth, utcOffsetHours: 8, hourKnown: me.timeKnown);
    final days = DateTime(n.year, n.month + 1, 0).day;
    final blanks = DateTime(n.year, n.month, 1).weekday % 7; // Sunday-start grid
    final scores = [for (var d = 1; d <= days; d++) eng.dailyScore(chart, DateTime(n.year, n.month, d))];
    final monthName = '${_monthNames[n.month - 1]} ${n.year}';
    final solarIdx = eng.solarMonthIndex(DateTime.utc(n.year, n.month, n.day, 4));
    final liChunYear = eng.liChunYear(DateTime.utc(n.year, n.month, n.day, 4));
    final monthStar = eng.monthlyCentreStar(liChunYear, solarIdx);
    const wd = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    void openDay(int d) {
      final date = DateTime(n.year, n.month, d);
      final a = eng.computeAlmanac(date);
      final sc = scores[d - 1];
      final txt = sc >= goodScore
          ? 'A good day for you (score $sc).'
          : sc <= careScore
              ? 'A take-care day (score $sc): rest, and avoid big purchases.'
              : 'An ordinary day (score $sc). Keep to your usual plans.';
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$d ${_monthNames[n.month - 1]} ${n.year} · ${a.dayPillar.chinese}', style: InkText.h2),
            const SizedBox(height: 6),
            Text(txt, style: InkText.body()),
            Text('Good for: ${a.goodFor.isEmpty ? '—' : a.goodFor.join(', ').replaceAll('_', ' ')}', style: InkText.body(size: 15)),
            Text('Avoid: ${a.avoid.isEmpty ? '—' : a.avoid.join(', ').replaceAll('_', ' ')}', style: InkText.body(size: 15)),
            Text('Clashes with ${a.clashBranch.animal}.', style: InkText.small),
            const SizedBox(height: 8),
            const Wrap(spacing: 8, children: [SourceBadge(label: SourceBadge.calculated)]),
            const SizedBox(height: 12),
            GhostButton(label: 'Close', onPressed: () => Navigator.of(ctx).pop()),
          ]),
        ),
      );
    }

    return InkstoneScaffold(
      children: [
        _Seg(selected: 1, onDay: () => context.go(Routes.today), onYear: () => context.go(Routes.yearly)),
        const SizedBox(height: 10),
        ScreenTitle(title: monthName, subtitle: 'for ${shortName(me)} · day scores from your chart'),
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
            for (var i = 0; i < blanks; i++) const SizedBox.shrink(),
            for (var d = 1; d <= days; d++)
              _DayCell(
                day: d,
                monthName: _monthNames[n.month - 1],
                good: scores[d - 1] >= goodScore,
                care: scores[d - 1] <= careScore,
                today: d == n.day,
                onTap: () => openDay(d),
              ),
          ],
        ),
        const SizedBox(height: 12),
        MidnightButton(label: 'Open today', onPressed: () => openDay(n.day)),
        FutureBuilder<AppContent>(
          future: ContentRepo.load(),
          builder: (context, snap) {
            final m = snap.data?.month(solarIdx);
            final dm = chart.dayMaster.element.name;
            return InkstoneCard(
              title: m == null ? 'Month outlook' : 'Month outlook · ${m.zh} ${m.en}',
              source: 'Written guide + calculated',
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (m != null) ...[
                  Text(m.theme, style: InkText.body(height: 1.45)),
                  if (m.focus[dm] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('For your ${cap1(dm)} Day Master: ${m.focus[dm]}', style: InkText.body(height: 1.45)),
                    ),
                  const SizedBox(height: 8),
                  AlmanacList(goodFor: m.dos.take(4).toList(), avoid: m.avoids.take(4).toList()),
                ],
                const SizedBox(height: 6),
                Text('Monthly Flying Star in the centre: $monthStar. Solar months turn at the jie terms, not the 1st.',
                    style: InkText.small),
              ]),
            );
          },
        ),
      ],
    );
  }
}

String cap1(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.monthName,
    required this.good,
    required this.care,
    required this.today,
    required this.onTap,
  });
  final int day;
  final String monthName;
  final bool good;
  final bool care;
  final bool today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = good;
    final c = care;
    final t = today;
    return Semantics(
      button: true,
      label: '$day $monthName${g ? ', good day' : ''}${c ? ', take care' : ''}${t ? ', today' : ''}',
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
