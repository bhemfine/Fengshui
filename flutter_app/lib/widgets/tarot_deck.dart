import 'dart:math';

import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../motion/motion.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

enum TarotPhase { idle, shuffling, arc, flipping, revealed }

class TarotDraw {
  const TarotDraw({required this.card, required this.reversed});
  final TarotCardData card;
  final bool reversed;
}

/// Drive the deck from a screen: controller.shuffle() / controller.reset().
class TarotDeckController extends ChangeNotifier {
  _TarotDeckState? _s;
  TarotPhase get phase => _s?._phase ?? TarotPhase.idle;
  void shuffle() => _s?._shuffle();
  void reset() => _s?._reset();
}

/// Seven backs: shuffle orbit (1.9s) → arc → tap one → 3D flip (1.1s).
class TarotDeck extends StatefulWidget {
  const TarotDeck({
    super.key,
    this.controller,
    this.cards = sampleTarotCards,
    this.onDrawn,
    this.onPhaseChanged,
    this.height = 280,
  });

  final TarotDeckController? controller;
  final List<TarotCardData> cards;
  final ValueChanged<TarotDraw>? onDrawn;
  final ValueChanged<TarotPhase>? onPhaseChanged;
  final double height;

  @override
  State<TarotDeck> createState() => _TarotDeckState();
}

class _TarotDeckState extends State<TarotDeck> with TickerProviderStateMixin {
  static const _n = 7;
  final _rng = Random();
  late final AnimationController _orbit = AnimationController(vsync: this, duration: Motion.tarotShuffle);
  late final AnimationController _settle = AnimationController(vsync: this, duration: Motion.tarotSettle);
  late final AnimationController _flip = AnimationController(vsync: this, duration: Motion.tarotFlip);
  TarotPhase _phase = TarotPhase.idle;
  int? _chosen;
  TarotDraw? _draw;

  @override
  void initState() {
    super.initState();
    widget.controller?._s = this;
  }

