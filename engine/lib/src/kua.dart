import 'models.dart';
import 'solar_terms.dart';

/// Kua number (命卦 Ming Gua) for a Li Chun-adjusted (solar) year.
///
/// PLAN.md Module 3: r = year mod 9; male k = (11 - r) mod 9, female
/// k = (r + 4) mod 9; 0 becomes 9; 5 becomes 2 (male) or 8 (female).
/// Equivalent to the classic digit-sum method for every century.
int kuaForYear(int year, Gender gender) {
  final r = year % 9; // Dart % is non-negative for a positive divisor.
  var k = gender == Gender.male ? (11 - r) % 9 : (r + 4) % 9;
  if (k == 0) k = 9;
  if (k == 5) k = gender == Gender.male ? 2 : 8;
  return k;
}

/// East group Kua numbers (东四命). West group is 2, 6, 7, 8.
const Set<int> eastGroupKua = {1, 3, 4, 9};

const _lucky = [
  ('sheng_qi', '生气', 'Sheng Qi', 'Life Generating (success)'),
  ('tian_yi', '天医', 'Tian Yi', 'Heavenly Doctor (health)'),
  ('yan_nian', '延年', 'Yan Nian', 'Longevity (relationships)'),
  ('fu_wei', '伏位', 'Fu Wei', 'Stability (personal growth)'),
];
const _unlucky = [
  ('huo_hai', '祸害', 'Huo Hai', 'Mishaps'),
  ('wu_gui', '五鬼', 'Wu Gui', 'Five Ghosts'),
  ('liu_sha', '六煞', 'Liu Sha', 'Six Killings'),
  ('jue_ming', '绝命', 'Jue Ming', 'Total Loss'),
];

const _d = Direction.values;
// Order: SQ, TY, YN, FW, HH, WG, LS, JM.
final Map<int, List<Direction>> _table = {
  1: [_d[3], _d[2], _d[4], _d[0], _d[6], _d[1], _d[7], _d[5]],
  2: [_d[1], _d[6], _d[7], _d[5], _d[2], _d[3], _d[4], _d[0]],
  3: [_d[4], _d[0], _d[3], _d[2], _d[5], _d[7], _d[1], _d[6]],
  4: [_d[0], _d[4], _d[2], _d[3], _d[7], _d[5], _d[6], _d[1]],
  6: [_d[6], _d[1], _d[5], _d[7], _d[3], _d[2], _d[0], _d[4]],
  7: [_d[7], _d[5], _d[1], _d[6], _d[0], _d[4], _d[3], _d[2]],
  8: [_d[5], _d[7], _d[6], _d[1], _d[4], _d[0], _d[2], _d[3]],
  9: [_d[2], _d[3], _d[0], _d[4], _d[1], _d[6], _d[5], _d[7]],
};

/// Builds the 4 good and 4 bad directions for a Kua number.
KuaResult kuaResultFor(int kua, {int adjustedYear = 0}) {
  final dirs = _table[kua];
  if (dirs == null) throw ArgumentError.value(kua, 'kua', 'must be 1-4 or 6-9');
  final list = <DirectionInfo>[
    for (var i = 0; i < 4; i++)
      DirectionInfo(_lucky[i].$1, _lucky[i].$2, _lucky[i].$3, _lucky[i].$4, dirs[i], true),
    for (var i = 0; i < 4; i++)
      DirectionInfo(
        _unlucky[i].$1,
        _unlucky[i].$2,
        _unlucky[i].$3,
        _unlucky[i].$4,
        dirs[4 + i],
        false,
      ),
  ];
  return KuaResult(
    kua: kua,
    adjustedYear: adjustedYear,
    eastGroup: eastGroupKua.contains(kua),
    directions: list,
  );
}

/// Solar (Li Chun-adjusted) year for a wall-clock birth time at [utcOffsetHours].
int solarYearForBirth(DateTime birthLocal, {double utcOffsetHours = 8.0}) {
  final wall = DateTime.utc(
    birthLocal.year,
    birthLocal.month,
    birthLocal.day,
    birthLocal.hour,
    birthLocal.minute,
  );
  final utc = wall.subtract(Duration(minutes: (utcOffsetHours * 60).round()));
  return liChunYear(utc);
}

/// Computes Kua from wall-clock birth time; year switches at Li Chun (立春).
///
/// If the birth time is unknown, pass noon; only births on Li Chun day itself
/// can be affected, and the UI should say so.
KuaResult computeKua(DateTime birthLocal, Gender gender, {double utcOffsetHours = 8.0}) {
  final y = solarYearForBirth(birthLocal, utcOffsetHours: utcOffsetHours);
  return kuaResultFor(kuaForYear(y, gender), adjustedYear: y);
}
