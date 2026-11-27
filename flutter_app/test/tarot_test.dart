import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkstone/data/tarot_catalog.dart';
import 'package:inkstone/data/tarot_classifier.dart';
import 'package:inkstone/data/tarot_reading.dart';

Map<String, Object?> _j(String rel) =>
    jsonDecode(File(rel).readAsStringSync()) as Map<String, Object?>;

TarotCatalog _catalog() => TarotCatalog.parse(
  readings: _j('assets/content/tarot/readings.json'),
  classifier: _j('assets/content/tarot/classifier.json'),
  spreads: _j('assets/content/tarot/spreads.json'),
);

void main() {
  late TarotCatalog cat;
  late TarotClassifier clf;

  setUpAll(() {
    cat = _catalog();
    clf = TarotClassifier(cat.classifier);
  });

  test('bundled tarot JSON matches content/ byte for byte', () {
    for (final f in ['readings', 'classifier', 'spreads']) {
      expect(
        File('assets/content/tarot/$f.json').readAsStringSync(),
        File('../content/tarot/$f.json').readAsStringSync(),
        reason: f,
      );
    }
  });

  test('pack has 78 unique cards with upright and reversed category texts', () {
    expect(cat.cards, hasLength(78));
    expect({for (final c in cat.cards) c.id}, hasLength(78));
    expect(cat.cards.where((c) => c.arcana == 'major'), hasLength(22));
    for (final c in cat.cards) {
      for (final m in [c.upright, c.reversed]) {
        expect(m.love, isNotEmpty, reason: c.id);
        expect(m.career, isNotEmpty, reason: c.id);
        expect(m.health, isNotEmpty, reason: c.id);
        expect(m.family, isNotEmpty, reason: c.id);
        expect(m.thread, isNotEmpty, reason: c.id);
        expect(m.byTopic(TarotTopic.love), m.love);
      }
      expect(c.upright.love, isNot(c.reversed.love), reason: c.id);
    }
  });

  test('classifier: love and career questions, plus Singlish and pinyin', () {
    expect(clf.classify("Does he still love me?").topic, TarotTopic.love);
    expect(clf.classify("Does he still love me?").yesNo, isTrue);
    expect(
      clf.classify('Should I take the new job in my career?').topic,
      TarotTopic.career,
    );
    expect(clf.classify('yuan fen with this person').topic, TarotTopic.love);
    expect(
      clf.classify('how is my gong zuo this year').topic,
      TarotTopic.career,
    );
    expect(clf.classify('cai yun looking bad').topic, TarotTopic.money);
    expect(clf.classify('jian kang and my energy').topic, TarotTopic.health);
    expect(clf.classify('jia ting and my parents').topic, TarotTopic.family);
    expect(clf.classify('steady or not').yesNo, isTrue);
    expect(clf.classify('When will the offer come?').timing, isTrue);
    expect(clf.classify('').topic, TarotTopic.general);
    expect(clf.classify('hello there').topic, TarotTopic.general);
  });

  test('draw uses unique cards and is deterministic with a seeded Random', () {
    final a = TarotDealer(Random(42)).draw(cat.cards, 3);
    final b = TarotDealer(Random(42)).draw(cat.cards, 3);
    expect({for (final d in a) d.card.id}, hasLength(3));
    expect(
      [for (final d in a) (d.card.id, d.reversed)],
      [for (final d in b) (d.card.id, d.reversed)],
    );
    final c = TarotDealer(Random(99)).draw(cat.cards, 3);
    expect([
      for (final d in a) d.card.id,
    ], isNot([for (final d in c) d.card.id]));
  });

  test('reversals are about half over many seeded draws', () {
    final rng = Random(7);
    final dealer = TarotDealer(rng);
    var reversed = 0;
    const n = 400;
    for (var i = 0; i < n; i++) {
      if (dealer.draw(cat.cards, 1).single.reversed) reversed++;
    }
    expect(reversed, greaterThan(140));
    expect(reversed, lessThan(260));
  });

  test('compose: love question, three-card past-present-future', () {
    final spread = cat.spreads.byId('past_present_future');
    final q = clf.classify('Do you see a future with my partner?');
    expect(q.topic, TarotTopic.love);
    final draws = [
      TarotDrawn(card: cat.cardById('the-fool'), reversed: false),
      TarotDrawn(card: cat.cardById('the-lovers'), reversed: false),
      TarotDrawn(card: cat.cardById('the-star'), reversed: true),
    ];
    final r = TarotComposer(
      cat.spreads,
      disclaimer: cat.disclaimer,
    ).compose(draws: draws, spread: spread, question: q);
    expect(r.passages, hasLength(3));
    expect(r.passages[0].position.id, 'past');
    expect(r.passages[0].body, cat.cardById('the-fool').upright.love);
    expect(r.passages[1].body, cat.cardById('the-lovers').upright.love);
    expect(r.passages[2].body, cat.cardById('the-star').reversed.love);
    expect(r.summary.toLowerCase(), contains('past points to'));
    expect(r.summary.toLowerCase(), contains('present points to'));
    expect(r.summary.toLowerCase(), contains('future points to'));
    expect(r.disclaimer.toLowerCase(), contains('entertainment'));
    expect(r.opener.toLowerCase(), contains('heart'));
  });

  test('compose: career question, single card, includes yes/no when asked', () {
    final spread = cat.spreads.byId('single');
    final q = clf.classify('Should I take this new job?');
    expect(q.topic, TarotTopic.career);
    expect(q.yesNo, isTrue);
    final draws = [
      TarotDrawn(card: cat.cardById('ace-of-wands'), reversed: false),
    ];
    final r = TarotComposer(
      cat.spreads,
      disclaimer: cat.disclaimer,
    ).compose(draws: draws, spread: spread, question: q);
    expect(r.passages.single.body, cat.cardById('ace-of-wands').upright.career);
    expect(r.yesNo, isNotNull);
    expect(r.yesNoLean, isNotNull);
    expect(r.summary.toLowerCase(), contains('in short'));
  });

  test('every card id has a bundled art asset', () {
    for (final c in cat.cards) {
      expect(
        File('assets/tarot/${c.id}.webp').existsSync(),
        isTrue,
        reason: 'missing art for ${c.id}',
      );
    }
    expect(File('assets/tarot/card-back.webp').existsSync(), isTrue);
  });
}
