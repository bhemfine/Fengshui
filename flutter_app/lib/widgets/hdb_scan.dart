import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../motion/motion.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// Replays the scan from a screen ("Scan again").
class HdbScanController extends ChangeNotifier {
  void scan() => notifyListeners();
}

/// Stylised 4-room HDB plan: compass settle, sweep, 9 palaces lighting in sequence,
/// then Flying Star pairs. Tap a palace → onZoneTap(index). Static when reduced motion.
class HdbScan extends StatefulWidget {
  const HdbScan({
    super.key,
    this.controller,
    this.palaces = samplePalaces,
    this.facingDegrees = 142,
    this.facingLabel = '142° SE',
    this.selected,
    this.onZoneTap,
    this.onScanComplete,
    this.autoplay = true,
  });

  final HdbScanController? controller;
  final List<Palace> palaces;
  final double facingDegrees;
  final String? facingLabel;
  final int? selected;
  final ValueChanged<int>? onZoneTap;
  final VoidCallback? onScanComplete;
  final bool autoplay;

  @override
  State<HdbScan> createState() => _HdbScanState();
}

class _HdbScanState extends State<HdbScan> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Motion.floorScan);
  bool _started = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_scan);
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() {});
        widget.onScanComplete?.call();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (widget.autoplay && !reduceMotion(context)) {
        _c.forward(from: 0);
      } else {
        _c.value = 1;
      }
    }
  }

  @override
  void didUpdateWidget(covariant HdbScan old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_scan);
      widget.controller?.addListener(_scan);
    }
  }

  void _scan() {
    if (reduceMotion(context)) {
      _c.value = 1;
      widget.onScanComplete?.call();
    } else {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_scan);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.goldDim),
      ),
      child: ClipRect(
        child: AspectRatio(
          aspectRatio: 340 / 300,
          child: LayoutBuilder(builder: (context, box) {
            final scale = box.maxWidth / 340;
            return Semantics(
              label: 'Example 4-room HDB floor plan',
              child: GestureDetector(
                onTapUp: (d) {
                  if (_c.isAnimating) return;
                  final p = d.localPosition / scale;
                  for (var i = 0; i < hdbZoneRects.length; i++) {
                    if (hdbZoneRects[i].contains(p)) {
                      widget.onZoneTap?.call(i);
                      break;
                    }
                  }
                },
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) => CustomPaint(
                    size: Size.infinite,
                    painter: _PlanPainter(
                      progress: _c.value,
                      done: !_c.isAnimating && _c.value >= 1,
                      palaces: widget.palaces,
                      facing: widget.facingDegrees,
                      facingLabel: widget.facingLabel,
                      selected: widget.selected,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Palace rects in the 340×300 plan space (NW, N, NE, W, C, E, SW, S, SE).
const List<Rect> hdbZoneRects = [
  Rect.fromLTWH(10, 10, 106, 93),
  Rect.fromLTWH(116, 10, 107, 93),
  Rect.fromLTWH(223, 10, 107, 93),
  Rect.fromLTWH(10, 103, 106, 93),
  Rect.fromLTWH(116, 103, 107, 93),
  Rect.fromLTWH(223, 103, 107, 93),
  Rect.fromLTWH(10, 196, 106, 94),
  Rect.fromLTWH(116, 196, 107, 94),
  Rect.fromLTWH(223, 196, 107, 94),
];

const _rooms = <(Rect, String, Offset)>[
  (Rect.fromLTWH(10, 10, 110, 95), 'Master bedroom', Offset(65, 90)),
  (Rect.fromLTWH(120, 10, 100, 95), 'Bedroom 2', Offset(170, 90)),
  (Rect.fromLTWH(220, 10, 110, 95), 'Study (bedroom 3)', Offset(275, 90)),
  (Rect.fromLTWH(10, 105, 70, 90), 'Bath', Offset(45, 182)),
  (Rect.fromLTWH(80, 105, 250, 90), 'Living / dining', Offset(205, 182)),
  (Rect.fromLTWH(10, 195, 140, 95), 'Kitchen', Offset(80, 278)),
  (Rect.fromLTWH(150, 195, 180, 95), 'Entrance', Offset(240, 278)),
];

const _litOrder = [1, 2, 5, 8, 7, 6, 3, 0, 4];

class _PlanPainter extends CustomPainter {
  _PlanPainter({
    required this.progress,
    required this.done,
    required this.palaces,
    required this.facing,
    required this.facingLabel,
    required this.selected,
  });

  final double progress;
  final bool done;
  final List<Palace> palaces;
  final double facing;
  final String? facingLabel;
  final int? selected;

  static const _c = Offset(170, 150);

  void _text(Canvas canvas, String s, Offset baseline, TextStyle style) {
    final tp = TextPainter(text: TextSpan(text: s, style: style), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(baseline.dx - tp.width / 2, baseline.dy - tp.height * 0.8));
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint p, double dash, double gap) {
    final len = (b - a).distance;
    final dir = (b - a) / len;
    var d = 0.0;
    while (d < len) {
      final e = min(d + dash, len);
      canvas.drawLine(a + dir * d, a + dir * e, p);
      d = e + gap;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 340);

    final roomFill = Paint()..color = const Color(0xFF172049);
    final roomLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF9C8A6A);
    final label = InkText.body(size: 11, weight: FontWeight.w600, height: 1);
    for (final r in _rooms) {
      canvas.drawRect(r.$1, roomFill);
      canvas.drawRect(r.$1, roomLine);
      _text(canvas, r.$2, r.$3, label);
    }

    final t = progress * Motion.floorScan.inMilliseconds;
    final scanning = !done && progress < 1;

    // zones
    if (scanning) {
      final lit = (t / 220).floor() + 1;
      final p = Paint()..color = AppColors.gold.withValues(alpha: 0.12);
      for (var k = 0; k < min(lit, 9); k++) {
        canvas.drawRect(hdbZoneRects[_litOrder[k]], p);
      }
    }
    if (done && selected != null && selected! >= 0 && selected! < 9) {
      canvas.drawRect(hdbZoneRects[selected!], Paint()..color = AppColors.silver.withValues(alpha: 0.1));
    }

    // grid + stars
    if (done) {
      final g = Paint()
        ..color = AppColors.gold.withValues(alpha: 0.6)
        ..strokeWidth = 1;
      _dashed(canvas, const Offset(116, 10), const Offset(116, 290), g, 3, 4);
      _dashed(canvas, const Offset(223, 10), const Offset(223, 290), g, 3, 4);
      _dashed(canvas, const Offset(10, 103), const Offset(330, 103), g, 3, 4);
      _dashed(canvas, const Offset(10, 196), const Offset(330, 196), g, 3, 4);
      final cf = Paint()..color = AppColors.ink;
      final cs = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = AppColors.gold;
      final st = InkText.body(size: 12, weight: FontWeight.w700, color: AppColors.goldHi, height: 1);
      for (var i = 0; i < min(9, palaces.length); i++) {
        final c = hdbZoneRects[i].center;
        canvas.drawCircle(c, 18, cf);
        canvas.drawCircle(c, 18, cs);
        _text(canvas, '${palaces[i].mountain}·${palaces[i].water}', c.translate(0, 5), st);
      }
    }

    // sweep (0.9s → 2.4s)
    if (scanning && t >= 900 && t <= 2400) {
      final k = (t - 900) / 1500;
      canvas.save();
      canvas.translate(_c.dx, _c.dy);
      canvas.rotate(k * 2 * pi);
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(0, -190)
        ..arcToPoint(const Offset(130, -140), radius: const Radius.circular(190))
        ..close();
      final paint = Paint()
        ..shader = ui.Gradient.linear(const Offset(0, 0), const Offset(130, 0), [
          AppColors.gold2.withValues(alpha: 0),
          const Color(0xFFECE6D8).withValues(alpha: 0.45),
        ]);
      canvas.drawPath(path, paint);
      canvas.restore();
    }

    // compass
    double op;
    double sc = 1;
    double rot = 0;
    if (scanning) {
      final s = Motion.settle.transform((t / 1000).clamp(0.0, 1.0));
      op = s;
      sc = 1.6 - 0.6 * s;
      rot = -pi / 2 * (1 - s);
    } else {
      op = 0.55;
    }
    canvas.save();
    canvas.translate(_c.dx, _c.dy);
    canvas.rotate(rot);
    canvas.scale(sc);
    final cp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFD6C7A6).withValues(alpha: op);
    canvas.drawCircle(Offset.zero, 128, cp);
    for (var a = 0.0; a < 2 * pi; a += 6 / 120) {
      canvas.drawLine(Offset(sin(a) * 120, -cos(a) * 120), Offset(sin(a + 1 / 120) * 120, -cos(a + 1 / 120) * 120), cp);
    }
    final tick = Paint()
      ..strokeWidth = 1.6
      ..color = cp.color;
    canvas.drawLine(const Offset(0, -132), const Offset(0, -120), tick);
    canvas.drawLine(const Offset(0, 120), const Offset(0, 132), tick);
    canvas.drawLine(const Offset(-132, 0), const Offset(-120, 0), tick);
    canvas.drawLine(const Offset(120, 0), const Offset(132, 0), tick);
    _text(canvas, 'N', const Offset(0, -137),
        InkText.display(size: 11, color: AppColors.gold2.withValues(alpha: op), height: 1));
    final fr = facing * pi / 180;
    final end = Offset(sin(fr) * 106, -cos(fr) * 106);
    _dashed(canvas, Offset.zero, end, Paint()
      ..strokeWidth = 1.3
      ..color = cp.color, 4, 3);
    canvas.restore();

    if (facingLabel != null && !scanning) {
      final lp = _c + Offset(sin(fr) * 112, -cos(fr) * 112);
      _text(canvas, facingLabel!, Offset(lp.dx.clamp(40, 300), lp.dy.clamp(20, 296)),
          InkText.body(size: 11, weight: FontWeight.w600, color: AppColors.gold2, height: 1));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PlanPainter old) =>
      old.progress != progress || old.done != done || old.selected != selected || old.facing != facing;
}
