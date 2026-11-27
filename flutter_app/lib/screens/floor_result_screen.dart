import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone/data/current_home.dart';
import 'package:inkstone/data/sample_data.dart' show Palace;
import 'package:inkstone/data/home_plan_store.dart';
import 'package:inkstone/data/household.dart';
import 'package:inkstone/data/your_year.dart' show currentSolarYear;
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';
import 'package:inkstone_engine/inkstone_engine.dart';

class FloorResultScreen extends StatefulWidget {
  const FloorResultScreen({super.key});
  @override
  State<FloorResultScreen> createState() => _FloorResultScreenState();
}

class _FloorResultScreenState extends State<FloorResultScreen> {
  final _scan = HdbScanController();
  bool _done = false;
  int? _sel;
  SavedPlan? _saved;

  @override
  void initState() {
    super.initState();
    currentHome.addListener(_rebuild);
    _loadPlan();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _loadPlan() async {
    final p = await HomePlanStore.load();
    if (!mounted) return;
    setState(() {
      _saved = p;
      if (p != null) _done = true;
    });
  }

  @override
  void dispose() {
    currentHome.removeListener(_rebuild);
    _scan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final home = currentHome.value;
    final palaces = planPalaces(home);
    final year = currentSolarYear();
    final tips = placementTips(home, year);
    final hasPhoto = _saved != null && _saved!.file.existsSync();
    final Palace? p;
    if (_sel == null) {
      p = null;
    } else if (hasPhoto) {
      final d = palacesInGridOrder(nearestPalace(home.facingDegrees))[_sel!];
      final stars = home.chart.palaces[d]!;
      p = Palace(
        direction: directionLong[d]!,
        mountain: stars.mountain,
        water: stars.facing,
        tip: palaceTip(stars, home.period),
      );
    } else {
      p = palaces[_sel!];
    }
    final mainChart = computeBazi(
      birthLocal: mainUser.timeKnown
          ? mainUser.birth
          : DateTime(mainUser.birth.year, mainUser.birth.month, mainUser.birth.day, 12),
      utcOffsetHours: 8,
      hourKnown: mainUser.timeKnown,
    );
    final partnerChart = computeBazi(
      birthLocal: partner.timeKnown
          ? partner.birth
          : DateTime(partner.birth.year, partner.birth.month, partner.birth.day, 12),
      utcOffsetHours: 8,
      hourKnown: partner.timeKnown,
    );
    return InkstoneScaffold(
      title: 'Your home reading',
      example: home.example,
      children: [
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, runSpacing: 4, children: [
          Text(
              '${home.label} · Faces ${home.facing.label} · Period ${home.period} · completed ${home.completionYear}'
              '${home.example ? ' (example; run the quick check to use your home)' : ''}',
              style: InkText.small),
          const SourceBadge(label: SourceBadge.calculated),
        ]),
        if (home.facing.isLineFacing)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Facing is within 3° of a sector line: some schools use a replacement chart (not shown yet).',
                style: InkText.body(size: 14, color: AppColors.care)),
          ),
        const SizedBox(height: 8),
        ButtonRow(
          first: MidnightButton(label: 'House check', onPressed: () => context.go(Routes.houseCheck)),
          second: GhostButton(label: 'Change plan', onPressed: () => context.go(Routes.floorUpload)),
        ),
        const SizedBox(height: 10),
        if (hasPhoto)
          FloorPlanOverlay(
            home: home,
            image: File(_saved!.file.path),
            selected: _sel,
            onZoneTap: (i) => setState(() {
              _sel = i;
              _done = true;
            }),
          )
        else
          HdbScan(
            controller: _scan,
            palaces: palaces,
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
          Text(
              'Period ${home.period} chart from the engine (mountain·water star). '
              '${home.chart.formations.isEmpty ? '' : 'Chart type: ${home.chart.formations.map(_formationName).join(', ')}. '}'
              '${hasPhoto ? 'Your plan is shown with the facing palace at the bottom. ' : 'The plan drawing is a stylised 4-room layout. '}'
              'Tap any square for a tip.',
              style: InkText.small),
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
          FloorElementCard(
            floorRaw: home.floor,
            favourable: mainChart.favourableElements,
            unfavourable: unfavourableElements(mainChart),
            partnerFavourable: partnerChart.favourableElements,
          ),
          InkstoneCard(
            title: 'Placement tips',
            source: SourceBadge.calculated,
            child: Column(children: [
              for (final (i, t) in [for (final x in tips) (room: x.$1, text: x.$2, good: x.$3)].indexed)
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
          YearAfflictionsCard(year: year, title: '$year reno tips: directions to respect'),
          YearAfflictionsCard(year: year + 1, title: '${year + 1} (from Li Chun) for planning ahead'),
          const SizedBox(height: 12),
          GhostButton(label: 'See optional remedies', onPressed: () => context.go(Routes.shop)),
          if (!hasPhoto)
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

String _formationName(String f) => switch (f) {
      'wang_shan_wang_shui' => 'Prosperous Mountain and Water 旺山旺水',
      'shang_shan_xia_shui' => 'Reversed 上山下水',
      'double_facing' => 'Double stars at facing 双星到向',
      'double_sitting' => 'Double stars at sitting 双星到坐',
      'sum_of_ten_mountain' => 'Sum of ten (mountain) 合十',
      'sum_of_ten_facing' => 'Sum of ten (water) 合十',
      _ => f,
    };
