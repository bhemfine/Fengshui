import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone/motion/motion.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

class FloorUploadScreen extends StatefulWidget {
  const FloorUploadScreen({super.key});
  @override
  State<FloorUploadScreen> createState() => _FloorUploadScreenState();
}

class _FloorUploadScreenState extends State<FloorUploadScreen> {
  static const _dirs = ['North', 'North-east', 'East', 'South-east', 'South', 'South-west', 'West', 'North-west'];
  int _deg = 142;
  bool _hasPlan = false;
  bool _reading = false;
  Timer? _t;

  String get _dir => _dirs[((_deg % 360) / 45).round() % 8];

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _load() => setState(() => _hasPlan = true);

  void _read() {
    _load();
    final d = reduceMotion(context) ? 150 : 1100;
    setState(() => _reading = true);
    _t?.cancel();
    _t = Timer(Duration(milliseconds: d), () {
      if (!mounted) return;
      setState(() => _reading = false);
      context.go(Routes.floorResult);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rm = reduceMotion(context);
    return InkstoneScaffold(
      title: 'Add your floor plan',
      showBack: true,
      fallbackRoute: Routes.floorResult,
      stickyCta: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        if (_reading) ...[
          Text('Reading your plan…', style: InkText.small),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: rm ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1100),
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 4,
                color: AppColors.gold2,
                backgroundColor: AppColors.gold.withValues(alpha: 0.2),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        MidnightButton(label: 'Read my home', onPressed: _reading ? null : _read),
      ]),
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xE60B1026),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.goldDim),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.space_dashboard_outlined, size: 44, color: AppColors.gold),
            const SizedBox(height: 10),
            if (_hasPlan)
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Text('Example plan loaded · 4-room HDB, Tampines',
                      style: InkText.body(color: AppColors.ivory2), textAlign: TextAlign.center),
                  const ExampleBadge(),
                ],
              )
            else
              Text('No plan chosen yet', style: InkText.body(color: AppColors.ivory2)),
          ]),
        ),
        const SizedBox(height: 12),
        ButtonRow(
          first: GhostButton(label: 'Use example plan', onPressed: _reading ? null : _read),
          second: GhostButton(
            label: 'Photograph a plan',
            onPressed: () {
              _load();
              showInkSnack(context, 'Camera not used in prototype — example plan loaded');
            },
          ),
        ),
        InkstoneCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Front door faces', style: InkText.body(size: 15, color: AppColors.ivory2)),
            const SizedBox(height: 6),
            Row(children: [
              InkIconButton(
                  icon: Icons.remove,
                  semanticLabel: 'Decrease bearing',
                  onTap: () => setState(() => _deg = (_deg + 359) % 360)),
              Expanded(
                child: Text('$_deg° $_dir (example)',
                    textAlign: TextAlign.center, style: InkText.body(size: 17)),
              ),
              InkIconButton(
                  icon: Icons.add,
                  semanticLabel: 'Increase bearing',
                  onTap: () => setState(() => _deg = (_deg + 1) % 360)),
            ]),
          ]),
        ),
        const SizedBox(height: 8),
        for (final (i, s) in const [
          'Lay the plan flat, in good light.',
          'Show all rooms, including the door.',
          'Stand at the door facing out to take the bearing.',
        ].indexed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration:
                BoxDecoration(border: i == 0 ? null : const Border(top: BorderSide(color: AppColors.hairline))),
            child: Text(s, style: InkText.small),
          ),
      ],
    );
  }
}
