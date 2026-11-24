import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../motion/motion.dart';
import '../theme/colors.dart';

/// Twinkling star canvas with a rare shooting star. Static when reduced motion.
class Starfield extends StatefulWidget {
  const Starfield({super.key, this.starCount = 120});

  final int starCount;

  @override
  State<Starfield> createState() => _StarfieldState();
}

class _Star {
  _Star(this.x, this.y, this.r, this.phase, this.speed, this.flare);
  final double x, y, r, phase, speed;
  final bool flare;
}

class _Shoot {
  _Shoot(this.x, this.y, this.start);
  final double x, y, start;
}

class _StarfieldState extends State<Starfield> with SingleTickerProviderStateMixin {
  final _rng = Random();
  final _time = ValueNotifier<double>(0);
  late final Ticker _ticker;
  late final List<_Star> _stars;
  _Shoot? _shoot;
  double _nextShoot = 8;
  bool _static = false;

  @override
  void initState() {
    super.initState();
    _stars = List.generate(widget.starCount, (_) {
      final big = _rng.nextDouble() < 0.06;
      return _Star(
        _rng.nextDouble(),
        _rng.nextDouble(),
        big ? 1.6 : _rng.nextDouble() * 0.9 + 0.3,
        _rng.nextDouble() * pi * 2,
        0.4 + _rng.nextDouble() * 1.2,
        big,
      );
    });
    _ticker = createTicker(_tick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _static = reduceMotion(context);
    if (_static) {
      if (_ticker.isActive) _ticker.stop();
      _shoot = null;
      _time.value = 0;
    } else if (!_ticker.isActive) {
      _nextShoot = 6 + _rng.nextDouble() * 8;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    if (_shoot == null && t >= _nextShoot) {
      _shoot = _Shoot(_rng.nextDouble() * 0.6, _rng.nextDouble() * 0.4, t);
      _nextShoot = t + 6 + _rng.nextDouble() * 8;
    }
    final s = _shoot;
    if (s != null && t - s.start > 0.85) _shoot = null;
    _time.value = t;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _SkyPainter(this),
        ),
      ),
    );
  }
}

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.s) : super(repaint: s._time);
  final _StarfieldState s;

  @override
  void paint(Canvas canvas, Size size) {
    final t = s._time.value;
    final fill = Paint();
    final line = Paint()..strokeWidth = 0.6;
    for (final st in s._stars) {
      final a = s._static ? 0.7 : (0.45 + 0.45 * sin(t * st.speed + st.phase)).clamp(0.0, 1.0);
      final c = Offset(st.x * size.width, st.y * size.height);
      fill.color = (st.flare ? AppColors.goldHi : AppColors.silver).withValues(alpha: a);
      canvas.drawCircle(c, st.r, fill);
      if (st.flare) {
        line.color = AppColors.goldHi.withValues(alpha: a * 0.5);
        canvas.drawLine(c.translate(-6, 0), c.translate(6, 0), line);
        canvas.drawLine(c.translate(0, -6), c.translate(0, 6), line);
      }
    }
    final sh = s._shoot;
    if (sh != null && !s._static) {
      final k = (t - sh.start) / 0.85 * 50;
      final p = Offset(sh.x * size.width + k * 6, sh.y * size.height + k * 2.4);
      final tail = p.translate(-60, -24);
      final paint = Paint()
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(colors: [
          AppColors.goldHi.withValues(alpha: 0),
          AppColors.goldHi.withValues(alpha: 0.8 * (1 - k / 50).clamp(0.0, 1.0)),
        ]).createShader(Rect.fromPoints(tail, p));
      canvas.drawLine(tail, p, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter old) => false;
}
