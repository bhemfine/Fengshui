import 'package:inkstone_engine/inkstone_engine.dart';

import 'content_repo.dart';
import 'household.dart';

/// Everything the "Your year" screen shows for one person and one year. Offline.
class YourYear {
  YourYear._({
    required this.person,
    required this.year,
    required this.zodiac,
    required this.chart,
    required this.taiSui,
    required this.afflictions,
    required this.lucky,
    required this.template,
  });

  factory YourYear.compute(KuaPerson person, int year, AppContent? content) {
    final birth = person.timeKnown ? person.birth : DateTime(person.birth.year, person.birth.month, person.birth.day, 12);
    final z = zodiacForBirth(birth);
    final chart = computeBazi(birthLocal: person.birth, utcOffsetHours: 8, hourKnown: person.timeKnown);
    return YourYear._(
      person: person,
      year: year,
      zodiac: z,
      chart: chart,
      taiSui: taiSuiReading(z.branch.index, year),
      afflictions: yearAfflictions(year),
      lucky: luckyProfile(
        chart: chart,
        kua: person.kua,
        year: year,
        crystals: content?.crystals ?? const [],
        rituals: content?.rituals ?? const [],
      ),
      template: content?.year(year, z.animal),
    );
  }

  final KuaPerson person;
  final int year;
  final ZodiacYear zodiac;
  final BaziChart chart;
  final TaiSuiReading taiSui;
  final YearAfflictions afflictions;
  final LuckyProfile lucky;

  /// Null if no bundled written guide exists for this year and animal.
  final YearTemplate? template;

  /// Bundled text when present, otherwise a rule-based guide so the year is never blank.
  YearTemplate get guide => template ?? ruleBasedYearTemplate(this);

  bool get hasWrittenGuide => template != null;

  /// Template avoids first, then the lucky-list avoids. Rule-based guides
  /// already include those lucky-list avoids, so they are not repeated.
  List<String> get allAvoids =>
      hasWrittenGuide ? [...template!.avoids, ...lucky.avoids] : List<String>.from(guide.avoids);
}

/// Years that currently have a bundled written forecast (extended as packs land).
const forecastYears = [2026, 2027, 2028, 2029, 2030, 2031, 2032, 2033, 2034, 2035];

/// English name of a Li Chun year, e.g. "Earth Monkey year".
String yearEnglishName(int year) {
  final p = yearPillarFor(year);
  return '${p.stem.element.english} ${p.branch.animal} year';
}

List<String> _uniqueNonEmpty(Iterable<String> xs) {
  final out = <String>[];
  final seen = <String>{};
  for (final x in xs) {
    final s = x.trim();
    if (s.isEmpty || !seen.add(s)) continue;
    out.add(s);
  }
  return out;
}

/// A complete [YearTemplate] from Tai Sui, lucky lists and the year pillar.
YearTemplate ruleBasedYearTemplate(YourYear y) {
  final p = y.taiSui.yearPillar;
  final yearName = '${p.chinese} ${yearEnglishName(y.year)}';
  final relations = y.taiSui.relations.map((r) => r.english).join(', ');
  final fav = y.lucky.favourable.map((e) => e.english).join(', ');
  final unfav = y.lucky.unfavourable.map((e) => e.english).join(', ');
  final offends = y.taiSui.status == TaiSuiStatus.offends;
  final harmony = y.taiSui.status == TaiSuiStatus.harmony;
  final overview = offends
      ? 'In the $yearName your animal meets Tai Sui as $relations. Tradition treats this as a year to keep plans steady, finish what you have started, and avoid needless conflict. Use your lucky elements ($fav) in colour, direction and daily rhythm. This is a rule-based outline, not a written yearly essay.'
      : harmony
          ? 'In the $yearName your sign sits in $relations with Tai Sui. Tradition reads this as a supportive year for cooperation and for starting work you already have in mind. Favour $fav and go gently with $unfav. This is a rule-based outline, not a written yearly essay.'
          : 'In the $yearName your sign has no direct clash or harmony with Tai Sui. A steady year suits most plans. Lean on $fav and treat $unfav as secondary. This is a rule-based outline, not a written yearly essay.';
  final career = offends
      ? 'Keep the job you have in good shape before reaching for a headline move. Review promises, document work, and pick one visible task you can finish well. A new role can wait until the ground is firm, unless the offer is already clear.'
      : 'A good year to show your work and ask for the next step if the work is already solid. Favour rooms and seats in your lucky Kua directions. Avoid rushing a job change on a rumour.';
  final money = offends
      ? 'Hold back on large, reversible bets. Pay down clear debts, keep a cash buffer, and read the small print on any joint deal. Lucky numbers in this reading: ${y.lucky.luckyNumbers.join(', ')}.'
      : 'A sensible year for planned saving and for reviewing insurance, rent or a mortgage. Use lucky numbers ${y.lucky.luckyNumbers.join(', ')} as a light reminder, not a guarantee. Skip impulse purchases sold as "once only".';
  final love = offends
      ? 'Patience helps more than a dramatic reset. Say clearly what you need and keep family dates you have already made. New introductions can wait until you feel settled.'
      : 'A kinder year for introductions, family talks and repairing a cool patch, as long as you listen as much as you speak. Do not force a timeline on anyone.';
  final health = offends
      ? 'Protect sleep and a regular meal time. If you already have a check-up due, take it. This app does not give medical advice; treat rest as the first remedy.'
      : 'Keep the routines that already work: sleep, movement, and time outdoors. This app does not give medical advice.';
  final dos = _uniqueNonEmpty([
    if (offends) 'Keep plans modest and finish open work',
    if (harmony) 'Say yes to a collaboration you already trust',
    if (fav.isNotEmpty) 'Use $fav colours and directions when you can',
    'Sit or sleep toward a lucky Kua direction when you can',
    ...y.lucky.luckyRituals.take(2).map((r) => r.name),
  ]);
  final avoids = _uniqueNonEmpty([
    if (offends) 'Big, rushed decisions in an own-year or clash year',
    'Starting heavy renovation in Tai Sui, Year Breaker, Three Killings or Five Yellow',
    ...y.lucky.avoids.take(4),
  ]);
  // Lucky months: the year's three-harmony and six-harmony animals, when present.
  final luckyMonths = <String>[
    for (final r in y.taiSui.relations)
      if (r == TaiSuiRelation.threeHarmony || r == TaiSuiRelation.sixHarmony) y.zodiac.animal.toLowerCase(),
  ];
  // Always include a simple seasonal hint from the year branch's element friends — use the
  // next and previous animals as a mild "neighbouring month" cue when the list would be empty.
  final months = luckyMonths.isNotEmpty
      ? luckyMonths
      : [
          branches[(p.branch.index + 3) % 12].animal.toLowerCase(),
          branches[(p.branch.index + 9) % 12].animal.toLowerCase(),
        ];
  return YearTemplate(
    year: y.year,
    yearName: yearName,
    overview: overview,
    career: career,
    money: money,
    love: love,
    health: health,
    dos: dos,
    avoids: avoids,
    luckyMonths: _uniqueNonEmpty(months),
    taiSuiNote: y.taiSui.summary,
  );
}

/// The Li Chun year for "today" in Singapore time.
int currentSolarYear([DateTime? now]) {
  final n = (now ?? DateTime.now()).toUtc();
  return liChunYear(n);
}

String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
