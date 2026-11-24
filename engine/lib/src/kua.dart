import 'models.dart';
import 'solar_terms.dart';

int _digitRoot(int n) {
  var x = n.abs();
  while (x > 9) {
    var s = 0;
    while (x > 0) {
      s += x % 10;
      x ~/= 10;
    }
    x = s;
  }
  return x;
}

/// Kua number (命卦 Ming Gua) for a Li Chun-adjusted year.
int kuaForYear(int year, Gender gender) {
  final r = _digitRoot(year % 100);
  int k;
  if (year < 2000) {
    k = gender == Gender.male ? 10 - r : 5 + r;
  } else {
    k = gender == Gender.male ? 9 - r : 6 + r;
  }
  k = _digitRoot(k);
  if (k == 0) k = 9;
  if (k == 5) k = gender == Gender.male ? 2 : 8;
  return k;
}

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

/// Computes Kua from wall-clock birth time; year switches at Li Chun (立春).
KuaResult computeKua(DateTime birthLocal, Gender gender, {double utcOffsetHours = 8.0}) {
  final wall = DateTime.utc(
      birthLocal.year, birthLocal.month, birthLocal.day, birthLocal.hour, birthLocal.minute);
  final utc = wall.subtract(Duration(minutes: (utcOffsetHours * 60).round()));
  final y = liChunYear(utc);
  final k = kuaForYear(y, gender);
  final dirs = _table[k]!;
  final list = <DirectionInfo>[
    for (var i = 0; i < 4; i++)
      DirectionInfo(_lucky[i].$1, _lucky[i].$2, _lucky[i].$3, _lucky[i].$4, dirs[i], true),
    for (var i = 0; i < 4; i++)
      DirectionInfo(
          _unlucky[i].$1, _unlucky[i].$2, _unlucky[i].$3, _unlucky[i].$4, dirs[4 + i], false),
  ];
  return KuaResult(kua: k, adjustedYear: y, eastGroup: const {1, 3, 4, 9}.contains(k), directions: list);
}
