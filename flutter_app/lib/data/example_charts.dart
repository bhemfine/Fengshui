import 'package:inkstone_engine/inkstone_engine.dart' as eng;

import 'household.dart';
import 'sample_data.dart';

/// BaZi for a household person, worked out by the engine (not hard-coded).
class PersonChart {
  PersonChart(this.person)
    : chart = eng.computeBazi(birthLocal: person.birth, utcOffsetHours: 8, hourKnown: person.timeKnown);

  final KuaPerson person;
  final eng.BaziChart chart;

  List<Pillar> get pillars => [
    _cell('Year', chart.year),
    _cell('Month', chart.month),
    _cell('You', chart.day, self: true),
    if (chart.hour != null)
      _cell('Hour', chart.hour!)
    else
      const Pillar(label: 'Hour', stem: '?', branch: '?', element: 'Unknown'),
  ];

  static Pillar _cell(String label, eng.Pillar p, {bool self = false}) => Pillar(
    label: label,
    stem: p.stem.chinese,
    branch: p.branch.chinese,
    element: p.stem.element.english,
    isSelf: self,
  );

  /// Day Master, e.g. "Ren Water".
  String get dayMaster => '${chart.day.stem.pinyin} ${chart.day.stem.element.english}';

  String get dayMasterImage => switch (chart.day.stem.element) {
    eng.FiveElement.wood => 'Like a tree: growing, patient, steady.',
    eng.FiveElement.fire => 'Like the sun: warm, visible, generous.',
    eng.FiveElement.earth => 'Like a mountain: dependable, calm, solid.',
    eng.FiveElement.metal => 'Like a blade or a jewel: clear, precise, principled.',
    eng.FiveElement.water => 'Like a great river: flowing, resourceful, quick to adapt.',
  };

  List<(String, int)> get elementBalance => [
    for (final e in eng.FiveElement.values) (e.english, chart.elementCounts[e] ?? 0),
  ];

  List<LuckPillar> luckPillars({DateTime? now}) {
    final n = now ?? DateTime.now();
    final age =
        n.year -
        person.birth.year -
        ((n.month < person.birth.month || (n.month == person.birth.month && n.day < person.birth.day)) ? 1 : 0);
    final list = eng.luckPillarsFor(
      chart: chart,
      birthUtc: DateTime.utc(
        person.birth.year,
        person.birth.month,
        person.birth.day,
        person.birth.hour,
        person.birth.minute,
      ).subtract(const Duration(hours: 8)),
      gender: person.gender,
      count: 5,
    );
    return [
      for (final l in list)
        LuckPillar(age: l.startAge, chinese: l.pillar.chinese, current: age >= l.startAge && age < l.startAge + 10),
    ];
  }
}

/// How one person fits a facing, from the engine's 8 Mansions table.
class PersonHomeFit {
  const PersonHomeFit({required this.person, required this.info, required this.score});
  final KuaPerson person;
  final eng.DirectionInfo info;

  /// 0–100 rank within the person's 8 directions: best lucky 90, worst unlucky 15.
  final int score;
  bool get good => info.lucky;
}

PersonHomeFit homeFitFor(KuaPerson p, eng.Direction facing) {
  final k = p.kua;
  final lucky = k.lucky, unlucky = k.unlucky;
  final li = lucky.indexWhere((d) => d.direction == facing);
  final info = k.directions.firstWhere((d) => d.direction == facing);
  final score = li >= 0 ? 90 - li * 8 : 45 - unlucky.indexWhere((d) => d.direction == facing) * 10;
  return PersonHomeFit(person: p, info: info, score: score);
}

/// Day Master element relation between two people (production / control cycle).
(String verdict, String line, int score, bool good) dayMasterFit(PersonChart a, PersonChart b) {
  final ea = a.chart.day.stem.element, eb = b.chart.day.stem.element;
  final na = shortName(a.person), nb = shortName(b.person);
  if (ea == eb)
    return ('Steady fit', '${ea.english} meets ${eb.english}: alike, easy to understand each other.', 70, true);
  if (ea.produces == eb) return ('Good fit', '${ea.english} feeds ${eb.english}: $na supports, $nb grows.', 80, true);
  if (eb.produces == ea) return ('Good fit', '${eb.english} feeds ${ea.english}: $nb supports, $na grows.', 80, true);
  if (ea.produces.produces == eb) {
    return ('Take care', '${ea.english} controls ${eb.english}: $na can feel strict to $nb.', 55, false);
  }
  return ('Take care', '${eb.english} controls ${ea.english}: $nb can feel strict to $na.', 55, false);
}
