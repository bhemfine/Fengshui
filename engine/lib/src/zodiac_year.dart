import 'flying_stars.dart';
import 'models.dart';
import 'solar_terms.dart';
import 'stems_branches.dart';
import 'bazi.dart' show yearPillarFor;
import 'kua.dart' show solarYearForBirth;

/// Na Yin (纳音 Na Yin, "received sound") element of a 60-cycle pair.
class NaYin {
  const NaYin(this.chinese, this.pinyin, this.english, this.element);
  final String chinese;
  final String pinyin;
  final String english;
  final FiveElement element;

  Map<String, Object?> toJson() =>
      {'chinese': chinese, 'pinyin': pinyin, 'english': english, 'element': element.name};
}

/// 30 Na Yin names; entry i covers cycle indices 2i and 2i+1 (甲子乙丑 = 海中金 ...).
const List<NaYin> naYinTable = [
  NaYin('海中金', 'Hai Zhong Jin', 'Sea Metal', FiveElement.metal), // 甲子 乙丑
  NaYin('炉中火', 'Lu Zhong Huo', 'Furnace Fire', FiveElement.fire), // 丙寅 丁卯
  NaYin('大林木', 'Da Lin Mu', 'Great Forest Wood', FiveElement.wood), // 戊辰 己巳
  NaYin('路旁土', 'Lu Pang Tu', 'Roadside Earth', FiveElement.earth), // 庚午 辛未
  NaYin('剑锋金', 'Jian Feng Jin', 'Sword-Edge Metal', FiveElement.metal), // 壬申 癸酉
  NaYin('山头火', 'Shan Tou Huo', 'Mountain-Top Fire', FiveElement.fire), // 甲戌 乙亥
  NaYin('涧下水', 'Jian Xia Shui', 'Stream Water', FiveElement.water), // 丙子 丁丑
  NaYin('城头土', 'Cheng Tou Tu', 'City-Wall Earth', FiveElement.earth), // 戊寅 己卯
  NaYin('白蜡金', 'Bai La Jin', 'White Wax Metal', FiveElement.metal), // 庚辰 辛巳
  NaYin('杨柳木', 'Yang Liu Mu', 'Willow Wood', FiveElement.wood), // 壬午 癸未
  NaYin('泉中水', 'Quan Zhong Shui', 'Spring Water', FiveElement.water), // 甲申 乙酉
  NaYin('屋上土', 'Wu Shang Tu', 'Roof-Tile Earth', FiveElement.earth), // 丙戌 丁亥
  NaYin('霹雳火', 'Pi Li Huo', 'Thunderbolt Fire', FiveElement.fire), // 戊子 己丑
  NaYin('松柏木', 'Song Bai Mu', 'Pine and Cypress Wood', FiveElement.wood), // 庚寅 辛卯
  NaYin('长流水', 'Chang Liu Shui', 'Long-Flowing Water', FiveElement.water), // 壬辰 癸巳
  NaYin('砂中金', 'Sha Zhong Jin', 'Sand Metal', FiveElement.metal), // 甲午 乙未
  NaYin('山下火', 'Shan Xia Huo', 'Foot-of-Mountain Fire', FiveElement.fire), // 丙申 丁酉
  NaYin('平地木', 'Ping Di Mu', 'Flatland Wood', FiveElement.wood), // 戊戌 己亥
  NaYin('壁上土', 'Bi Shang Tu', 'Wall Earth', FiveElement.earth), // 庚子 辛丑
  NaYin('金箔金', 'Jin Bo Jin', 'Gold-Leaf Metal', FiveElement.metal), // 壬寅 癸卯
  NaYin('覆灯火', 'Fu Deng Huo', 'Lamp Fire', FiveElement.fire), // 甲辰 乙巳
  NaYin('天河水', 'Tian He Shui', 'Heavenly River Water', FiveElement.water), // 丙午 丁未
  NaYin('大驿土', 'Da Yi Tu', 'Great Post-Road Earth', FiveElement.earth), // 戊申 己酉
  NaYin('钗钏金', 'Chai Chuan Jin', 'Hairpin Metal', FiveElement.metal), // 庚戌 辛亥
  NaYin('桑柘木', 'Sang Zhe Mu', 'Mulberry Wood', FiveElement.wood), // 壬子 癸丑
  NaYin('大溪水', 'Da Xi Shui', 'Great Stream Water', FiveElement.water), // 甲寅 乙卯
  NaYin('沙中土', 'Sha Zhong Tu', 'Sand Earth', FiveElement.earth), // 丙辰 丁巳
  NaYin('天上火', 'Tian Shang Huo', 'Sky Fire', FiveElement.fire), // 戊午 己未
  NaYin('石榴木', 'Shi Liu Mu', 'Pomegranate Wood', FiveElement.wood), // 庚申 辛酉
  NaYin('大海水', 'Da Hai Shui', 'Great Sea Water', FiveElement.water), // 壬戌 癸亥
];

