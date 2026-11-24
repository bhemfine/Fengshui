import 'dart:math';

import 'package:flutter/material.dart';

import '../motion/motion.dart';

/// One-shot particle burst (16–24 champagne specks). Nothing when reduced motion.
class StarBurst extends StatefulWidget {
  const StarBurst({super.key, this.origin = const Alignment(0, -0.5), this.play = true});

  final Alignment origin;
  final bool play;

  @override
  State<StarBurst> createState() => _StarBurstState();
}

class _P {
  _P(this.angle, this.dist, this.size, this.color, this.speed);
  final double angle, dist, size, speed;
  final Color color;
}

class _StarBurstState extends State<StarBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Motion.burst);
  late final List<_P> _ps;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final r = Random();
    const cols = [Color(0xFFE8D3A2), Color(0xFFF6EFE0), Color(0xFFD9BF86), Color(0xFFFFFAF0)];
    _ps = List.generate(16 + r.nextInt(9), (i) {
      return _P(r.nextDouble() * pi * 2, 50 + r.nextDouble() * 70, 4 + r.nextDouble() * 5, cols[i % 4],
          0.78 + r.nextDouble() * 0.22);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && widget.play && !reduceMotion(context)) {
      _started = true;
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => (_c.value == 0 || _c.value == 1)
            ? const SizedBox.expand()
            : CustomPaint(size: Size.infinite, painter: _BurstPainter(_ps, _c.value, widget.origin)),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.ps, this.t, this.origin);
  final List<_P> ps;
  final double t;
  final Alignment origin;

  @override
  void paint(Canvas canvas, Size size) {
    final o = origin.alongSize(size);
    final paint = Paint();
    for (final p in ps) {
      final k = Motion.settle.transform((t / p.speed).clamp(0.0, 1.0));
      final pos = o + Offset(cos(p.angle), sin(p.angle)) * p.dist * k;
      paint.color = p.color.withValues(alpha: 1 - k);
      canvas.drawCircle(pos, p.size / 2 * (1 - 0.4 * k), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.t != t;
}
