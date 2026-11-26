import 'home_facing.dart' show directionLong;
import 'models.dart';
import 'zodiac_year.dart';

/// Rule-based lucky / unlucky profile for one person and one year.
///
/// Methods (shown in the UI):
/// - Elements: favourable = the BaZi heuristic in [BaziChart.favourableElements];
///   unfavourable = the two most plentiful other elements in the chart.
/// - Colours: the classic colour of each element.
/// - Numbers: He Tu (河图) pairs 1·6 Water, 2·7 Fire, 3·8 Wood, 4·9 Metal, 5·0 Earth.
/// - Directions: the four Kua good directions, minus any the year afflicts
///   (Tai Sui, Year Breaker, Three Killings, annual 5 and 2 stars).
/// - Items: crystals whose element is favourable and rituals by intent tag.

const Map<FiveElement, List<String>> elementColours = {
  FiveElement.wood: ['green', 'teal'],
  FiveElement.fire: ['red', 'orange', 'purple', 'pink'],
  FiveElement.earth: ['yellow', 'beige', 'brown'],
  FiveElement.metal: ['white', 'gold', 'silver'],
  FiveElement.water: ['black', 'navy', 'blue'],
};

/// He Tu (河图) numbers per element.
const Map<FiveElement, List<int>> heTuNumbers = {
  FiveElement.water: [1, 6],
  FiveElement.fire: [2, 7],
  FiveElement.wood: [3, 8],
  FiveElement.metal: [4, 9],
  FiveElement.earth: [5, 0],
};

/// Minimal crystal record (from content/crystals.json).
class CrystalItem {
  const CrystalItem({required this.id, required this.name, required this.element, required this.intentions});
  final String id;
  final String name;
  final FiveElement element;
  final List<String> intentions;

  factory CrystalItem.fromJson(Map<String, Object?> j) => CrystalItem(
        id: j['id']! as String,
        name: j['name']! as String,
        element: FiveElement.values.byName((j['element']! as String).toLowerCase()),
        intentions: [for (final i in (j['intentions'] as List? ?? const [])) i as String],
      );
}

/// Minimal ritual record (from content/rituals.json).
class RitualItem {
  const RitualItem({required this.id, required this.name, required this.intents});
  final String id;
  final String name;
  final List<String> intents;

  factory RitualItem.fromJson(Map<String, Object?> j) => RitualItem(
        id: j['id']! as String,
        name: j['name']! as String,
        intents: [for (final i in (j['intent'] as List? ?? const [])) i as String],
      );
}

/// How the year's stem element relates to the Day Master (simplified Ten Gods).
String yearElementNote(FiveElement dayMaster, FiveElement yearEl) {
  final role = yearEl == dayMaster
      ? 'Companion (same element): friends and rivals both show up'
      : yearEl == dayMaster.producedBy
          ? 'Resource (it feeds you): support, learning and mentors'
          : yearEl == dayMaster.produces
              ? 'Output (you feed it): ideas and expression, but it tires you'
              : yearEl == dayMaster.controls
                  ? 'Wealth (you control it): money chances that take effort'
                  : 'Power (it controls you): pressure, rules and responsibility';
  return 'The year element ${yearEl.english} is your $role.';
}

class LuckyDirection {
  const LuckyDirection(this.info, this.caution);
  final DirectionInfo info;

  /// Non-null when the year afflicts this direction.
  final String? caution;
}

class LuckyProfile {
  const LuckyProfile({
    required this.year,
    required this.favourable,
    required this.unfavourable,
    required this.luckyColours,
    required this.unluckyColours,
    required this.luckyNumbers,
    required this.unluckyNumbers,
    required this.luckyDirections,
    required this.unluckyDirections,
    required this.luckyCrystals,
    required this.luckyRituals,
    required this.unluckyCrystals,
    required this.avoids,
    required this.yearElementNote,
  });
  final int year;
  final List<FiveElement> favourable;
  final List<FiveElement> unfavourable;
  final List<String> luckyColours;
  final List<String> unluckyColours;
  final List<int> luckyNumbers;
  final List<int> unluckyNumbers;
  final List<LuckyDirection> luckyDirections;

  /// Kua bad directions plus the year's afflicted ones (deduplicated, text).
  final List<String> unluckyDirections;
  final List<CrystalItem> luckyCrystals;
  final List<RitualItem> luckyRituals;
  final List<CrystalItem> unluckyCrystals;
  final List<String> avoids;
  final String yearElementNote;

  static const methodNote =
      'Rule-based, offline. Elements from your BaZi (heuristic), colours by element, numbers from the '
      'He Tu (河图), directions from your Kua minus this year\'s afflicted sectors, items by element and tag.';

  Map<String, Object?> toJson() => {
        'year': year,
        'favourable': favourable.map((e) => e.name).toList(),
        'unfavourable': unfavourable.map((e) => e.name).toList(),
        'luckyColours': luckyColours,
        'unluckyColours': unluckyColours,
        'luckyNumbers': luckyNumbers,
        'unluckyNumbers': unluckyNumbers,
        'luckyDirections': [
          for (final d in luckyDirections) {'direction': d.info.direction.name, 'caution': d.caution}
        ],
        'unluckyDirections': unluckyDirections,
        'luckyCrystals': luckyCrystals.map((c) => c.id).toList(),
        'luckyRituals': luckyRituals.map((r) => r.id).toList(),
        'unluckyCrystals': unluckyCrystals.map((c) => c.id).toList(),
        'avoids': avoids,
      };
}

