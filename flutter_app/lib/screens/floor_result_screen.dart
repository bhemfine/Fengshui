import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone/data/sample_data.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

class FloorResultScreen extends StatefulWidget {
  const FloorResultScreen({super.key});
  @override
  State<FloorResultScreen> createState() => _FloorResultScreenState();
}

class _FloorResultScreenState extends State<FloorResultScreen> {
  final _scan = HdbScanController();
  bool _done = false;
  int? _sel;

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _sel == null ? null : samplePalaces[_sel!];
    return InkstoneScaffold(
      title: 'Your home reading',
      example: true,
      children: [
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, runSpacing: 4, children: [
          Text('Tampines 4-room · Faces SE 142° · Period 8 · completed 2012 (example)', style: InkText.small),
          const SourceBadge(label: SourceBadge.photo),
        ]),
        const SizedBox(height: 8),
        ButtonRow(
          first: MidnightButton(label: 'House check', onPressed: () => context.go(Routes.houseCheck)),
          second: GhostButton(label: 'Change plan', onPressed: () => context.go(Routes.floorUpload)),
        ),
        const SizedBox(height: 10),
        HdbScan(
          controller: _scan,
          selected: _sel,
          onZoneTap: (i) => setState(() => _sel = i),
          onScanComplete: () => setState(() => _done = true),
        ),
        if (!_done)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(children: [
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold2)),
              const SizedBox(width: 10),
              Text('Reading the plan…', style: InkText.body(size: 17, color: AppColors.gold2)),
            ]),
          )
        else ...[
          const SizedBox(height: 8),
          Term(
            english: 'Flying Stars',
            chinese: '飞星',
            meaning: 'energy in each area of the home',
            style: InkText.body(size: 14, color: AppColors.ivory2, height: 1.4),
          ),
          Text('Example. Tap any square for a tip.', style: InkText.small),
          InkstoneCard(
            child: Semantics(
              liveRegion: true,
              child: p == null
                  ? Text('Tap a square on the plan to see what its number means.', style: InkText.body(height: 1.5))
                  : Text.rich(TextSpan(children: [
                      TextSpan(
                          text: '${p.direction} · ${p.mountain}·${p.water}',
                          style: InkText.body(weight: FontWeight.w600)),
                      TextSpan(text: ' — ${p.tip}', style: InkText.body(height: 1.5)),
                    ])),
            ),
          ),
          InkstoneCard(
            title: 'Placement tips',
            example: true,
            child: Column(children: [
              for (final (i, t) in samplePlacementTips.indexed)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                      border: i == 0 ? null : const Border(top: BorderSide(color: AppColors.hairline))),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(
                      width: 96,
                      child: Row(children: [
                        Icon(t.good ? Icons.circle : Icons.change_history,
                            size: 14, color: t.good ? AppColors.good : AppColors.care),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(t.good ? 'Good' : 'Take care',
                              style: InkText.body(
                                  size: 14,
                                  weight: FontWeight.w600,
                                  color: t.good ? AppColors.good : AppColors.care)),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(TextSpan(children: [
                        TextSpan(text: t.room, style: InkText.body(weight: FontWeight.w600)),
                        TextSpan(text: ' — ${t.text}', style: InkText.body()),
                      ])),
                    ),
                  ]),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          GhostButton(label: 'See optional remedies', onPressed: () => context.go(Routes.shop)),
          LinkButton(
            label: 'Scan again',
            onPressed: () {
              setState(() {
                _done = false;
                _sel = null;
              });
              _scan.scan();
            },
          ),
        ],
      ],
    );
  }
}
