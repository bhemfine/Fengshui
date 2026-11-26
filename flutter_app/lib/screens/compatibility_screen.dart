import 'package:flutter/material.dart';
import 'package:inkstone/data/example_charts.dart';
import 'package:inkstone/data/household.dart';
import 'package:inkstone_engine/inkstone_engine.dart'
    show directionShort, sharedGoodDirections, taiSuiRelations, TaiSuiRelation, zodiacForBirth;
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

class CompatibilityScreen extends StatelessWidget {
  const CompatibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final a = PersonChart(mainUser), b = PersonChart(partner);
    final (verdict, line, score, good) = dayMasterFit(a, b);
    final ka = mainUser.kua, kb = partner.kua;
    final shared = sharedGoodDirections([ka, kb]);
    final za = zodiacForBirth(mainUser.birth), zb = zodiacForBirth(partner.birth);
    final zRel = taiSuiRelations(za.branch.index, zb.branch.index)
        .map((r) => r == TaiSuiRelation.benMing ? 'Same sign 同肖' : '${r.english} ${r.chinese}')
        .toList();
    final unknown = [for (final p in [mainUser, partner]) if (!p.timeKnown) shortName(p)];
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
            Text('${mainUser.name} and ${partner.name}', style: InkText.small),
            const SourceBadge(label: SourceBadge.calculated),
          ],
        ),
        InkstoneCard(
          child: Row(children: [
            ScoreRing(value: score),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(verdict, style: InkText.body(weight: FontWeight.w600, color: good ? AppColors.good : AppColors.care)),
                Text('Day Masters ${a.dayMaster} and ${b.dayMaster}. $line', style: InkText.body(height: 1.5)),
              ]),
            ),
          ]),
        ),
        InkstoneCard(
          key: const Key('compat-zodiac'),
          title: 'Zodiac signs',
          source: SourceBadge.calculated,
          child: Text(
            '${shortName(mainUser)}: ${za.name} ${za.pillar.chinese} · ${shortName(partner)}: ${zb.name} ${zb.pillar.chinese}. '
            '${zRel.isEmpty ? 'No special clash or harmony between the signs.' : 'Signs: ${zRel.join(', ')}.'}',
            style: InkText.body(height: 1.45),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.care.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.care.withValues(alpha: 0.45)),
          ),
          child: Text(
              unknown.isEmpty
                  ? 'Both birth times are known.'
                  : '${unknown.join(' and ')}${unknown.length > 1 ? "'s birth times are" : "'s birth time is"} unknown. Hour-based results are unavailable.',
              style: InkText.body(size: 15)),
        ),
        InkstoneCard(
          title: 'Home directions (Kua)',
          source: SourceBadge.calculated,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${shortName(mainUser)}: Kua ${ka.kua}, ${ka.eastGroup ? 'East' : 'West'} group · good ${dirs(ka.lucky)}',
                style: InkText.body(size: 15, height: 1.5)),
            Text('${shortName(partner)}: Kua ${kb.kua}, ${kb.eastGroup ? 'East' : 'West'} group · good ${dirs(kb.lucky)}',
                style: InkText.body(size: 15, height: 1.5)),
            const SizedBox(height: 6),
            Text(
                shared.isEmpty
                    ? 'No shared good direction: a mixed couple. Pick the facing for the main earner and set beds and desks to each person\'s own good directions.'
                    : 'Shared good directions: ${shared.map((d) => directionShort[d]).join(', ')}.',
                style: InkText.body(size: 15, color: shared.isEmpty ? AppColors.care : AppColors.good, height: 1.5)),
          ]),
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
