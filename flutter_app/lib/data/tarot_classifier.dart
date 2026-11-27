import 'tarot_catalog.dart';

/// On-device classification of a typed question. Nothing is sent off the phone.
class TarotQuestion {
  const TarotQuestion({
    required this.raw,
    required this.topic,
    required this.yesNo,
    required this.timing,
    required this.topicScore,
    required this.yesNoScore,
    required this.timingScore,
  });

  final String raw;
  final TarotTopic topic;
  final bool yesNo, timing;
  final int topicScore, yesNoScore, timingScore;

  bool get hasText => raw.trim().isNotEmpty;
}

class TarotClassifier {
  TarotClassifier(this.spec);
  final TarotClassifierSpec spec;

  /// Phrase hits score 3 each; keyword hits score 2. Topic needs at least 2
  /// to beat "general". Flags need at least 3.
  TarotQuestion classify(String question) {
    final raw = question.trim();
    final lower = raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (lower.isEmpty) {
      return const TarotQuestion(
        raw: '',
        topic: TarotTopic.general,
        yesNo: false,
        timing: false,
        topicScore: 0,
        yesNoScore: 0,
        timingScore: 0,
      );
    }

    final topicScores = <TarotTopic, int>{
      for (final t in TarotTopic.values)
        if (t != TarotTopic.general) t: _score(lower, spec.topics[t]),
    };
    var best = TarotTopic.general;
    var bestScore = 0;
    // Stable tie-break: love, career, money, health, family.
    for (final t in const [
      TarotTopic.love,
      TarotTopic.career,
      TarotTopic.money,
      TarotTopic.health,
      TarotTopic.family,
    ]) {
      final s = topicScores[t] ?? 0;
      if (s > bestScore) {
        best = t;
        bestScore = s;
      }
    }
    if (bestScore < 2) {
      best = TarotTopic.general;
    }

    final yesNoScore = _score(lower, spec.yesNo);
    final timingScore = _score(lower, spec.timing);
    return TarotQuestion(
      raw: raw,
      topic: best,
      yesNo: yesNoScore >= 3,
      timing: timingScore >= 3,
      topicScore: bestScore,
      yesNoScore: yesNoScore,
      timingScore: timingScore,
    );
  }

  int _score(String lower, TarotPhraseBank? bank) {
    if (bank == null) return 0;
    var n = 0;
    final padded = ' $lower ';
    for (final p in bank.phrases) {
      if (p.isEmpty) continue;
      if (padded.contains(' $p ')) n += 3;
    }
    final tokens = lower
        .split(RegExp(r"[^a-z0-9]+"))
        .where((t) => t.isNotEmpty && !spec.ignore.contains(t))
        .toSet();
    for (final k in bank.keywords) {
      if (k.isEmpty) continue;
      if (k.contains(' ')) {
        if (padded.contains(' $k ')) n += 2;
      } else if (tokens.contains(k)) {
        n += 2;
      }
    }
    return n;
  }
}
