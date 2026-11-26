import 'package:flutter/material.dart';
import 'package:inkstone_engine/inkstone_engine.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';
import 'example_badge.dart';
import 'inkstone_card.dart';

/// Tai Sui, Year Breaker, Three Killings and the annual 5 / 2 stars for a year.
class YearAfflictionsCard extends StatelessWidget {
  const YearAfflictionsCard({super.key, required this.year, this.title});
  final int year;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final a = yearAfflictions(year);
    Widget row(String name, String zh, Direction d, String rule) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '$name ', style: InkText.body(weight: FontWeight.w600)),
            TextSpan(text: '($zh) ', style: InkText.body(size: 14, color: AppColors.ivory2)),
            TextSpan(text: '${directionLong[d]}', style: InkText.body(weight: FontWeight.w600, color: AppColors.care)),
            TextSpan(text: ' — $rule', style: InkText.body(size: 15, height: 1.4)),
          ])),
        );
    return InkstoneCard(
      title: title ?? '$year ${a.yearPillar.chinese}: directions to respect',
      source: SourceBadge.calculated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        row('Tai Sui', '太岁 ${a.taiSuiMountain.chinese}', a.taiSui, 'sit with it behind you, do not face it; no renovation.'),
        row('Year Breaker', '岁破 ${a.yearBreakerMountain.chinese}', a.yearBreaker, 'opposite Tai Sui; no renovation.'),
        row('Three Killings', '三煞 ${a.threeKillingsMountains.map((m) => m.chinese).join()}', a.threeKillings,
            'face it but do not sit with your back to it; no renovation.'),
        row('Five Yellow', '五黄', a.fiveYellow, 'the year\'s most troublesome star; keep still.'),
        row('Two Black', '二黑', a.twoBlack, 'illness star; keep calm, avoid long sleep there.'),
        const SizedBox(height: 6),
        Text('Year runs from Li Chun (about 4 Feb $year). Traditional rules, for reflection only.', style: InkText.small),
      ]),
    );
  }
}
