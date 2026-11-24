import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone/data/sample_data.dart';
import 'package:inkstone/motion/motion.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

class YearlyScreen extends StatelessWidget {
  const YearlyScreen({super.key});

  Widget _note(Widget child, bool first) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration:
            BoxDecoration(border: first ? null : const Border(top: BorderSide(color: AppColors.hairline))),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final body = InkText.body(height: 1.4);
    return InkstoneScaffold(
      children: [
        _YearSeg(onDay: () => context.go(Routes.today), onMonth: () => context.go(Routes.monthly)),
        const SizedBox(height: 10),
        const ScreenTitle(title: '2026 outlook', example: true, subtitle: 'A year to tidy, not to leap.'),
        const SizedBox(height: 12),
        MidnightButton(label: 'Read my BaZi', onPressed: () => context.go(Routes.bazi)),
        InkstoneCard(
          title: 'Key notes',
          source: SourceBadge.calculated,
          child: Column(children: [
            _note(
                Text.rich(TextSpan(children: [
                  TextSpan(text: 'Tai Sui', style: body),
                  TextSpan(text: " (太岁 — the year's ruling star)", style: InkText.body(size: 14, color: AppColors.ivory2)),
                  TextSpan(text: ' calm this year (example).', style: body),
                ])),
                true),
            _note(Text('Luck pillar: Fire decade, ages 32–41: visibility grows (example).', style: body), false),
            _note(
                Text.rich(TextSpan(children: [
                  TextSpan(text: 'Home Flying Stars', style: body),
                  TextSpan(
                      text: ' (飞星 — energy in each area of the home)',
                      style: InkText.body(size: 14, color: AppColors.ivory2)),
                  TextSpan(text: ': Wealth star 8 sits south-east, by your door (example).', style: body),
                ])),
                false),
          ]),
        ),
        const InkstoneCard(
          title: 'Sky chart',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ExampleBadge(label: 'Decorative'),
            SizedBox(height: 170, child: _Orbits()),
          ]),
        ),
        InkstoneCard(
          title: 'Month by month',
          example: true,
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 4.2,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              for (final m in yearMonths)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.centerLeft,
                  decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppColors.goldDim))),
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: '${m.$1} ',
                          style: InkText.body(size: 15, weight: FontWeight.w600, color: AppColors.gold2)),
                      TextSpan(text: m.$2, style: InkText.body(size: 15)),
                    ]),
                    maxLines: 2,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _YearSeg extends StatelessWidget {
  const _YearSeg({required this.onDay, required this.onMonth});
  final VoidCallback onDay;
  final VoidCallback onMonth;

  @override
  Widget build(BuildContext context) {
    Widget b(String l, VoidCallback? t, bool sel) => Expanded(
          child: Semantics(
            button: true,
            selected: sel,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: t,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: sel
                    ? BoxDecoration(
                        color: AppColors.silver.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)))
                    : null,
                child: Text(l,
                    style: InkText.body(
                        size: 15, weight: FontWeight.w600, color: sel ? AppColors.ivory : AppColors.ivory2, height: 1.2)),
              ),
            ),
          ),
        );
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xE00B1026),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.goldDim),
      ),
      child: Row(children: [b('Day', onDay, false), b('Month', onMonth, false), b('Year', null, true)]),
    );
  }
}

class _Orbits extends StatefulWidget {
  const _Orbits();
  @override
  State<_Orbits> createState() => _OrbitsState();
}

class _OrbitsState extends State<_Orbits> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 120));

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
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(size: Size.infinite, painter: _OrbitPainter(_c.value)),
        ),
      );
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final secs = t * 120;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.gold.withValues(alpha: 0.5);
    canvas.drawCircle(c, 40, ring);
    canvas.drawCircle(c, 70, ring);
    canvas.drawCircle(c, 80, ring..color = AppColors.gold.withValues(alpha: 0.1));
    canvas.drawCircle(c, 9, Paint()..color = AppColors.gold2);
    canvas.drawCircle(
        c,
        15,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = AppColors.gold2.withValues(alpha: 0.3));
    void orb(double r, double start, double period, double dir, double rad, Color col) {
      final a = start + dir * 2 * pi * (secs / period);
      canvas.drawCircle(c + Offset(cos(a) * r, sin(a) * r), rad, Paint()..color = col);
    }

    orb(40, 0, Motion.orbit1.inSeconds.toDouble(), 1, 3.5, AppColors.ivory);
    orb(70, -pi / 2, Motion.orbit2.inSeconds.toDouble(), -1, 4.5, AppColors.silver);
    orb(80, pi, Motion.orbit3.inSeconds.toDouble(), 1, 3, AppColors.goldHi);
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) => old.t != t;
}
