import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// One orientation's pre-written texts (bundled; never fetched).
class TarotMeanings {
  const TarotMeanings({
    required this.summary,
    required this.love,
    required this.career,
    required this.money,
    required this.health,
    required this.family,
    required this.general,
    required this.yesNo,
    required this.timing,
    required this.advice,
    required this.thread,
  });

  final String summary, love, career, money, health, family, general, yesNo, timing, advice, thread;

  factory TarotMeanings.fromJson(Map<String, Object?> j) => TarotMeanings(
        summary: '${j['summary']}',
        love: '${j['love']}',
        career: '${j['career']}',
        money: '${j['money']}',
        health: '${j['health']}',
        family: '${j['family']}',
        general: '${j['general']}',
        yesNo: '${j['yes_no']}',
        timing: '${j['timing']}',
        advice: '${j['advice']}',
        thread: '${j['thread']}',
      );

  String byTopic(TarotTopic topic) => switch (topic) {
        TarotTopic.love => love,
        TarotTopic.career => career,
        TarotTopic.money => money,
        TarotTopic.health => health,
        TarotTopic.family => family,
        TarotTopic.general => general,
      };
}

enum TarotTopic { love, career, money, health, family, general }

enum TarotLean { yes, no, maybe }

class TarotCard {
  const TarotCard({
    required this.id,
    required this.name,
    required this.arcana,
    required this.suit,
    required this.yesNoLean,
    required this.upright,
    required this.reversed,
  });

  final String id, name, arcana, suit;
  final TarotLean yesNoLean;
  final TarotMeanings upright, reversed;

  factory TarotCard.fromJson(Map<String, Object?> j) => TarotCard(
        id: '${j['id']}',
        name: '${j['name']}',
        arcana: '${j['arcana']}',
        suit: '${j['suit']}',
        yesNoLean: parseLean('${j['yes_no_lean']}'),
        upright: TarotMeanings.fromJson(j['upright']! as Map<String, Object?>),
        reversed: TarotMeanings.fromJson(j['reversed']! as Map<String, Object?>),
      );

  TarotMeanings meanings(bool reversed) => reversed ? this.reversed : upright;
}

TarotLean parseLean(String raw) => switch (raw.toLowerCase().trim()) {
      'yes' => TarotLean.yes,
      'no' => TarotLean.no,
      _ => TarotLean.maybe,
    };

class TarotPosition {
  const TarotPosition({required this.id, required this.label, required this.intro});
  final String id, label, intro;

  factory TarotPosition.fromJson(Map<String, Object?> j) => TarotPosition(
        id: '${j['id']}',
        label: '${j['label']}',
        intro: '${j['intro']}',
      );
}

class TarotSpread {
  const TarotSpread({required this.id, required this.name, required this.blurb, required this.positions});
  final String id, name, blurb;
  final List<TarotPosition> positions;
  int get size => positions.length;

  factory TarotSpread.fromJson(Map<String, Object?> j) => TarotSpread(
        id: '${j['id']}',
        name: '${j['name']}',
        blurb: '${j['blurb']}',
        positions: [
          for (final p in (j['positions'] as List? ?? const [])) TarotPosition.fromJson(p as Map<String, Object?>)
        ],
      );
}

class TarotPhraseBank {
  const TarotPhraseBank({required this.phrases, required this.keywords});
  final List<String> phrases, keywords;

  factory TarotPhraseBank.fromJson(Map<String, Object?> j) => TarotPhraseBank(
        phrases: [for (final x in (j['phrases'] as List? ?? const [])) '$x'.toLowerCase().trim()],
        keywords: [for (final x in (j['keywords'] as List? ?? const [])) '$x'.toLowerCase().trim()],
      );
}

class TarotClassifierSpec {
  const TarotClassifierSpec({
    required this.topics,
    required this.yesNo,
    required this.timing,
    required this.ignore,
  });

  final Map<TarotTopic, TarotPhraseBank> topics;
  final TarotPhraseBank yesNo, timing;
  final Set<String> ignore;

