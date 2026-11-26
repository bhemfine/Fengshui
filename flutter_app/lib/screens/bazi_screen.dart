import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone/data/example_charts.dart';
import 'package:inkstone/data/household.dart';
import 'package:inkstone/data/sample_data.dart';
import 'package:inkstone_engine/inkstone_engine.dart' show zodiacForBirth;
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

class BaziScreen extends StatelessWidget {
  const BaziScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = mainUser;
    final c = PersonChart(me);
    final pillars = c.pillars;
    final luck = c.luckPillars();
    final k = me.kua;
    final z = zodiacForBirth(me.birth);
    return InkstoneScaffold(
      title: 'Your BaZi',
      showBack: true,
      example: true,
      fallbackRoute: Routes.readings,
      stickyCta: MidnightButton(label: 'Ask a master', onPressed: () => context.go(Routes.masters)),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Term(english: 'BaZi', chinese: '八字', meaning: 'four pillars of destiny', style: InkText.small),
            Text('for ${me.name}', style: InkText.small),
            const SourceBadge(label: SourceBadge.calculated),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < pillars.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(child: _PillarCell(p: pillars[i])),
            ],
          ],
        ),
        InkstoneCard(
          child: Text.rich(TextSpan(children: [
            TextSpan(text: 'Day Master ', style: InkText.body(weight: FontWeight.w600)),
            TextSpan(text: '(日主 — your day element)', style: InkText.body(size: 14, color: AppColors.ivory2)),
            TextSpan(text: ': ${c.dayMaster}', style: InkText.body(weight: FontWeight.w600)),
            TextSpan(
                text: ' — the element that stands for you. ${c.dayMasterImage}${me.timeKnown ? '' : ' Birth time unknown, so the hour pillar is left out.'}',
                style: InkText.body(height: 1.5)),
          ])),
        ),
        InkstoneCard(
          key: const Key('bazi-zodiac'),
          title: 'Zodiac · ${z.name} ${z.pillar.chinese}',
          onTap: () => context.go(Routes.yearly),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Year element ${z.yearElement.english} (stem ${z.pillar.stem.chinese}) · '
                '${z.animal} fixed element ${z.animalElement.english} (branch ${z.branch.chinese}) · '
                'Na Yin ${z.naYin.chinese} ${z.naYin.english}', style: InkText.body(height: 1.45)),
            const SizedBox(height: 4),
            Text('Tap for your year: Tai Sui, lucky colours, numbers and directions.', style: InkText.small),
          ]),
        ),
        InkstoneCard(
          title: 'Element balance',
          child: Column(
            children: [
              for (final e in c.elementBalance)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(children: [
                    SizedBox(width: 62, child: Text(e.$1, style: InkText.body(size: 15))),
                    const SizedBox(width: 8),
                    Expanded(child: ScoreBar(value: e.$2, max: 8, color: AppColors.gold2, showNumber: false)),
                    const SizedBox(width: 8),
                    SizedBox(width: 20, child: Text('${e.$2}', style: InkText.body(size: 15))),
                  ]),
                ),
            ],
          ),
        ),
        InkstoneCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Term(english: 'Kua number', chinese: '卦', meaning: 'your personal direction number', style: InkText.h2),
              const SizedBox(height: 6),
              Text('Kua ${k.kua} · ${k.eastGroup ? 'East' : 'West'} group (example)', style: InkText.body()),
              Text('Good: ${dirs(k.lucky)}', style: InkText.body(color: AppColors.good)),
              Text('Take care: ${dirs(k.unlucky)}', style: InkText.body(color: AppColors.care)),
            ],
          ),
        ),
        InkstoneCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Term(english: 'Luck pillars', chinese: '大运', meaning: 'ten-year phases', style: InkText.h2),
              const SizedBox(height: 8),
              Row(children: [
                for (var i = 0; i < luck.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(child: _LuckCell(l: luck[i])),
                ],
              ]),
              const SizedBox(height: 6),
              Text('Starting age shown. Current phase outlined.', style: InkText.small),
            ],
          ),
        ),
      ],
    );
  }
}

class _PillarCell extends StatelessWidget {
  const _PillarCell({required this.p});
  final Pillar p;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '${p.label} pillar, ${p.element}',
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            color: const Color(0x990B1026),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.isSelf ? AppColors.gold2 : AppColors.goldDim),
          ),
          child: ExcludeSemantics(
            child: Column(children: [
              Text(p.label, style: InkText.body(size: 13, color: AppColors.gold2)),
              Text('${p.stem}\n${p.branch}',
                  textAlign: TextAlign.center, style: InkText.body(size: 24, height: 1.25)),
              Text(p.element, style: InkText.body(size: 13, color: AppColors.ivory2)),
            ]),
          ),
        ),
      );
}

class _LuckCell extends StatelessWidget {
  const _LuckCell({required this.l});
  final LuckPillar l;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: l.current ? AppColors.gold2 : AppColors.gold.withValues(alpha: 0.2),
            width: l.current ? 1.5 : 1,
          ),
        ),
        child: Column(children: [
          Text('${l.age}', style: InkText.body(size: 13, color: AppColors.ivory2)),
          Text(l.chinese, style: InkText.body(size: 17)),
        ]),
      );
}
