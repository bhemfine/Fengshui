import 'dart:math';

import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// Ring score with count-up (480ms ease-out); instant when reduced motion.
class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.value, this.size = 96, this.color = AppColors.good, this.max = 100});

  final int value;
  final double size;
  final Color color;
  final int max;

  @override
  Widget build(BuildContext context) {
    final rm = reduceMotion(context);
    return Semantics(
      label: 'Score $value out of $max',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: rm ? value.toDouble() : 0, end: value.toDouble()),
        duration: rm ? Duration.zero : Motion.countUp,
        curve: Motion.count,
        builder: (context, v, _) => SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(v / max, color),
            child: Center(
              child: ExcludeSemantics(child: Text('${v.round()}', style: InkText.score)),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.frac, this.color);
  final double frac;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - 6;
    final c = size.center(Offset.zero);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = AppColors.gold.withValues(alpha: 0.2);
    canvas.drawCircle(c, r, track);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -pi / 2, 2 * pi * frac.clamp(0.0, 1.0), false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.frac != frac || old.color != color;
}

/// Number + horizontal bar + "/100", counting up together.
class ScoreBar extends StatelessWidget {
  const ScoreBar({super.key, required this.value, this.color = AppColors.good, this.max = 100, this.showNumber = true});

  final int value;
  final Color color;
  final int max;
  final bool showNumber;

  @override
  Widget build(BuildContext context) {
    final rm = reduceMotion(context);
    return Semantics(
      label: 'Score $value out of $max',
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: rm ? value.toDouble() : 0, end: value.toDouble()),
          duration: rm ? Duration.zero : Motion.countUp,
          curve: Motion.count,
          builder: (context, v, _) => Row(
            children: [
              if (showNumber) SizedBox(width: 64, child: Text('${v.round()}', style: InkText.score)),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 6,
                    child: Stack(children: [
                      Container(color: AppColors.gold.withValues(alpha: 0.18)),
                      FractionallySizedBox(
                        widthFactor: (v / max).clamp(0.0, 1.0),
                        child: Container(color: color),
                      ),
                    ]),
                  ),
                ),
              ),
              if (showNumber) ...[const SizedBox(width: 12), Text('/$max', style: InkText.small)],
            ],
          ),
        ),
      ),
    );
  }
}