NaYin naYinFor(Pillar p) => naYinTable[p.cycleIndex ~/ 2];

/// A person's zodiac year with the three elements people quote.
class ZodiacYear {
  const ZodiacYear({required this.solarYear, required this.pillar});

  /// Li Chun (立春) year the birth falls in.
  final int solarYear;
  final Pillar pillar;

  Branch get branch => pillar.branch;
  String get animal => pillar.branch.animal;

  /// Year element from the stem (庚 = Metal): what "Metal Horse" means.
  FiveElement get yearElement => pillar.stem.element;

  /// The animal's fixed element from the branch (午 Horse is always Fire).
  FiveElement get animalElement => pillar.branch.element;
  NaYin get naYin => naYinFor(pillar);

  /// e.g. "Metal Horse".
  String get name => '${yearElement.english} $animal';

  String get explainer =>
      'Most calculators name the year by its stem ${pillar.stem.chinese} (${yearElement.english}), '
      'so you are a $name. The $animal itself always carries ${animalElement.english}, and the older '
      'Na Yin system calls ${pillar.chinese} ${naYin.chinese} ${naYin.english}. All three are right; '
      'they answer different questions.';

  Map<String, Object?> toJson() => {
        'solarYear': solarYear,
        'pillar': pillar.toJson(),
        'animal': animal,
        'name': name,
        'yearElement': yearElement.name,
        'animalElement': animalElement.name,
        'naYin': naYin.toJson(),
        'explainer': explainer,
      };
}

ZodiacYear zodiacForSolarYear(int solarYear) =>
    ZodiacYear(solarYear: solarYear, pillar: yearPillarFor(solarYear));

/// Zodiac year for a wall-clock birth (switches at Li Chun, like BaZi and Kua).
ZodiacYear zodiacForBirth(DateTime birthLocal, {double utcOffsetHours = 8.0}) =>
    zodiacForSolarYear(solarYearForBirth(birthLocal, utcOffsetHours: utcOffsetHours));

/// Relations between a birth-year branch and the year's Tai Sui (太岁) branch.
enum TaiSuiRelation {
  benMing('本命', 'Ben Ming', 'Own year (值太岁)', true),
  selfPunishment('自刑', 'Zi Xing', 'Self-punishment', true),
  clash('冲', 'Chong', 'Clash', true),
  punishment('刑', 'Xing', 'Punishment', true),
  harm('害', 'Hai', 'Harm', true),
  breaks('破', 'Po', 'Break', true),
  sixHarmony('六合', 'Liu He', 'Six Harmony', false),
  threeHarmony('三合', 'San He', 'Three Harmony', false);

  const TaiSuiRelation(this.chinese, this.pinyin, this.english, this.offends);
  final String chinese;
  final String pinyin;
  final String english;

  /// Counted as offending Tai Sui (犯太岁 Fan Tai Sui) in folk practice.
  final bool offends;
}

const _selfPunish = {4, 6, 9, 11}; // 辰 午 酉 亥
const _punishGroups = [
  {2, 5, 8}, // 寅巳申 ungrateful punishment
  {1, 7, 10}, // 丑未戌 bullying punishment
  {0, 3}, // 子卯 rude punishment
];
const _breakPairs = [
  {0, 9}, {3, 6}, {1, 4}, {7, 10}, {2, 11}, {5, 8}, // 子酉 卯午 辰丑 未戌 寅亥 巳申
];

/// All relations between [birthBranch] and [yearBranch] (0 = 子 Rat).
List<TaiSuiRelation> taiSuiRelations(int birthBranch, int yearBranch) {
  final b = birthBranch % 12, y = yearBranch % 12;
  final out = <TaiSuiRelation>[];
  if (b == y) {
    out.add(TaiSuiRelation.benMing);
    if (_selfPunish.contains(b)) out.add(TaiSuiRelation.selfPunishment);
    return out;
  }
  if (clashPartner(b) == y) out.add(TaiSuiRelation.clash);
  if (_punishGroups.any((g) => g.contains(b) && g.contains(y))) out.add(TaiSuiRelation.punishment);
  if ((b + y) % 12 == 7) out.add(TaiSuiRelation.harm);
  if (_breakPairs.any((g) => g.contains(b) && g.contains(y))) out.add(TaiSuiRelation.breaks);
  if (sixHarmonyPartner(b) == y) out.add(TaiSuiRelation.sixHarmony);
  if (inThreeHarmony(b, y)) out.add(TaiSuiRelation.threeHarmony);
  return out;
}

enum TaiSuiStatus { offends, harmony, neutral }

class TaiSuiReading {
  const TaiSuiReading({required this.year, required this.yearPillar, required this.relations});
  final int year;
  final Pillar yearPillar;
  final List<TaiSuiRelation> relations;

