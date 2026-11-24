import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inkstone/motion/motion.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

enum _Stage { guide, reading, done }

class PalmScreen extends StatefulWidget {
  const PalmScreen({super.key});
  @override
  State<PalmScreen> createState() => _PalmScreenState();
}

class _PalmScreenState extends State<PalmScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _scan = AnimationController(vsync: this, duration: Motion.palmScan);
  _Stage _stage = _Stage.guide;
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    _scan.dispose();
    super.dispose();
  }

  void _read(bool take) {
    final rm = reduceMotion(context);
    setState(() => _stage = _Stage.reading);
    if (take) showInkSnack(context, 'Camera not used in prototype — example photo used');
    if (!rm) _scan.forward(from: 0);
    _t?.cancel();
    _t = Timer(Duration(milliseconds: rm ? 150 : 1100), () {
      if (mounted) setState(() => _stage = _Stage.done);
    });
  }

  void _reset() {
    _t?.cancel();
    _scan.value = 0;
    setState(() => _stage = _Stage.guide);
  }

  @override
  Widget build(BuildContext context) {
    final rm = reduceMotion(context);
    final done = _stage == _Stage.done;
    return InkstoneScaffold(
      title: 'Palm reading',
      showBack: true,
      example: true,
      fallbackRoute: Routes.readings,
      children: [
        const SizedBox(height: 10),
        Container(
          height: 250,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.field,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.goldDim),
          ),
          child: Stack(children: [
            Center(
              child: Semantics(
                label: 'Example hand outline',
                child: SizedBox(
                  height: 230,
                  width: 230 * 160 / 220,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: done ? 1 : 0),
                    duration: rm ? Duration.zero : const Duration(seconds: 1),
                    builder: (context, v, _) => CustomPaint(painter: _HandPainter(v)),
                  ),
                ),
              ),
            ),
            if (_stage == _Stage.reading && !rm)
              AnimatedBuilder(
                animation: _scan,
                builder: (context, _) => Positioned(
                  left: 0,
                  right: 0,
                  top: -50 + 300 * Curves.easeInOut.transform(_scan.value),
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.gold2.withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ),
        if (_stage == _Stage.guide) ...[
          const SizedBox(height: 6),
          Text('Line up your left palm. Good light, fingers apart.', style: InkText.body(color: AppColors.ivory2)),
          const SizedBox(height: 12),
          ButtonRow(
            first: MidnightButton(label: 'Use example photo', onPressed: () => _read(false)),
            second: GhostButton(label: 'Read my palm', onPressed: () => _read(true)),
          ),
          const SizedBox(height: 8),
          Text('Photos are read and then deleted. We do not keep them.', style: InkText.small),
        ],
        if (_stage == _Stage.reading)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(children: [
              const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold2)),
              const SizedBox(width: 10),
              Text('Reading your palm…', style: InkText.body(size: 17, color: AppColors.gold2)),
            ]),
          ),
        if (done) ...[
          const SizedBox(height: 12),
          ButtonRow(
            first: MidnightButton(
                label: 'Save reading', onPressed: () => showInkSnack(context, 'Reading saved (example)')),
            second: GhostButton(label: 'Retake photo', onPressed: _reset),
          ),
          InkstoneCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                const ExampleBadge(),
                const SourceBadge(label: SourceBadge.photo),
                Text('· Clear', style: InkText.small),
              ]),
              const _Line(n: 1, name: 'Heart line', color: AppColors.good, text: 'Long and curved: warm, open with feelings.', first: true),
              const _Line(n: 2, name: 'Head line', color: AppColors.gold2, text: 'Gently sloped: practical with room for ideas.'),
              const _Line(n: 3, name: 'Life line', color: AppColors.care, text: 'Wide arc: steady energy. Not a lifespan.'),
            ]),
          ),
        ],
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.n, required this.name, required this.color, required this.text, this.first = false});
  final int n;
  final String name;
  final Color color;
  final String text;
  final bool first;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(border: first ? null : const Border(top: BorderSide(color: AppColors.hairline))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.gold2)),
            child: Text('$n', style: InkText.body(size: 13, color: AppColors.gold2, height: 1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '$name ', style: InkText.body(weight: FontWeight.w600, color: color)),
              TextSpan(text: text, style: InkText.body(height: 1.4)),
            ])),
          ),
        ]),
      );
}

class _HandPainter extends CustomPainter {
  _HandPainter(this.p);
  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 160, size.height / 220);
    final hand = Path()
      ..moveTo(40, 210)
      ..lineTo(40, 120)
      ..lineTo(22, 70)
      ..quadraticBezierTo(18, 60, 28, 58)
      ..quadraticBezierTo(36, 58, 40, 70)
      ..lineTo(52, 100)
      ..lineTo(50, 30)
      ..quadraticBezierTo(50, 20, 58, 20)
      ..quadraticBezierTo(66, 20, 66, 30)
      ..lineTo(70, 90)
      ..lineTo(74, 18)
      ..quadraticBezierTo(74, 8, 82, 8)
      ..quadraticBezierTo(90, 8, 90, 18)
      ..lineTo(90, 90)
      ..lineTo(98, 28)
      ..quadraticBezierTo(100, 18, 108, 20)
      ..quadraticBezierTo(116, 22, 114, 32)
      ..lineTo(108, 96)
      ..lineTo(120, 50)
      ..quadraticBezierTo(124, 42, 131, 45)
      ..quadraticBezierTo(138, 48, 136, 58)
      ..lineTo(124, 130)
      ..quadraticBezierTo(118, 180, 110, 210)
      ..close();
    canvas.drawPath(hand, Paint()..color = const Color(0xCC172049));
    canvas.drawPath(
        hand,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..color = const Color(0xFFD6C7A6));
    if (p <= 0) return;
    void line(Offset a, Offset c, Offset b, Color col) {
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(c.dx, c.dy, b.dx, b.dy);
      for (final m in path.computeMetrics()) {
        canvas.drawPath(
            m.extractPath(0, m.length * p),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = col);
      }
    }

    line(const Offset(58, 120), const Offset(85, 105), const Offset(118, 115), AppColors.good);
    line(const Offset(52, 138), const Offset(85, 128), const Offset(112, 148), AppColors.gold2);
    line(const Offset(62, 122), const Offset(50, 160), const Offset(70, 200), AppColors.care);
  }

  @override
  bool shouldRepaint(covariant _HandPainter old) => old.p != p;
}