  factory TarotClassifierSpec.fromJson(Map<String, Object?> j) {
    final topics = <TarotTopic, TarotPhraseBank>{};
    final raw = j['topics'] as Map<String, Object?>? ?? const {};
    for (final t in TarotTopic.values) {
      final m = raw[t.name] as Map<String, Object?>?;
      if (m != null) topics[t] = TarotPhraseBank.fromJson(m);
    }
    final flags = j['flags'] as Map<String, Object?>? ?? const {};
    return TarotClassifierSpec(
      topics: topics,
      yesNo: TarotPhraseBank.fromJson(flags['yes_no'] as Map<String, Object?>? ?? const {}),
      timing: TarotPhraseBank.fromJson(flags['timing'] as Map<String, Object?>? ?? const {}),
      ignore: {for (final x in (j['ignore'] as List? ?? const [])) '$x'.toLowerCase()},
    );
  }
}

class TarotSpreadPack {
  const TarotSpreadPack({
    required this.spreads,
    required this.openers,
    required this.closings,
    required this.yesNoBridge,
    required this.timingBridge,
  });

  final List<TarotSpread> spreads;
  final Map<String, String> openers, closings;
  final String yesNoBridge, timingBridge;

  factory TarotSpreadPack.fromJson(Map<String, Object?> j) => TarotSpreadPack(
        spreads: [for (final s in (j['spreads'] as List? ?? const [])) TarotSpread.fromJson(s as Map<String, Object?>)],
        openers: {for (final e in (j['openers'] as Map? ?? const {}).entries) '${e.key}': '${e.value}'},
        closings: {for (final e in (j['closings'] as Map? ?? const {}).entries) '${e.key}': '${e.value}'},
        yesNoBridge: '${j['yes_no_bridge'] ?? 'On the yes-or-no side of the question:'}',
        timingBridge: '${j['timing_bridge'] ?? 'As for timing and pace:'}',
      );

  TarotSpread byId(String id) => spreads.firstWhere((s) => s.id == id);
}

/// Offline 78-card pack, classifier and spread copy. Loaded from bundled assets.
class TarotCatalog {
  const TarotCatalog({
    required this.cards,
    required this.classifier,
    required this.spreads,
    required this.disclaimer,
  });

  final List<TarotCard> cards;
  final TarotClassifierSpec classifier;
  final TarotSpreadPack spreads;
  final String disclaimer;

  TarotCard cardById(String id) => cards.firstWhere((c) => c.id == id);

  static Future<TarotCatalog>? _cache;

  static Future<TarotCatalog> load() => _cache ??= _load();

  static void setForTest(TarotCatalog c) => _cache = Future.value(c);

  static void resetCache() => _cache = null;

  static Future<TarotCatalog> _load() async {
    Future<Map<String, Object?>> j(String f) async =>
        jsonDecode(await rootBundle.loadString('assets/content/tarot/$f.json')) as Map<String, Object?>;
    final parts = await Future.wait([j('readings'), j('classifier'), j('spreads')]);
    return parse(readings: parts[0], classifier: parts[1], spreads: parts[2]);
  }

  static TarotCatalog parse({
    required Map<String, Object?> readings,
    required Map<String, Object?> classifier,
    required Map<String, Object?> spreads,
  }) {
    final cards = [for (final c in (readings['cards'] as List? ?? const [])) TarotCard.fromJson(c as Map<String, Object?>)];
    if (cards.length != 78) {
      throw StateError('Tarot pack must have 78 cards, got ${cards.length}');
    }
    final ids = {for (final c in cards) c.id};
    if (ids.length != 78) {
      throw StateError('Tarot pack has duplicate ids');
    }
    return TarotCatalog(
      cards: cards,
      classifier: TarotClassifierSpec.fromJson(classifier),
      spreads: TarotSpreadPack.fromJson(spreads),
      disclaimer: '${readings['disclaimer']}',
    );
  }
}