  TaiSuiStatus get status {
    if (relations.any((r) => r.offends)) return TaiSuiStatus.offends;
    if (relations.isNotEmpty) return TaiSuiStatus.harmony;
    return TaiSuiStatus.neutral;
  }

  /// e.g. "本命年·自刑".
  String get chineseLabel {
    if (relations.isEmpty) return '无冲合';
    return relations
        .map((r) => r == TaiSuiRelation.benMing ? '本命年' : r.chinese)
        .join('·');
  }

  String get englishLabel {
    if (relations.isEmpty) return 'No clash or harmony';
    return relations.map((r) => r.english).join(' + ');
  }

  String get summary => switch (status) {
        TaiSuiStatus.offends =>
          'Fan Tai Sui (犯太岁): your sign meets the $year Tai Sui as $englishLabel. Tradition says keep the year steady.',
        TaiSuiStatus.harmony =>
          'He Tai Sui (合太岁): $englishLabel with the $year Tai Sui. Tradition reads this as supportive.',
        TaiSuiStatus.neutral => 'No direct clash or harmony with the $year Tai Sui.',
      };

  Map<String, Object?> toJson() => {
        'year': year,
        'yearPillar': yearPillar.chinese,
        'relations': relations.map((r) => r.name).toList(),
        'status': status.name,
        'label': chineseLabel,
      };
}

TaiSuiReading taiSuiReading(int birthBranch, int year) {
  final yp = yearPillarFor(year);
  return TaiSuiReading(year: year, yearPillar: yp, relations: taiSuiRelations(birthBranch, yp.branch.index));
}

/// Palace (8 directions) of each branch.
const List<Direction> branchDirection = [
  Direction.n, Direction.ne, Direction.ne, Direction.e, Direction.se, Direction.se,
  Direction.s, Direction.sw, Direction.sw, Direction.w, Direction.nw, Direction.nw,
];

/// The year's afflicted directions (Tai Sui 太岁, Year Breaker 岁破, Three Killings 三煞).
class YearAfflictions {
  const YearAfflictions({
    required this.year,
    required this.yearPillar,
    required this.taiSui,
    required this.taiSuiMountain,
    required this.yearBreaker,
    required this.yearBreakerMountain,
    required this.threeKillings,
    required this.threeKillingsMountains,
    required this.fiveYellow,
    required this.twoBlack,
  });
  final int year;
  final Pillar yearPillar;
  final Direction taiSui;
  final Mountain taiSuiMountain;
  final Direction yearBreaker;
  final Mountain yearBreakerMountain;
  final Direction threeKillings;
  final List<Mountain> threeKillingsMountains;

  /// Annual Flying Star 5 and 2 palaces (from [annualChart]).
  final Direction fiveYellow;
  final Direction twoBlack;

  /// Directions where tradition says not to start renovation this year.
  Set<Direction> get noRenovation => {taiSui, yearBreaker, threeKillings, fiveYellow};

  Map<String, Object?> toJson() => {
        'year': year,
        'taiSui': taiSui.name,
        'yearBreaker': yearBreaker.name,
        'threeKillings': threeKillings.name,
        'fiveYellow': fiveYellow.name,
        'twoBlack': twoBlack.name,
      };
}

/// Mountain index (0 = 壬) for a branch: 子 = 1, 丑 = 3, ...
Mountain mountainOfBranch(int branch) => mountains[(branch % 12) * 2 + 1];

YearAfflictions yearAfflictions(int year) {
  final yp = yearPillarFor(year);
  final b = yp.branch.index;
  final breaker = clashPartner(b);
  // Three Killings sit opposite the year's Three Harmony element:
  // 申子辰 Water → South, 寅午戌 Fire → North, 亥卯未 Wood → West, 巳酉丑 Metal → East.
  final group = b % 4; // 0: 子辰申, 1: 丑巳酉, 2: 寅午戌, 3: 卯未亥
  final (Direction ks, List<int> ksBranches) = switch (group) {
    0 => (Direction.s, [5, 6, 7]),
    1 => (Direction.e, [2, 3, 4]),
    2 => (Direction.n, [11, 0, 1]),
    _ => (Direction.w, [8, 9, 10]),
  };
  final annual = annualChart(year);
  Direction where(int star) => annual.entries.firstWhere((e) => e.value == star).key;
  return YearAfflictions(
    year: year,
    yearPillar: yp,
    taiSui: branchDirection[b],
    taiSuiMountain: mountainOfBranch(b),
    yearBreaker: branchDirection[breaker],
    yearBreakerMountain: mountainOfBranch(breaker),
    threeKillings: ks,
    threeKillingsMountains: [for (final x in ksBranches) mountainOfBranch(x)],
    fiveYellow: where(5),
    twoBlack: where(2),
  );
}

/// Convenience: Li Chun year for a UTC instant (re-exported for screens).
int solarYearOf(DateTime utc) => liChunYear(utc);