String _dl(Direction d) => directionLong[d]!;

/// "South (Tai Sui, Five Yellow) or North (Year Breaker, Three Killings)".
String _renoList(YearAfflictions a) {
  final by = <Direction, List<String>>{};
  void add(Direction d, String why) => (by[d] ??= []).add(why);
  add(a.taiSui, 'Tai Sui');
  add(a.yearBreaker, 'Year Breaker');
  add(a.threeKillings, 'Three Killings');
  add(a.fiveYellow, 'Five Yellow');
  return by.entries.map((e) => '${_dl(e.key)} (${e.value.join(', ')})').join(' or ');
}

/// Unfavourable elements: the two most plentiful elements that are not favourable.
List<FiveElement> unfavourableElements(BaziChart chart) {
  final rest = FiveElement.values.where((e) => !chart.favourableElements.contains(e)).toList()
    ..sort((a, b) {
      final c = chart.elementCounts[b]!.compareTo(chart.elementCounts[a]!);
      // Tie-break: the element that controls the Day Master first.
      if (c != 0) return c;
      final dm = chart.dayMaster.element;
      int rank(FiveElement e) => e == dm.controlledBy ? 0 : 1;
      return rank(a).compareTo(rank(b));
    });
  return rest.take(2).toList();
}

LuckyProfile luckyProfile({
  required BaziChart chart,
  required KuaResult kua,
  required int year,
  List<CrystalItem> crystals = const [],
  List<RitualItem> rituals = const [],
}) {
  final fav = chart.favourableElements;
  final unfav = unfavourableElements(chart);
  final aff = yearAfflictions(year);
  final tai = taiSuiReading(chart.year.branch.index, year);

  String? cautionFor(Direction d) {
    final why = <String>[
      if (d == aff.taiSui) 'Tai Sui (do not face it)',
      if (d == aff.yearBreaker) 'Year Breaker',
      if (d == aff.threeKillings) 'Three Killings (do not sit with your back to it)',
      if (d == aff.fiveYellow) 'Five Yellow star',
      if (d == aff.twoBlack) 'Two Black star',
    ];
    return why.isEmpty ? null : why.join(', ');
  }

  final luckyDirs = [for (final d in kua.lucky) LuckyDirection(d, cautionFor(d.direction))];
  final unluckyDirs = <String>[
    for (final d in kua.unlucky) '${_dl(d.direction)} (${d.english})',
    for (final d in Direction.values)
      if (d != Direction.centre && cautionFor(d) != null && !kua.unlucky.any((u) => u.direction == d))
        '${_dl(d)} ($year: ${cautionFor(d)})',
  ];

  // Crystals: favourable element first, protection/calm first in a Tai Sui offence year.
  final wantIntents = tai.status == TaiSuiStatus.offends
      ? ['protection', 'calm', 'grounding']
      : ['luck', 'wealth', 'career', 'growth'];
  int score(CrystalItem c) => c.intentions.where(wantIntents.contains).length;
  final favCrystals = crystals.where((c) => fav.contains(c.element)).toList()
    ..sort((a, b) {
      final s = score(b).compareTo(score(a));
      return s != 0 ? s : fav.indexOf(a.element).compareTo(fav.indexOf(b.element));
    });
  final unfavCrystals = crystals.where((c) => unfav.contains(c.element)).take(3).toList();

  final ritualIntents = tai.status == TaiSuiStatus.offends
      ? ['protection', 'clarity', 'home_harmony']
      : ['wealth', 'career', 'home_harmony'];
  final picked = <RitualItem>[];
  if (tai.relations.contains(TaiSuiRelation.benMing)) {
    picked.addAll(rituals.where((r) => r.id == 'lucky_red_thread'));
  }
  for (final intent in ritualIntents) {
    for (final r in rituals) {
      if (picked.length >= 3) break;
      if (r.intents.contains(intent) && !picked.contains(r)) {
        picked.add(r);
        break;
      }
    }
  }

  final avoids = <String>[
    'Starting renovation, hacking or drilling in the ${_renoList(aff)} this year.',
    'Facing the ${_dl(aff.taiSui)} for long spells at your desk (facing Tai Sui).',
    'Leaning on ${unfav.map((e) => e.english).join(' and ')} colours (${unfav.expand((e) => elementColours[e]!).take(4).join(', ')}) for big days.',
    if (tai.status == TaiSuiStatus.offends) 'Rushed big moves: tradition says keep a ${tai.chineseLabel} year steady.',
  ];

  return LuckyProfile(
    year: year,
    favourable: fav,
    unfavourable: unfav,
    luckyColours: [for (final e in fav) ...elementColours[e]!],
    unluckyColours: [for (final e in unfav) ...elementColours[e]!],
    luckyNumbers: [for (final e in fav) ...heTuNumbers[e]!],
    unluckyNumbers: [for (final e in unfav) ...heTuNumbers[e]!],
    luckyDirections: luckyDirs,
    unluckyDirections: unluckyDirs,
    luckyCrystals: favCrystals.take(3).toList(),
    luckyRituals: picked,
    unluckyCrystals: unfavCrystals,
    avoids: avoids,
    yearElementNote: yearElementNote(chart.dayMaster.element, yearPillarForYear(year).stem.element),
  );
}

/// Year pillar helper (kept here so screens need one import).
Pillar yearPillarForYear(int year) => yearAfflictions(year).yearPillar;
