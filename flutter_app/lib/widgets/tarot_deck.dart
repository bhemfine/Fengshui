import 'dart:math';

import 'package:flutter/material.dart';

import '../data/tarot_art.dart';
import '../data/tarot_reading.dart';
import '../motion/motion.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

enum TarotPhase { idle, shuffling, arc, flipping, revealed }

/// Drive the deck from a screen: prepare draws, then shuffle / reset.
class TarotDeckController extends ChangeNotifier {
  _TarotDeckState? _s;
  TarotPhase get phase => _s?._phase ?? TarotPhase.idle;

  /// Cards to reveal, in pick order. Call before [shuffle].
  void prepare(List<TarotDrawn> draws) => _s?._prepare(draws);
  void shuffle() => _s?._shuffle();
  void reset() => _s?._reset();
}

/// Seven backs: shuffle orbit → arc → tap until the prepared spread is filled.
class TarotDeck extends StatefulWidget {
  const TarotDeck({
    super.key,
    this.controller,
    this.onRevealed,
    this.onPhaseChanged,
    this.height = 280,
  });

  final TarotDeckController? controller;
  final ValueChanged<List<TarotDrawn>>? onRevealed;
  final ValueChanged<TarotPhase>? onPhaseChanged;
  final double height;

  @override
  State<TarotDeck> createState() => _TarotDeckState();
}

class _TarotDeckState extends State<TarotDeck> with TickerProviderStateMixin {
  static const _n = 7;
  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: Motion.tarotShuffle,
  );
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: Motion.tarotSettle,
  );
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: Motion.tarotFlip,
  );
  TarotPhase _phase = TarotPhase.idle;
  List<TarotDrawn> _pending = const [];
  final _picked = <int, TarotDrawn>{};
  final _order = <int>[];

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

  void _prepare(List<TarotDrawn> draws) {
    _pending = List.of(draws);
  }

  void _reset() {
    _orbit.stop();
    _settle.stop();
    _flip.stop();
    _orbit.value = 0;
    _settle.value = 0;
    _flip.value = 0;
    _picked.clear();
    _order.clear();
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
    if (_phase != TarotPhase.arc && _phase != TarotPhase.revealed) return;
    if (_phase == TarotPhase.revealed) return;
    if (_picked.containsKey(i)) return;
    if (_picked.length >= _pending.length || _pending.isEmpty) return;
    final drawn = _pending[_picked.length];
    setState(() {
      _picked[i] = drawn;
      _order.add(i);
    });
    _setPhase(TarotPhase.flipping);
    void done() {
      if (!mounted) return;
      if (_picked.length >= _pending.length) {
        _setPhase(TarotPhase.revealed);
        widget.onRevealed?.call([for (final k in _order) _picked[k]!]);
      } else {
        _setPhase(TarotPhase.arc);
      }
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
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              for (var i = 0; i < _n; i++)
                if (!_order.contains(i)) _buildCard(i, rm),
              for (final i in _order) _buildCard(i, rm),
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
    final drawn = _picked[i];
    final isLatest =
        _order.isNotEmpty && _order.last == i && _phase == TarotPhase.flipping;
    final alreadyFront = drawn != null && !isLatest;
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
        if (alreadyFront) {
          angle = pi;
        }
      case TarotPhase.flipping:
      case TarotPhase.revealed:
        final (p, r) = _arc(i);
        if (isLatest) {
          final m = rm
              ? 1.0
              : const Interval(
                  0,
                  0.4,
                  curve: Curves.ease,
                ).transform(_flip.value);
          pos = Offset.lerp(
            p,
            Offset(0, -10.0 * (_pending.length == 1 ? 1 : 0)),
            m,
          )!;
          rot = r * (1 - m);
          scale = 1 + 0.12 * m;
          angle = rm
              ? pi
              : const Interval(
                      0.4,
                      1,
                      curve: Motion.flip,
                    ).transform(_flip.value) *
                    pi;
        } else if (drawn != null) {
          pos = p;
          rot = r;
          angle = pi;
        } else {
          pos = p;
          rot = r;
          if (_phase == TarotPhase.revealed) opacity = 0.12;
        }
    }

    final showFront = (angle > pi / 2 || alreadyFront) && drawn != null;
    Widget face;
    if (rm && (isLatest || alreadyFront)) {
      face = AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: showFront
            ? _Front(key: ValueKey('f$i'), draw: drawn)
            : const _Back(key: ValueKey('b')),
      );
    } else {
      final m = Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..rotateY(showFront ? (isLatest ? angle - pi : 0) : angle);
      face = Transform(
        alignment: Alignment.center,
        transform: m,
        child: showFront ? _Front(draw: drawn) : const _Back(),
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
              button: _phase == TarotPhase.arc && !_picked.containsKey(i),
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
      border: Border.all(color: AppColors.gold.withValues(alpha: 0.7)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x80000000),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Image.asset(TarotArt.backAsset, fit: BoxFit.cover),
  );
}

class _Front extends StatelessWidget {
  const _Front({super.key, required this.draw});
  final TarotDrawn draw;

  @override
  Widget build(BuildContext context) {
    final art = Image.asset(
      TarotArt.assetFor(draw.card.id),
      fit: BoxFit.cover,
      width: 76,
      height: 120,
      errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF0F1636)),
    );
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1636),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.gold2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE4DCC8).withValues(alpha: 0.12),
            blurRadius: 10,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          draw.reversed ? Transform.rotate(angle: pi, child: art) : art,
          const Align(
            alignment: Alignment.bottomCenter,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x000B1026), Color(0xCC0B1026)],
                  ),
                ),
                child: SizedBox(width: double.infinity, height: 36),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(3, 0, 3, 4),
              child: Text(
                draw.card.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: InkText.display(
                  size: 8,
                  height: 1.05,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
