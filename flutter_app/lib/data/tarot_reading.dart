import 'dart:math';

import 'tarot_catalog.dart';
import 'tarot_classifier.dart';

class TarotDrawn {
  const TarotDrawn({required this.card, required this.reversed});
  final TarotCard card;
  final bool reversed;

  TarotMeanings get meanings => card.meanings(reversed);
}

/// Secure by default; pass a seeded [Random] in tests.
class TarotDealer {
  TarotDealer([Random? rng]) : _rng = rng ?? Random.secure();
  final Random _rng;

  /// [count] unique cards, each independently upright or reversed at 50/50.
  List<TarotDrawn> draw(List<TarotCard> deck, int count) {
    if (count < 1 || count > deck.length) {
      throw ArgumentError.value(count, 'count');
    }
    final order = List<int>.generate(deck.length, (i) => i)..shuffle(_rng);
    return [
      for (var i = 0; i < count; i++) TarotDrawn(card: deck[order[i]], reversed: _rng.nextBool()),
    ];
  }
}

class TarotPassage {
  const TarotPassage({
    required this.position,
    required this.drawn,
    required this.body,
    required this.advice,
  });
  final TarotPosition position;
  final TarotDrawn drawn;
  final String body, advice;
}

class TarotReading {
  const TarotReading({
    required this.spread,
    required this.question,
    required this.opener,
    required this.passages,
    required this.summary,
    required this.disclaimer,
    this.yesNo,
    this.timing,
    this.yesNoLean,
  });

  final TarotSpread spread;
  final TarotQuestion question;
  final String opener, summary, disclaimer;
  final List<TarotPassage> passages;
  final String? yesNo, timing;
  final TarotLean? yesNoLean;
}

class TarotComposer {
  const TarotComposer(this.pack, {required this.disclaimer});
  final TarotSpreadPack pack;
  final String disclaimer;

  TarotReading compose({
    required List<TarotDrawn> draws,
    required TarotSpread spread,
    required TarotQuestion question,
  }) {
    if (draws.length != spread.size) {
      throw ArgumentError('Expected ${spread.size} cards, got ${draws.length}');
    }
    final topic = question.topic;
    final passages = <TarotPassage>[
      for (var i = 0; i < draws.length; i++)
        TarotPassage(
          position: spread.positions[i],
          drawn: draws[i],
          body: draws[i].meanings.byTopic(topic),
          advice: draws[i].meanings.advice,
        ),
    ];

    final opener = pack.openers[topic.name] ?? pack.openers['general'] ?? 'Here is a reading for your question.';

    String? yesNoText;
    TarotLean? lean;
    if (question.yesNo) {
      lean = _combinedLean(draws);
      final focus = draws.last.meanings.yesNo;
      yesNoText = draws.length == 1
          ? '${pack.yesNoBridge} $focus'
          : '${pack.yesNoBridge} ${_leanSentence(lean)} $focus';
    }
    String? timingText;
    if (question.timing) {
      timingText = '${pack.timingBridge} ${draws.last.meanings.timing}';
    }

    return TarotReading(
      spread: spread,
      question: question,
      opener: opener,
      passages: passages,
      summary: _summary(draws, spread, topic),
      disclaimer: disclaimer,
      yesNo: yesNoText,
      timing: timingText,
      yesNoLean: lean,
    );
  }

  String _summary(List<TarotDrawn> draws, TarotSpread spread, TarotTopic topic) {
    if (draws.length == 1) {
      final closing = pack.closings['single'] ?? '';
      return 'In short, this card points to ${draws.first.meanings.thread}. $closing'.trim();
    }
    final parts = <String>[
      for (var i = 0; i < draws.length; i++)
        '${spread.positions[i].label.toLowerCase()} points to ${draws[i].meanings.thread}',
    ];
    final mixed = draws.any((d) => d.reversed) && draws.any((d) => !d.reversed);
    final allRev = draws.every((d) => d.reversed);
    final closingKey = allRev ? 'all_reversed' : (mixed ? 'mixed' : 'all_upright');
    final closing = pack.closings[closingKey] ?? '';
    final joined = parts.length == 2
        ? '${parts[0]}, and ${parts[1]}'
        : '${parts.sublist(0, parts.length - 1).join('; ')}; and ${parts.last}';
    return 'Taken together, $joined. $closing'.trim();
  }

  TarotLean _combinedLean(List<TarotDrawn> draws) {
    var score = 0;
    for (final d in draws) {
      score += switch (d.card.yesNoLean) {
        TarotLean.yes => d.reversed ? -1 : 1,
        TarotLean.no => d.reversed ? 1 : -1,
        TarotLean.maybe => 0,
      };
    }
    if (score > 0) return TarotLean.yes;
    if (score < 0) return TarotLean.no;
    return TarotLean.maybe;
  }

  String _leanSentence(TarotLean lean) => switch (lean) {
        TarotLean.yes => 'The spread leans yes.',
        TarotLean.no => 'The spread leans no.',
        TarotLean.maybe => 'The spread leans mixed — not a clear yes or no.',
      };
}
