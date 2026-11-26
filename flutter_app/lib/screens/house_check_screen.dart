import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone/data/example_charts.dart';
import 'package:inkstone/data/household.dart';
import 'package:inkstone/data/sample_data.dart';
import 'package:inkstone_engine/inkstone_engine.dart' show directionAt, directionLong;
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

class HouseCheckScreen extends StatefulWidget {
  const HouseCheckScreen({super.key});
  @override
  State<HouseCheckScreen> createState() => _HouseCheckScreenState();
}

class _HouseCheckScreenState extends State<HouseCheckScreen> {
  final _a = TextEditingController(text: sampleHome.address);
  final _f = TextEditingController(
      text: '${directionLong[directionAt(sampleHome.facingDegrees.toDouble())]} · ${sampleHome.facingDegrees}° (example)');

  @override
  void dispose() {
    _a.dispose();
    _f.dispose();
    super.dispose();
  }

  Widget _field(String l, TextEditingController c) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l, style: InkText.body(size: 15, color: AppColors.ivory2)),
          const SizedBox(height: 5),
          TextField(controller: c, style: InkText.body(size: 15)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final facing = directionAt(sampleHome.facingDegrees.toDouble());
    final fits = [for (final p in [mainUser, partner]) homeFitFor(p, facing)];
    final dirName = directionLong[facing]!;
    final reasons = [
      for (final f in fits)
        '$dirName door is ${f.info.pinyin} (${f.info.english}) for ${shortName(f.person)}\'s Kua ${f.person.kua.kua}'
            '${f.good ? '' : '; good directions are ${dirs(f.person.kua.lucky)}'} (example).',
      'Wealth star 8 sits by the door this period (example).',
    ];
    return InkstoneScaffold(
      title: 'House check',
      showBack: true,
      example: true,
      fallbackRoute: Routes.floorResult,
      children: [
        _field('Address', _a),
        _field('Front door', _f),
        InkstoneCard(
          title: 'Couple fit',
          example: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final (i, f) in fits.indexed) ...[
              SizedBox(height: i == 0 ? 6 : 8),
              Text.rich(TextSpan(children: [
                TextSpan(text: '${shortName(f.person)} · Kua ${f.person.kua.kua} — ', style: InkText.body()),
                TextSpan(
                    text: f.good ? 'Good fit' : 'Take care',
                    style: InkText.body(color: f.good ? AppColors.good : AppColors.care)),
              ])),
              const SizedBox(height: 10),
              ScoreBar(value: f.score, color: f.good ? AppColors.good : AppColors.care),
            ],
            const SizedBox(height: 6),
            Text('Birth times unknown — hour-based checks left out. Scores rank the facing within each person\'s 8 directions.', style: InkText.small),
          ]),
        ),
        const SizedBox(height: 12),
        MidnightButton(label: 'See the floor reading', onPressed: () => context.go(Routes.floorResult)),
        const SizedBox(height: 10),
        ButtonRow(
          first: GhostButton(label: 'Quick check', onPressed: () => context.push(Routes.quickCheck)),
          second: GhostButton(label: 'Home checklist', onPressed: () => context.push(Routes.homeChecklist)),
        ),
        InkstoneCard(
          title: 'Why',
          source: SourceBadge.calculated,
          child: Column(children: [
            for (final (i, r) in reasons.indexed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                    border: i == 0 ? null : const Border(top: BorderSide(color: AppColors.hairline))),
                child: Text(r, style: InkText.body(height: 1.4)),
              ),
          ]),
        ),
      ],
    );
  }
}