  @override
  void didUpdateWidget(covariant TarotDeck old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?._s = null;
      widget.controller?._s = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller?._s == this) widget.controller?._s = null;
    _orbit.dispose();
    _settle.dispose();
    _flip.dispose();
    super.dispose();
  }

  void _setPhase(TarotPhase p) {
    if (!mounted) return;
    setState(() => _phase = p);
    widget.onPhaseChanged?.call(p);
  }

  void _reset() {
    _orbit.stop();
    _settle.stop();
    _flip.stop();
    _orbit.value = 0;
    _settle.value = 0;
    _flip.value = 0;
    _chosen = null;
    _draw = null;
    _setPhase(TarotPhase.idle);
  }

  void _shuffle() {
    _reset();
    _setPhase(TarotPhase.shuffling);
    if (reduceMotion(context)) {
      _settle.value = 1;
      _setPhase(TarotPhase.arc);
      return;
    }
    _orbit.forward(from: 0).then((_) {
      if (!mounted || _phase != TarotPhase.shuffling) return;
      _setPhase(TarotPhase.arc);
      _settle.forward(from: 0);
    });
  }

  void _pick(int i) {
    if (_phase != TarotPhase.arc) return;
    final card = widget.cards[_rng.nextInt(widget.cards.length)];
    _draw = TarotDraw(card: card, reversed: _rng.nextInt(5) == 0);
    _chosen = i;
    _setPhase(TarotPhase.flipping);
    void done() {
      _setPhase(TarotPhase.revealed);
      final d = _draw;
      if (d != null) widget.onDrawn?.call(d);
    }

    if (reduceMotion(context)) {
      _flip.value = 1;
      done();
    } else {
      _flip.forward(from: 0).then((_) {
        if (mounted && _phase == TarotPhase.flipping) done();
      });
    }
  }

  // position + rotation (radians) for card i
  (Offset, double) _arc(int i) {
    final o = i - 3;
    return (Offset(o * 44.0, o.abs() * 8.0), o * 7 * pi / 180);
  }

  @override
  Widget build(BuildContext context) {
    final rm = reduceMotion(context);
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: Listenable.merge([_orbit, _settle, _flip]),
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (_phase == TarotPhase.shuffling && !rm)
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                  ),
                ),
              for (var i = 0; i < _n; i++)
                if (i != _chosen) _buildCard(i, rm),
              if (_chosen != null) _buildCard(_chosen!, rm),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(int i, bool rm) {
    Offset pos;
    double rot = 0;
    double scale = 1;
    double opacity = 1;
    double angle = 0;
    switch (_phase) {
      case TarotPhase.idle:
        pos = Offset(i * 0.6, -i * 0.6);
      case TarotPhase.shuffling:
        final k = _orbit.value;
        final a = k * pi * 4 + i * (pi * 2 / _n);
        final rad = 60 * sin(k * pi);
        pos = Offset(cos(a) * rad, sin(a) * rad * 0.5);
        rot = a * 20 * pi / 180;
      case TarotPhase.arc:
        final (p, r) = _arc(i);
        final s = Curves.ease.transform(_settle.value);
        pos = Offset.lerp(Offset.zero, p, s)!;
        rot = r * s;
      case TarotPhase.flipping:
      case TarotPhase.revealed:
        final (p, r) = _arc(i);
        if (i == _chosen) {
          final m = rm ? 1.0 : const Interval(0, 0.4, curve: Curves.ease).transform(_flip.value);
          pos = Offset.lerp(p, const Offset(0, -10), m)!;
          rot = r * (1 - m);
          scale = 1 + 0.25 * m;
          angle = rm ? pi : const Interval(0.4, 1, curve: Motion.flip).transform(_flip.value) * pi;
        } else {
          pos = p;
          rot = r;
          opacity = 0.12;
        }
    }

    final d = _draw;
    final showFront = angle > pi / 2 && d != null && i == _chosen;
    Widget face;
    if (rm && i == _chosen) {
      face = AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: showFront ? _Front(key: const ValueKey('f'), draw: d) : const _Back(key: ValueKey('b')),
      );
    } else {
      final m = Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..rotateY(showFront ? angle - pi : angle);
      face = Transform(
        alignment: Alignment.center,
        transform: m,
        child: showFront ? _Front(draw: d) : const _Back(),
      );
    }

    return Transform.translate(
      offset: pos,
      child: Transform.rotate(
        angle: rot,
        child: Transform.scale(
          scale: scale,
          child: AnimatedOpacity(
            opacity: opacity,
            duration: Duration(milliseconds: rm ? 200 : 500),
            child: Semantics(
              button: _phase == TarotPhase.arc,
              label: 'Card ${i + 1}',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _phase == TarotPhase.arc ? () => _pick(i) : null,
                child: SizedBox(width: 76, height: 120, child: face),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Back extends StatelessWidget {
  const _Back({super.key});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF18214D), Color(0xFF0C1230)],
          ),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.7)),
          boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 16, offset: Offset(0, 6))],
        ),
        padding: const EdgeInsets.all(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withValues(alpha: 0.4)),
          ),
        ),
      );
}

class _Front extends StatelessWidget {
  const _Front({super.key, required this.draw});
  final TarotDraw draw;

  @override
  Widget build(BuildContext context) {
    final inner = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.auto_awesome, size: 22, color: AppColors.gold2),
        const SizedBox(height: 6),
        Text(draw.card.name,
            textAlign: TextAlign.center, style: InkText.display(size: 12, height: 1.1)),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1636),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.gold2),
        boxShadow: [BoxShadow(color: const Color(0xFFE4DCC8).withValues(alpha: 0.12), blurRadius: 10)],
      ),
      child: draw.reversed ? Transform.rotate(angle: pi, child: inner) : inner,
    );
  }
}
