import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone/data/household.dart';
import 'package:inkstone/data/tarot_art.dart';
import 'package:inkstone/data/tarot_catalog.dart';
import 'package:inkstone/data/tarot_classifier.dart';
import 'package:inkstone/data/tarot_reading.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

class TarotScreen extends StatefulWidget {
  const TarotScreen({super.key, this.catalog, this.initialReading});

  /// Tests can pass a catalog so the screen does not have to load assets.
  final TarotCatalog? catalog;

  /// Tests can start on a finished reading to check the revealed layout.
  final TarotReading? initialReading;

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
    if (widget.catalog != null) {
      _catalog = widget.catalog;
    } else {
      _load();
    }
    final seed = widget.initialReading;
    if (seed != null) {
      _phase = TarotPhase.revealed;
      _reading = seed;
      _draws = [for (final p in seed.passages) p.drawn];
      _spreadId = seed.spread.id;
      _dealSpread = seed.spread;
      _q.text = seed.question.raw;
    }
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: cat == null || _loadError != null
            ? _LoadingShell(error: _loadError)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _TarotBar(),
                  if (!drawn && !spreadLocked)
                    _Setup(
                      catalog: cat,
                      spreadId: _spreadId,
                      blurb: _spread.blurb,
                      question: _q,
                      onSpread: (id) => setState(() => _spreadId = id),
                    )
                  else if (drawn)
                    _CollapsedChip(
                      spreadName: _reading!.spread.name,
                      question: _q.text.trim(),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: Text(
                        _spread.name,
                        style: InkText.small,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Expanded(
                    flex: drawn ? 5 : 6,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: drawn
                          ? TarotRevealedCards(
                              passages: _reading!.passages,
                              onTap: (p) =>
                                  showTarotCardViewer(context, passage: p),
                            )
                          : LayoutBuilder(
                              builder: (context, box) {
                                final h = box.maxHeight.isFinite
                                    ? box.maxHeight.clamp(180.0, 520.0)
                                    : 280.0;
                                return TarotDeck(
                                  key: const Key('tarot-deck'),
                                  controller: _deck,
                                  height: h,
                                  onPhaseChanged: (p) =>
                                      setState(() => _phase = p),
                                  onRevealed: _onRevealed,
                                );
                              },
                            ),
                    ),
                  ),
                  if (_prompt.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _prompt,
                          textAlign: TextAlign.center,
                          style: InkText.display(size: 22),
                        ),
                      ),
                    ),
                  if (!drawn)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: MidnightButton(
                        label: 'Shuffle',
                        onPressed: busy ? null : _start,
                      ),
                    ),
                  if (drawn)
                    Expanded(
                      flex: 4,
                      child: _ReadingSheet(
                        reading: _reading!,
                        onShuffle: _start,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _TarotBar extends StatelessWidget {
  const _TarotBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            InkIconButton(
              icon: Icons.chevron_left,
              semanticLabel: 'Back',
              onTap: () => context.canPop()
                  ? context.pop()
                  : context.go(Routes.readings),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tarot',
                style: InkText.topBar,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingShell extends StatelessWidget {
  const _LoadingShell({this.error});
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _TarotBar(),
        Expanded(
          child: Center(
            child: error != null
                ? Text(
                    'The deck could not be loaded.',
                    style: InkText.body(color: AppColors.care),
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      ],
    );
  }
}

class _Setup extends StatelessWidget {
  const _Setup({
    required this.catalog,
    required this.spreadId,
    required this.blurb,
    required this.question,
    required this.onSpread,
  });

  final TarotCatalog catalog;
  final String spreadId;
  final String blurb;
  final TextEditingController question;
  final ValueChanged<String> onSpread;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        key: const Key('tarot-setup'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A reading for ${shortName(mainUser)}. Cards stay on this phone.',
            style: InkText.small,
          ),
          const SizedBox(height: 8),
          ChoicePills<String>(
            options: [for (final s in catalog.spreads.spreads) (s.id, s.name)],
            selected: spreadId,
            onSelected: onSpread,
          ),
          const SizedBox(height: 4),
          Text(blurb, style: InkText.small),
          const SizedBox(height: 8),
          TextField(
            controller: question,
            style: InkText.body(size: 15),
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'What should I focus on this week?',
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsedChip extends StatelessWidget {
  const _CollapsedChip({required this.spreadName, required this.question});
  final String spreadName;
  final String question;

  @override
  Widget build(BuildContext context) {
    final label = question.isEmpty
        ? '$spreadName · tap a card to enlarge'
        : '$spreadName · $question';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Container(
        key: const Key('tarot-collapsed-setup'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xCC121836),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.goldDim),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: InkText.small,
        ),
      ),
    );
  }
}

/// Revealed cards in a reserved row, sized to the leftover space (2:3).
class TarotRevealedCards extends StatelessWidget {
  const TarotRevealedCards({
    super.key,
    required this.passages,
    required this.onTap,
  });

  final List<TarotPassage> passages;
  final ValueChanged<TarotPassage> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final n = passages.length;
        final gap = 10.0;
        final maxH = box.maxHeight;
        final maxW = (box.maxWidth - gap * (n - 1)) / n;
        // 2:3 card. Fit both axes, leave a little for the label.
        var h = maxH - 36;
        var w = h * 2 / 3;
        if (w > maxW) {
          w = maxW;
          h = w * 3 / 2;
        }
        if (h < 80) {
          h = maxH.clamp(60, 80);
          w = h * 2 / 3;
        }
        return Center(
          child: Row(
            key: const Key('tarot-revealed-row'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < n; i++) ...[
                if (i > 0) SizedBox(width: gap),
                _RevealedCard(
                  passage: passages[i],
                  width: w,
                  height: h,
                  onTap: () => onTap(passages[i]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RevealedCard extends StatelessWidget {
  const _RevealedCard({
    required this.passage,
    required this.width,
    required this.height,
    required this.onTap,
  });

  final TarotPassage passage;
  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = passage.drawn;
    return Semantics(
      button: true,
      label: '${d.card.name}, ${d.reversed ? 'reversed' : 'upright'}',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          key: Key('tarot-reveal-card-${d.card.id}'),
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.8),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x80000000),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Transform.rotate(
                  angle: d.reversed ? 3.14159 : 0,
                  child: Image.asset(
                    TarotArt.assetFor(d.card.id),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                passage.position.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: InkText.small,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadingSheet extends StatelessWidget {
  const _ReadingSheet({required this.reading, required this.onShuffle});

  final TarotReading reading;
  final VoidCallback onShuffle;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('tarot-reading-sheet'),
      color: const Color(0xF00B1026),
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.goldDim),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gold2,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: MidnightButton(label: 'Shuffle again', onPressed: onShuffle),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              children: [TarotReadingBody(reading: reading)],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reading text used in the sheet (and in tests).
class TarotReadingBody extends StatelessWidget {
  const TarotReadingBody({super.key, required this.reading});
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

/// Full-screen card viewer: art, name, upright/reversed, close.
Future<void> showTarotCardViewer(
  BuildContext context, {
  required TarotPassage passage,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close card',
    barrierColor: const Color(0xF00B1026),
    pageBuilder: (ctx, _, __) => TarotCardViewer(passage: passage),
  );
}

class TarotCardViewer extends StatelessWidget {
  const TarotCardViewer({super.key, required this.passage});
  final TarotPassage passage;

  @override
  Widget build(BuildContext context) {
    final d = passage.drawn;
    return SafeArea(
      child: Material(
        color: AppColors.ink,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(d.card.name, style: InkText.display(size: 28)),
                  ),
                  InkIconButton(
                    icon: Icons.close,
                    semanticLabel: 'Close',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Text(
                '${passage.position.label} · ${d.reversed ? 'Reversed' : 'Upright'}',
                style: InkText.small,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.85),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Transform.rotate(
                        angle: d.reversed ? 3.14159 : 0,
                        child: Image.asset(
                          TarotArt.assetFor(d.card.id),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              MidnightButton(
                label: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
