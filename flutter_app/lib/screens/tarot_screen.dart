import 'package:flutter/material.dart';
import 'package:inkstone/data/tarot_catalog.dart';
import 'package:inkstone/data/tarot_classifier.dart';
import 'package:inkstone/data/tarot_reading.dart';
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
  final _dealer = TarotDealer();
  TarotPhase _phase = TarotPhase.idle;
  TarotCatalog? _catalog;
  Object? _loadError;
  String _spreadId = 'single';
  TarotSpread? _dealSpread;
  List<TarotDrawn> _draws = const [];
  TarotReading? _reading;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await TarotCatalog.load();
      if (!mounted) return;
      setState(() => _catalog = c);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e);
    }
  }

  @override
  void dispose() {
    _deck.dispose();
    _q.dispose();
    super.dispose();
  }

  TarotSpread get _spread => _catalog!.spreads.byId(_spreadId);

  String get _prompt {
    final need = _spread.size;
    final got = _draws.length;
    return switch (_phase) {
      TarotPhase.shuffling => 'Shuffling…',
      TarotPhase.arc =>
        need == 1
            ? 'Pick one card'
            : (got == 0 ? 'Pick $need cards' : 'Pick ${need - got} more'),
      TarotPhase.flipping => 'Turning…',
      _ => '',
    };
  }

  void _start() {
    final cat = _catalog;
    if (cat == null) return;
    final spread = _spread;
    final draws = _dealer.draw(cat.cards, spread.size);
    _deck.prepare(draws);
    setState(() {
      _dealSpread = spread;
      _draws = const [];
      _reading = null;
    });
    _deck.shuffle();
  }

  void _onRevealed(List<TarotDrawn> draws) {
    final cat = _catalog;
    if (cat == null) return;
    final q = TarotClassifier(cat.classifier).classify(_q.text);
    final spread = _dealSpread ?? _spread;
    final reading = TarotComposer(
      cat.spreads,
      disclaimer: cat.disclaimer,
    ).compose(draws: draws, spread: spread, question: q);
    setState(() {
      _draws = draws;
      _reading = reading;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cat = _catalog;
    final drawn = _phase == TarotPhase.revealed && _reading != null;
    final busy =
        _phase == TarotPhase.shuffling || _phase == TarotPhase.flipping;
    final spreadLocked = busy || drawn || _phase == TarotPhase.arc;
    return InkstoneScaffold(
      title: 'Tarot',
      showBack: true,
      fallbackRoute: Routes.readings,
      stickyCta: MidnightButton(
        label: drawn ? 'Shuffle again' : 'Shuffle',
        onPressed: cat == null || busy ? null : _start,
      ),
      children: [
        Text(
          'Ask a question, pick a spread, then shuffle. Cards are drawn on this phone. For reflection and entertainment only.',
          style: InkText.body(color: AppColors.ivory2),
        ),
        if (_loadError != null) ...[
          const SizedBox(height: 12),
          Text(
            'The deck could not be loaded.',
            style: InkText.body(color: AppColors.care),
          ),
        ] else if (cat == null) ...[
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator()),
        ] else ...[
          const SizedBox(height: 12),
          Text(
            'Spread',
            style: InkText.body(size: 15, color: AppColors.ivory2),
          ),
          const SizedBox(height: 6),
          ChoicePills<String>(
            options: [for (final s in cat.spreads.spreads) (s.id, s.name)],
            selected: _spreadId,
            onSelected: spreadLocked
                ? (_) {}
                : (id) => setState(() => _spreadId = id),
          ),
          const SizedBox(height: 4),
          Text(_spread.blurb, style: InkText.small),
          if (!drawn) ...[
            const SizedBox(height: 10),
            Text(
              'Your question (optional)',
              style: InkText.body(size: 15, color: AppColors.ivory2),
            ),
            const SizedBox(height: 5),
            TextField(
              controller: _q,
              style: InkText.body(size: 15),
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'What should I focus on this week?',
              ),
            ),
          ],
          SizedBox(height: drawn ? 0 : 6),
          TarotDeck(
            controller: _deck,
            height: drawn ? 200 : 280,
            onPhaseChanged: (p) => setState(() => _phase = p),
            onRevealed: _onRevealed,
          ),
          Semantics(
            liveRegion: true,
            child: SizedBox(
              height: 30,
              child: Text(
                _prompt,
                textAlign: TextAlign.center,
                style: InkText.display(size: 24),
              ),
            ),
          ),
          if (_reading != null) _Result(reading: _reading!),
        ],
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.reading});
  final TarotReading reading;

  @override
  Widget build(BuildContext context) {
    final q = reading.question;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkstoneCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(reading.opener, style: InkText.body(size: 17, height: 1.5)),
              if (q.hasText) ...[
                const SizedBox(height: 8),
                Text('Your question: ${q.raw}', style: InkText.small),
              ],
            ],
          ),
        ),
        for (final p in reading.passages)
          InkstoneCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(p.position.label, style: InkText.small),
                    Text(p.drawn.card.name, style: InkText.display(size: 24)),
                    InkTag(label: p.drawn.reversed ? 'Reversed' : 'Upright'),
                  ],
                ),
                const SizedBox(height: 6),
                Text(p.position.intro, style: InkText.small),
                const SizedBox(height: 6),
                Text(p.body, style: InkText.body(size: 17, height: 1.5)),
                const SizedBox(height: 6),
                Text(
                  p.advice,
                  style: InkText.body(
                    size: 16,
                    height: 1.45,
                    color: AppColors.ivory2,
                  ),
                ),
              ],
            ),
          ),
        if (reading.yesNo != null)
          InkstoneCard(
            child: Text(
              reading.yesNo!,
              style: InkText.body(size: 17, height: 1.5),
            ),
          ),
        if (reading.timing != null)
          InkstoneCard(
            child: Text(
              reading.timing!,
              style: InkText.body(size: 17, height: 1.5),
            ),
          ),
        InkstoneCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Together', style: InkText.display(size: 22)),
              const SizedBox(height: 6),
              Text(reading.summary, style: InkText.body(size: 17, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(reading.disclaimer, style: InkText.small),
      ],
    );
  }
}
