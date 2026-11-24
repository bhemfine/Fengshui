import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone/data/sample_data.dart';
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
  final _f = TextEditingController(text: 'South-east · 142° (example)');

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
    const reasons = [
      "South-east door suits Mei Lin's Kua 1 (example).",
      'Wealth star 8 sits by the door this period (example).',
      "Wei Hao's best directions face away from the door (example).",
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
            for (final (i, s) in houseCheckScores.indexed) ...[
              SizedBox(height: i == 0 ? 6 : 8),
              Text.rich(TextSpan(children: [
                TextSpan(text: '${s.$1} — ', style: InkText.body()),
                TextSpan(
                    text: s.$3 ? 'Good fit' : 'Take care',
                    style: InkText.body(color: s.$3 ? AppColors.good : AppColors.care)),
              ])),
              const SizedBox(height: 10),
              ScoreBar(value: s.$2, color: s.$3 ? AppColors.good : AppColors.care),
            ],
            const SizedBox(height: 6),
            Text('Birth time unknown — hour-based checks left out.', style: InkText.small),
          ]),
        ),
        const SizedBox(height: 12),
        MidnightButton(label: 'See the floor reading', onPressed: () => context.go(Routes.floorResult)),
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
