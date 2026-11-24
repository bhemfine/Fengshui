import 'package:flutter/material.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

class TarotScreen extends StatefulWidget {
  const TarotScreen({super.key});
  @override
  State<TarotScreen> createState() => _TarotScreenState();
}

class _TarotScreenState extends State<TarotScreen> {
  final _deck = TarotDeckController();
  final _q = TextEditingController();
  TarotPhase _phase = TarotPhase.idle;
  TarotDraw? _draw;

  @override
  void dispose() {
    _deck.dispose();
    _q.dispose();
    super.dispose();
  }

  String get _prompt => switch (_phase) {
        TarotPhase.shuffling => 'Shuffling…',
        TarotPhase.arc => 'Pick one card',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final drawn = _phase == TarotPhase.revealed && _draw != null;
    final busy = _phase == TarotPhase.shuffling || _phase == TarotPhase.flipping;
    return InkstoneScaffold(
      title: 'Tarot',
      showBack: true,
      example: true,
      fallbackRoute: Routes.readings,
      stickyCta: MidnightButton(
        label: drawn ? 'Shuffle again' : 'Shuffle',
        onPressed: busy
            ? null
            : () {
                setState(() => _draw = null);
                _deck.shuffle();
              },
      ),
      children: [
        Text('A calm, single-card draw.', style: InkText.body(color: AppColors.ivory2)),
        if (!drawn) ...[
          const SizedBox(height: 8),
          Text('Your question (optional)', style: InkText.body(size: 15, color: AppColors.ivory2)),
          const SizedBox(height: 5),
          TextField(
            controller: _q,
            style: InkText.body(size: 15),
            decoration: const InputDecoration(hintText: 'What should I focus on this week?'),
          ),
        ],
        SizedBox(height: drawn ? 0 : 6),
        TarotDeck(
          controller: _deck,
          height: drawn ? 200 : 280,
          onPhaseChanged: (p) => setState(() => _phase = p),
          onDrawn: (d) => setState(() => _draw = d),
        ),
        Semantics(
          liveRegion: true,
          child: SizedBox(
            height: 30,
            child: Text(_prompt, textAlign: TextAlign.center, style: InkText.display(size: 24)),
          ),
        ),
        if (drawn)
          InkstoneCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(_draw!.card.name, style: InkText.display(size: 26)),
                ExampleBadge(label: _draw!.reversed ? 'Reversed' : 'Upright'),
              ]),
              const SizedBox(height: 4),
              Text(
                _draw!.reversed ? (_draw!.card.reversedMeaning ?? _draw!.card.meaning) : _draw!.card.meaning,
                style: InkText.body(size: 17, height: 1.5),
              ),
              Text('Random draw (example)', style: InkText.small),
            ]),
          ),
      ],
    );
  }
}
