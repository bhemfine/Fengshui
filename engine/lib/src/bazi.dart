import 'models.dart';
import 'solar_terms.dart';
import 'stems_branches.dart';

/// Day-boundary convention for the Zi 子 (Rat) double hour 23:00–01:00.
enum ZiConvention {
  /// Day pillar changes at 23:00 (early Zi 早子 Zao Zi convention). Default.
  dayChangesAt23,

  /// Day pillar changes at 00:00; 23:00–24:00 hour stem uses next day's stem (late Zi 夜子 Ye Zi).
  dayChangesAtMidnight,
}

/// Julian Day Number for a Gregorian civil date.
int julianDayNumber(int y, int m, int d) =>
    DateTime.utc(y, m, d).difference(DateTime.utc(2000, 1, 1)).inDays + 2451545;

/// Day pillar for a civil date. Anchor: 2000-01-01 = 戊午 Wu-Wu (index 54).
Pillar dayPillarForDate(int y, int m, int d) => Pillar.fromCycleIndex(julianDayNumber(y, m, d) + 49);

/// Year pillar for a Li Chun year number.
Pillar yearPillarFor(int liChunYear) => Pillar.fromCycleIndex(liChunYear - 4);

/// Month pillar by five-tiger rule (五虎遁 Wu Hu Dun). [monthIndex] 0 = 寅 Yin month.
Pillar monthPillarFor(int yearStem, int monthIndex) {
  final firstStem = ((yearStem % 5) * 2 + 2) % 10;
  return Pillar(stems[(firstStem + monthIndex) % 10], branches[(monthIndex + 2) % 12]);
}

/// Hour pillar by five-rat rule (五鼠遁 Wu Shu Dun).
Pillar hourPillarFor(int dayStem, int hourBranch) {
  final ziStem = ((dayStem % 5) * 2) % 10;
  return Pillar(stems[(ziStem + hourBranch) % 10], branches[hourBranch]);
}

int hourBranchFor(int hour) => ((hour + 1) ~/ 2) % 12;

/// Computes the Four Pillars (四柱 Si Zhu).
///
/// [birthLocal] wall-clock fields are used as-is (time zone ignored);
/// [utcOffsetHours] converts to UTC. If [useTrueSolarTime] and [longitude] given,
/// day/hour use local *mean* solar time (equation of time TODO).
BaziChart computeBazi({
  required DateTime birthLocal,
  required double utcOffsetHours,
  bool hourKnown = true,
  double? longitude,
  bool useTrueSolarTime = false,
  ZiConvention zi = ZiConvention.dayChangesAt23,
}) {
  final wall = DateTime.utc(birthLocal.year, birthLocal.month, birthLocal.day,
      hourKnown ? birthLocal.hour : 12, hourKnown ? birthLocal.minute : 0);
  final utc = wall.subtract(Duration(minutes: (utcOffsetHours * 60).round()));

  var local = wall;
  if (useTrueSolarTime && longitude != null) {
    local = utc.add(Duration(seconds: (longitude * 240).round()));
  }

  final yearP = yearPillarFor(liChunYear(utc));
  final monthP = monthPillarFor(yearP.stem.index, solarMonthIndex(utc));

  var dayDate = DateTime.utc(local.year, local.month, local.day);
  if (hourKnown && zi == ZiConvention.dayChangesAt23 && local.hour >= 23) {
    dayDate = DateTime.utc(local.year, local.month, local.day + 1);
  }
  final dayP = dayPillarForDate(dayDate.year, dayDate.month, dayDate.day);

  Pillar? hourP;
  if (hourKnown) {
    var stemForHour = dayP.stem.index;
    if (zi == ZiConvention.dayChangesAtMidnight && local.hour >= 23) {
      stemForHour = (stemForHour + 1) % 10;
    }
    hourP = hourPillarFor(stemForHour, hourBranchFor(local.hour));
  }

  final pillars = [yearP, monthP, dayP, ?hourP];
  final counts = {for (final e in FiveElement.values) e: 0};
  for (final p in pillars) {
    counts[p.stem.element] = counts[p.stem.element]! + 1;
    counts[p.branch.element] = counts[p.branch.element]! + 1;
  }

  final hidden = <String, List<Stem>>{
    'year': hiddenStemsOf(yearP.branch),
    'month': hiddenStemsOf(monthP.branch),
    'day': hiddenStemsOf(dayP.branch),
    if (hourP != null) 'hour': hiddenStemsOf(hourP.branch),
  };

  // HEURISTIC strength: share of same + resource elements, plus seasonal bonus.
  final dm = dayP.stem.element;
  final total = counts.values.fold<int>(0, (a, b) => a + b) - 1;
  var support = (counts[dm]! - 1) + counts[dm.producedBy]!.toDouble();
  final mEl = monthP.branch.element;
  var denom = total.toDouble();
  if (mEl == dm || mEl == dm.producedBy) {
    support += 1;
  }
  denom += 1;
  final ratio = denom <= 0 ? 0.5 : support / denom;
  final StrengthLevel level;
  final List<FiveElement> fav;
  if (ratio >= 0.6) {
    level = StrengthLevel.strong;
    fav = [dm.produces, dm.controls, dm.controlledBy];
  } else if (ratio <= 0.4) {
    level = StrengthLevel.weak;
    fav = [dm.producedBy, dm];
  } else {
    level = StrengthLevel.balanced;
    final sorted = FiveElement.values.toList()..sort((a, b) => counts[a]!.compareTo(counts[b]!));
    fav = [sorted.first];
  }

  return BaziChart(
    year: yearP,
    month: monthP,
    day: dayP,
    hour: hourP,
    elementCounts: counts,
    hiddenStems: hidden,
    strength: level,
    strengthRatio: ratio,
    favourableElements: fav,
    utcOffsetHours: utcOffsetHours,
  );
}
