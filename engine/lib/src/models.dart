import 'stems_branches.dart';

/// Five Elements (五行 Wu Xing, Five Phases).
enum FiveElement {
  wood('木', 'Mu', 'Wood'),
  fire('火', 'Huo', 'Fire'),
  earth('土', 'Tu', 'Earth'),
  metal('金', 'Jin', 'Metal'),
  water('水', 'Shui', 'Water');

  const FiveElement(this.chinese, this.pinyin, this.english);
  final String chinese;
  final String pinyin;
  final String english;

  /// Element this one produces (生 Sheng, Production cycle).
  FiveElement get produces => FiveElement.values[(index + 1) % 5];

  /// Element this one controls (克 Ke, Control cycle).
  FiveElement get controls => FiveElement.values[(index + 2) % 5];

  /// Element that produces this one (resource).
  FiveElement get producedBy => FiveElement.values[(index + 4) % 5];

  /// Element that controls this one.
  FiveElement get controlledBy => FiveElement.values[(index + 3) % 5];
}

enum Gender { male, female }

/// Compass palaces of the Lo Shu (洛书 Luo Shu) grid.
enum Direction { n, ne, e, se, s, sw, w, nw, centre }

const Map<Direction, Direction> oppositeDirection = {
  Direction.n: Direction.s,
  Direction.s: Direction.n,
  Direction.e: Direction.w,
  Direction.w: Direction.e,
  Direction.ne: Direction.sw,
  Direction.sw: Direction.ne,
  Direction.se: Direction.nw,
  Direction.nw: Direction.se,
  Direction.centre: Direction.centre,
};

/// One pillar (柱 Zhu): a stem + branch pair of the 60-cycle.
class Pillar {
  const Pillar(this.stem, this.branch);

  factory Pillar.fromCycleIndex(int n) {
    final i = n % 60;
    return Pillar(stems[i % 10], branches[i % 12]);
  }

  final Stem stem;
  final Branch branch;

  int get cycleIndex => sexagenaryIndex(stem.index, branch.index);
  String get chinese => '${stem.chinese}${branch.chinese}';
  String get pinyin => '${stem.pinyin}-${branch.pinyin}';

  @override
  bool operator ==(Object other) =>
      other is Pillar && other.stem.index == stem.index && other.branch.index == branch.index;

  @override
  int get hashCode => Object.hash(stem.index, branch.index);

  @override
  String toString() => '$chinese ($pinyin)';

  Map<String, Object?> toJson() => {
        'chinese': chinese,
        'pinyin': pinyin,
        'cycleIndex': cycleIndex,
        'stem': stem.toJson(),
        'branch': branch.toJson(),
      };
}

enum StrengthLevel { weak, balanced, strong }

class BaziChart {
  const BaziChart({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.elementCounts,
    required this.hiddenStems,
    required this.strength,
    required this.strengthRatio,
    required this.favourableElements,
    required this.utcOffsetHours,
  });

  final Pillar year;
  final Pillar month;
  final Pillar day;

  /// Null when the birth hour is unknown.
  final Pillar? hour;
  final Map<FiveElement, int> elementCounts;

  /// Hidden stems (藏干 Cang Gan) per pillar position: 'year','month','day','hour'.
  final Map<String, List<Stem>> hiddenStems;
  final StrengthLevel strength;
  final double strengthRatio;

  /// HEURISTIC favourable elements (喜用神 Xi Yong Shen, approximate). Entertainment only.
  final List<FiveElement> favourableElements;
  final double utcOffsetHours;

  /// Day Master (日主 Ri Zhu): the day stem.
  Stem get dayMaster => day.stem;

  Map<String, Object?> toJson() => {
        'year': year.toJson(),
        'month': month.toJson(),
        'day': day.toJson(),
        'hour': hour?.toJson(),
        'dayMaster': dayMaster.toJson(),
        'elementCounts': {for (final e in elementCounts.entries) e.key.name: e.value},
        'hiddenStems': {
          for (final e in hiddenStems.entries) e.key: e.value.map((s) => s.chinese).toList()
        },
        'strength': strength.name,
        'strengthRatio': strengthRatio,
        'favourableElementsHeuristic': favourableElements.map((e) => e.name).toList(),
        'utcOffsetHours': utcOffsetHours,
      };
}

class DirectionInfo {
  const DirectionInfo(this.key, this.chinese, this.pinyin, this.english, this.direction, this.lucky);
  final String key;
  final String chinese;
  final String pinyin;
  final String english;
  final Direction direction;
  final bool lucky;

  Map<String, Object?> toJson() => {
        'key': key,
        'chinese': chinese,
        'pinyin': pinyin,
        'english': english,
        'direction': direction.name,
        'lucky': lucky,
      };
}

class KuaResult {
  const KuaResult({
    required this.kua,
    required this.adjustedYear,
    required this.eastGroup,
    required this.directions,
  });
  final int kua;
  final int adjustedYear;
  final bool eastGroup;
  final List<DirectionInfo> directions;

  List<DirectionInfo> get lucky => directions.where((d) => d.lucky).toList();
  List<DirectionInfo> get unlucky => directions.where((d) => !d.lucky).toList();

  Map<String, Object?> toJson() => {
        'kua': kua,
        'adjustedYear': adjustedYear,
        'group': eastGroup ? 'east' : 'west',
        'directions': directions.map((d) => d.toJson()).toList(),
      };
}

class PalaceStars {
  const PalaceStars(this.base, this.mountain, this.facing);

  /// Period/base star (运星 Yun Xing).
  final int base;

  /// Mountain/sitting star (山星 Shan Xing).
  final int mountain;

  /// Facing/water star (向星 Xiang Xing).
  final int facing;

  Map<String, Object?> toJson() => {'base': base, 'mountain': mountain, 'facing': facing};
}

class FlyingStarChart {
  const FlyingStarChart({
    required this.period,
    required this.facingDegree,
    required this.facingMountain,
    required this.sittingMountain,
    required this.palaces,
    required this.formations,
  });
  final int period;
  final double facingDegree;
  final int facingMountain;
  final int sittingMountain;
  final Map<Direction, PalaceStars> palaces;
  final List<String> formations;

  Map<String, Object?> toJson() => {
        'period': period,
        'facingDegree': facingDegree,
        'facingMountain': facingMountain,
        'sittingMountain': sittingMountain,
        'palaces': {for (final e in palaces.entries) e.key.name: e.value.toJson()},
        'formations': formations,
        'replacementChart': 'not_implemented',
      };
}

class AlmanacDay {
  const AlmanacDay({
    required this.date,
    required this.dayPillar,
    required this.monthBranch,
    required this.officerIndex,
    required this.clashBranch,
    required this.luckyHourBranches,
    required this.goodFor,
    required this.avoid,
  });
  final DateTime date;
  final Pillar dayPillar;
  final Branch monthBranch;

  /// Index into [dayOfficers] (建除十二神 Jian Chu Shi Er Shen, Twelve Day Officers).
  final int officerIndex;
  final Branch clashBranch;
  final List<Branch> luckyHourBranches;
  final List<String> goodFor;
  final List<String> avoid;

  Map<String, Object?> toJson() => {
        'date': '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'dayPillar': dayPillar.toJson(),
        'monthBranch': monthBranch.toJson(),
        'officerIndex': officerIndex,
        'clashAnimal': clashBranch.animal,
        'luckyHours': luckyHourBranches.map((b) => b.pinyin).toList(),
        'goodFor': goodFor,
        'avoid': avoid,
      };
}
