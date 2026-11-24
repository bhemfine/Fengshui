import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone/data/sample_data.dart';
import 'package:inkstone/motion/motion.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InkstoneScaffold(
      children: [
        Row(children: [
          const _Wheel(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$todayWeekday\n$todayMonthYear', style: InkText.display(size: 26, height: 1.1)),
              const SizedBox(height: 4),
              Text(todayLunar, style: InkText.small),
              const SizedBox(height: 4),
              const ExampleBadge(),
            ]),
          ),
        ]),
        InkstoneCard(margin: const EdgeInsets.only(top: 8), child: Text(todayLucky, style: InkText.body(height: 1.5))),
        InkstoneCard(
          title: 'Almanac',
          source: SourceBadge.calculated,
          child: AlmanacList(goodFor: sampleAlmanac.goodFor, avoid: sampleAlmanac.avoid),
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
              Flexible(child: Text('Good hour. Outlined: now.', style: InkText.small)),
            ]),
            const SizedBox(height: 8),
            const DoubleHourStrip(currentIndex: sampleCurrentHourIndex),
          ]),
        ),
      ],
    );
  }
}

class _Wheel extends StatefulWidget {
  const _Wheel();
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
              child: Text('$todayDay', style: InkText.display(size: 46, color: AppColors.ivory, height: 1)),
            ),
          ]),
        ),
      );
}
