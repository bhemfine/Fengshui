import 'package:flutter/material.dart';
import 'package:inkstone/data/sample_data.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

class CompatibilityScreen extends StatelessWidget {
  const CompatibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget list(String title, Color c, List<String> items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: InkText.h2.copyWith(color: c)),
            const SizedBox(height: 4),
            for (final s in items) Text(s, style: InkText.body(size: 15, height: 1.55)),
          ],
        );
    return InkstoneScaffold(
      title: 'Compatibility',
      showBack: true,
      example: true,
      fallbackRoute: Routes.readings,
      stickyCta: MidnightButton(
          label: 'Share result', onPressed: () => showInkSnack(context, 'Link copied (example)')),
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('${meiLin.name} and ${weiHao.name}', style: InkText.small),
            const SourceBadge(label: SourceBadge.calculated),
          ],
        ),
        InkstoneCard(
          child: Row(children: [
            const ScoreRing(value: compatibilityScore),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Good fit', style: InkText.body(weight: FontWeight.w600, color: AppColors.good)),
                Text('Fire meets Earth: he steadies, she warms.', style: InkText.body(height: 1.5)),
              ]),
            ),
          ]),
        ),
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.care.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.care.withValues(alpha: 0.45)),
          ),
          child: Text("Wei Hao's birth time is unknown. Hour-based results are unavailable.",
              style: InkText.body(size: 15)),
        ),
        InkstoneCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: list('Good together', AppColors.good,
                    const ['Shared goals at home', 'Patient with each other', 'Year pillars combine'])),
            const SizedBox(width: 10),
            Expanded(
                child: list('Take care', AppColors.care,
                    const ['Spending styles', 'Rushed decisions', 'Busy months clash'])),
          ]),
        ),
        InkstoneCard(
          child: Text.rich(TextSpan(children: [
            TextSpan(text: 'Communication tip: ', style: InkText.body(weight: FontWeight.w600)),
            TextSpan(text: 'Talk money on calm weekends, not late at night.', style: InkText.body(height: 1.5)),
          ])),
        ),
      ],
    );
  }
}
