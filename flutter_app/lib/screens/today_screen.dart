import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone_engine/inkstone_engine.dart' as eng;
import 'package:inkstone/data/content_repo.dart';
import 'package:inkstone/data/household.dart';
import 'package:inkstone/data/sample_data.dart' show DoubleHour;
import 'package:inkstone/data/your_year.dart';
import 'package:inkstone/motion/motion.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _hourRanges = [
  '11pm–1am', '1–3am', '3–5am', '5–7am', '7–9am', '9–11am',
  '11am–1pm', '1–3pm', '3–5pm', '5–7pm', '7–9pm', '9–11pm',
];

/// Today for the main user, worked out by the engine on the phone.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, this.now});

  /// Fixed clock for tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final n = now ?? DateTime.now();
    final me = mainUser;
    return FutureBuilder<AppContent>(
      future: ContentRepo.load(),
      builder: (context, snap) {
        final content = snap.data;
        final day = DateTime(n.year, n.month, n.day);
        final alm = eng.computeAlmanac(day);
        final chart = eng.computeBazi(birthLocal: me.birth, utcOffsetHours: 8, hourKnown: me.timeKnown);
        final score = eng.dailyScore(chart, day);
        final year = currentSolarYear(n);
        final yy = YourYear.compute(me, year, content);
        final luckyDir = me.kua.lucky.first;
        final colour = yy.lucky.luckyColours.first;
        final hours = [
          for (final b in eng.branches)
            DoubleHour(
              english: b.pinyin,
              chinese: b.chinese,
              meaning: b.animal,
              range: _hourRanges[b.index],
              isGood: alm.luckyHourBranches.any((x) => x.index == b.index),
            ),
        ];
        final goodHour = hours.firstWhere((h) => h.isGood, orElse: () => hours.first);
        final (headline, body) = content?.daily(score, n.day, {
              'name': shortName(me),
              'element': chart.dayMaster.element.english,
              'lucky_hour': '${goodHour.english} (${goodHour.range})',
              'lucky_direction': eng.directionLong[luckyDir.direction]!.toLowerCase(),
              'lucky_colour': colour,
            }) ??
            ('Today', '');
        final clashMe = alm.clashBranch.index == chart.year.branch.index;
        final officer = content?.officer(alm.officerIndex);
        String label(String t) => content?.activityLabel(t) ?? t;
        return InkstoneScaffold(
          children: [
            Row(children: [
              _Wheel(day: n.day),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${_weekdays[n.weekday - 1]}\n${_monthNames[n.month - 1]} ${n.year}',
                      style: InkText.display(size: 26, height: 1.1)),
                  const SizedBox(height: 4),
                  Text('Day ${alm.dayPillar.chinese} ${alm.dayPillar.pinyin}'
                      '${officer == null ? '' : ' · ${officer.$1}'}', style: InkText.small),
                  const SizedBox(height: 4),
                  Text('for ${shortName(me)}', style: InkText.small),
                ]),
              ),
            ]),
            InkstoneCard(
              key: const Key('today-card'),
              margin: const EdgeInsets.only(top: 8),
              source: SourceBadge.calculated,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  ScoreRing(value: score),
                  const SizedBox(width: 14),
                  Expanded(child: Text(headline, style: InkText.body(weight: FontWeight.w600, height: 1.35))),
                ]),
                const SizedBox(height: 8),
                if (body.isNotEmpty) Text(body, style: InkText.body(height: 1.5)),
                const SizedBox(height: 6),
                Text('Lucky: face ${eng.directionLong[luckyDir.direction]!.toLowerCase()} (${luckyDir.english}) when you work. '
                    'Lucky colour: $colour. Numbers: ${yy.lucky.luckyNumbers.join(', ')}.',
                    style: InkText.body(size: 15, height: 1.45)),
                if (clashMe)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('Today clashes with your ${yy.zodiac.animal} sign (${alm.dayPillar.branch.chinese}冲${chart.year.branch.chinese}). Keep plans light.',
                        style: InkText.body(size: 15, color: AppColors.care)),
                  ),
              ]),
            ),
            InkstoneCard(
              key: const Key('today-year'),
              title: 'Your year · ${yy.zodiac.name} ${yy.zodiac.pillar.chinese}',
              onTap: () => context.go(Routes.yearly),
              child: Text(
                '$year ${yy.taiSui.yearPillar.chinese}: ${yy.taiSui.chineseLabel} (${yy.taiSui.englishLabel}). '
                'Lucky colours ${yy.lucky.luckyColours.take(3).join(', ')}. Tap for the full year.',
                style: InkText.body(height: 1.45),
              ),
            ),
            InkstoneCard(
              title: 'Almanac',
              source: SourceBadge.calculated,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (officer != null) Text(officer.$2, style: InkText.small),
                AlmanacList(goodFor: alm.goodFor.map(label).toList(), avoid: alm.avoid.map(label).toList()),
                const SizedBox(height: 4),
                Text('Clashes with ${alm.clashBranch.animal} today.', style: InkText.small),
              ]),
            ),
            const SizedBox(height: 12),
            ButtonRow(
              first: MidnightButton(label: 'See this month', onPressed: () => context.go(Routes.monthly)),
              second: GhostButton(label: 'See this year', onPressed: () => context.go(Routes.yearly)),
            ),
            InkstoneCard(
              title: 'Double hours',
              source: SourceBadge.calculated,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.good)),
                  const SizedBox(width: 6),
                  Flexible(child: Text('Good hour for the day. Outlined: now.', style: InkText.small)),
                ]),
                const SizedBox(height: 8),
                DoubleHourStrip(hours: hours, currentIndex: eng.hourBranchFor(n.hour)),
                const SizedBox(height: 6),
                if (!me.timeKnown)
                  Text('Your own birth hour is unknown, so personal hour readings are unavailable.', style: InkText.small),
              ]),
            ),
          ],
        );
      },
    );
  }
}

class _Wheel extends StatefulWidget {
  const _Wheel({required this.day});
  final int day;
  @override
  State<_Wheel> createState() => _WheelState();
}

class _WheelState extends State<_Wheel> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Motion.ringSlow);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          width: 118,
          height: 118,
          child: Stack(alignment: Alignment.center, children: [
            RotationTransition(
              turns: _c,
              child: Container(
                width: 112,
                height: 112,
                alignment: Alignment.topCenter,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, border: Border.all(color: AppColors.gold.withValues(alpha: 0.7))),
                child: Container(
                    width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.goldHi)),
              ),
            ),
            Container(
              width: 98,
              height: 98,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, border: Border.all(color: AppColors.gold.withValues(alpha: 0.35))),
            ),
            Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.ink2,
                  border: Border.all(color: AppColors.gold2.withValues(alpha: 0.6))),
              child: Text('${widget.day}', style: InkText.display(size: 46, color: AppColors.ivory, height: 1)),
            ),
          ]),
        ),
      );
}
