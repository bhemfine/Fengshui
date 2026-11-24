import 'bazi.dart';
import 'models.dart';
import 'solar_terms.dart';
import 'stems_branches.dart';

/// Twelve Day Officers (建除十二神 Jian Chu Shi Er Shen).
class DayOfficer {
  const DayOfficer(this.chinese, this.pinyin, this.english, this.baseScore, this.goodFor, this.avoid);
  final String chinese;
  final String pinyin;
  final String english;
  final int baseScore;
  final List<String> goodFor;
  final List<String> avoid;
}

const List<DayOfficer> dayOfficers = [
  DayOfficer('建', 'Jian', 'Establish', 60, ['signing', 'travel'], ['moving_house', 'renovation']),
  DayOfficer('除', 'Chu', 'Remove', 65, ['haircut', 'renovation'], ['wedding']),
  DayOfficer('满', 'Man', 'Full', 60, ['signing', 'wedding'], ['haircut']),
  DayOfficer('平', 'Ping', 'Balance', 50, ['renovation'], ['travel']),
  DayOfficer('定', 'Ding', 'Stable', 70, ['signing', 'wedding'], ['travel']),
  DayOfficer('执', 'Zhi', 'Initiate', 55, ['renovation', 'signing'], ['moving_house']),
  DayOfficer('破', 'Po', 'Destruction', 25, ['haircut'], ['wedding', 'signing', 'moving_house', 'travel']),
  DayOfficer('危', 'Wei', 'Danger', 40, [], ['travel', 'renovation']),
  DayOfficer('成', 'Cheng', 'Success', 80, ['wedding', 'signing', 'moving_house', 'travel'], []),
  DayOfficer('收', 'Shou', 'Receive', 60, ['signing'], ['travel', 'haircut']),
  DayOfficer('开', 'Kai', 'Open', 75, ['moving_house', 'wedding', 'travel', 'signing'], []),
  DayOfficer('闭', 'Bi', 'Close', 35, [], ['moving_house', 'wedding', 'renovation']),
];

AlmanacDay computeAlmanac(DateTime date, {double utcOffsetHours = 8.0}) {
  final noonUtc = DateTime.utc(date.year, date.month, date.day, 12)
      .subtract(Duration(minutes: (utcOffsetHours * 60).round()));
  final monthBranch = branches[(solarMonthIndex(noonUtc) + 2) % 12];
  final dp = dayPillarForDate(date.year, date.month, date.day);
  final db = dp.branch.index;
  final officer = (db - monthBranch.index) % 12;
  final lucky = <Branch>[
    for (final b in branches)
      if (b.index == db || b.index == sixHarmonyPartner(db) || inThreeHarmony(b.index, db)) b,
  ];
  return AlmanacDay(
    date: DateTime.utc(date.year, date.month, date.day),
    dayPillar: dp,
    monthBranch: monthBranch,
    officerIndex: officer,
    clashBranch: branches[clashPartner(db)],
    luckyHourBranches: lucky,
    goodFor: dayOfficers[officer].goodFor,
    avoid: dayOfficers[officer].avoid,
  );
}

/// HEURISTIC daily score 0–100 (entertainment only).
int dailyScore(BaziChart user, DateTime day) {
  final a = computeAlmanac(day, utcOffsetHours: user.utcOffsetHours);
  var s = dayOfficers[a.officerIndex].baseScore;
  final db = a.dayPillar.branch.index;
  final ub = user.day.branch.index;
  final yb = user.year.branch.index;
  if (clashPartner(db) == ub) s -= 25;
  if (clashPartner(db) == yb) s -= 15;
  if (sixHarmonyPartner(db) == ub || sixHarmonyPartner(db) == yb) s += 10;
  if (inThreeHarmony(db, ub) || inThreeHarmony(db, yb)) s += 5;
  final el = a.dayPillar.stem.element;
  if (user.favourableElements.contains(el)) {
    s += 10;
  } else if (user.favourableElements.contains(el.produces)) {
    s += 3;
  } else {
    s -= 5;
  }
  return s.clamp(0, 100);
}
