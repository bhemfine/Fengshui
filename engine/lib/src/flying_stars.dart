import 'models.dart';
import 'solar_terms.dart';

/// One of the 24 mountains (二十四山 Er Shi Si Shan), 15° each.
class Mountain {
  const Mountain(this.index, this.chinese, this.pinyin, this.english);
  final int index;
  final String chinese;
  final String pinyin;
  final String english;

  Direction get palace => _palaceOrder[index ~/ 3];

  /// 0 = Earth (地元 Di Yuan), 1 = Heaven (天元 Tian Yuan), 2 = Man (人元 Ren Yuan).
  int get sub => index % 3;
  double get centreDegree => (index * 15.0) % 360.0;
  String get code => '${palace.name.toUpperCase()}${sub + 1}';
}

const _palaceOrder = [
  Direction.n, Direction.ne, Direction.e, Direction.se,
  Direction.s, Direction.sw, Direction.w, Direction.nw,
];

const List<Mountain> mountains = [
  Mountain(0, '壬', 'Ren', 'Yang Water'),
  Mountain(1, '子', 'Zi', 'Rat'),
  Mountain(2, '癸', 'Gui', 'Yin Water'),
  Mountain(3, '丑', 'Chou', 'Ox'),
  Mountain(4, '艮', 'Gen', 'Mountain trigram'),
  Mountain(5, '寅', 'Yin', 'Tiger'),
  Mountain(6, '甲', 'Jia', 'Yang Wood'),
  Mountain(7, '卯', 'Mao', 'Rabbit'),
  Mountain(8, '乙', 'Yi', 'Yin Wood'),
  Mountain(9, '辰', 'Chen', 'Dragon'),
  Mountain(10, '巽', 'Xun', 'Wind trigram'),
  Mountain(11, '巳', 'Si', 'Snake'),
  Mountain(12, '丙', 'Bing', 'Yang Fire'),
  Mountain(13, '午', 'Wu', 'Horse'),
  Mountain(14, '丁', 'Ding', 'Yin Fire'),
  Mountain(15, '未', 'Wei', 'Goat'),
  Mountain(16, '坤', 'Kun', 'Earth trigram'),
  Mountain(17, '申', 'Shen', 'Monkey'),
  Mountain(18, '庚', 'Geng', 'Yang Metal'),
  Mountain(19, '酉', 'You', 'Rooster'),
  Mountain(20, '辛', 'Xin', 'Yin Metal'),
  Mountain(21, '戌', 'Xu', 'Dog'),
  Mountain(22, '乾', 'Qian', 'Heaven trigram'),
  Mountain(23, '亥', 'Hai', 'Pig'),
];

/// Mountain containing compass [degree] (0 = N). 壬 Ren spans 337.5–352.5.
Mountain mountainAt(double degree) => mountains[(((degree - 337.5) % 360.0) ~/ 15).toInt() % 24];

/// Lo Shu flight path (飞星路线): centre → NW → W → NE → S → N → SW → E → SE.
const List<Direction> loShuPath = [
  Direction.centre, Direction.nw, Direction.w, Direction.ne, Direction.s,
  Direction.n, Direction.sw, Direction.e, Direction.se,
];

int _wrap9(int x) => (x - 1) % 9 + 1;

/// Flies [centre] along the Lo Shu path, forward (顺飞 Shun Fei) or backward (逆飞 Ni Fei).
Map<Direction, int> flyStars(int centre, {bool forward = true}) => {
      for (var k = 0; k < 9; k++) loShuPath[k]: _wrap9(forward ? centre + k : centre - k),
    };

/// Period (元运 Yuan Yun) for a Li Chun year. Period 7: 1984–2003, 8: 2004–2023, 9: 2024–2043.
/// Boundary is Li Chun of the first year; pass a Li Chun-adjusted year.
int periodForYear(int liChunYear) => ((liChunYear - 1864) ~/ 20) % 9 + 1;

int periodForDate(DateTime utc) => periodForYear(liChunYear(utc));

/// Polarity pattern per star number for (Earth, Heaven, Man) sub-mountains. true = yang.
bool _isYang(int star, int sub) {
  const cardinal = {1, 3, 7, 9}; // + - -
  if (cardinal.contains(star)) return sub == 0;
  return sub != 0; // 2,4,6,8: - + +
}

/// Natal chart (下卦 Xia Gua, standard chart; Ti Gua replacement charts TODO).
/// When a star is 5 it adopts the trigram of the period number.
FlyingStarChart natalChart(double facingDegree, int period) {
  final facing = mountainAt(facingDegree);
  final sitting = mountains[(facing.index + 12) % 24];
  final base = flyStars(period);
  final fStar = base[facing.palace]!;
  final mStar = base[sitting.palace]!;
  final fChart = flyStars(fStar, forward: _isYang(fStar == 5 ? period : fStar, facing.sub));
  final mChart = flyStars(mStar, forward: _isYang(mStar == 5 ? period : mStar, sitting.sub));
  final palaces = {
    for (final d in Direction.values) d: PalaceStars(base[d]!, mChart[d]!, fChart[d]!),
  };

  final formations = <String>[];
  final fp = palaces[facing.palace]!;
  final sp = palaces[sitting.palace]!;
  if (fp.facing == period && sp.mountain == period) formations.add('wang_shan_wang_shui');
  if (fp.mountain == period && sp.facing == period) formations.add('shang_shan_xia_shui');
  if (fp.facing == period && fp.mountain == period) formations.add('double_facing');
  if (sp.facing == period && sp.mountain == period) formations.add('double_sitting');
  if (palaces.values.every((p) => p.base + p.mountain == 10)) formations.add('sum_of_ten_mountain');
  if (palaces.values.every((p) => p.base + p.facing == 10)) formations.add('sum_of_ten_facing');

  return FlyingStarChart(
    period: period,
    facingDegree: facingDegree,
    facingMountain: facing.index,
    sittingMountain: sitting.index,
    palaces: palaces,
    formations: formations,
  );
}

/// Annual centre star for a Li Chun year (2024 = 3, 2025 = 2, 2026 = 1).
int annualCentreStar(int liChunYear) => _wrap9(3 - (liChunYear - 2024));

Map<Direction, int> annualChart(int liChunYear) => flyStars(annualCentreStar(liChunYear));

/// Monthly centre star; [monthIndex] 0 = 寅 Yin month (from Li Chun).
int monthlyCentreStar(int liChunYear, int monthIndex) {
  final yb = (liChunYear - 4) % 12;
  final int start;
  if (yb % 3 == 0) {
    start = 8; // 子午卯酉 Zi/Wu/Mao/You years
  } else if (yb % 3 == 1) {
    start = 5; // 丑辰未戌 Chou/Chen/Wei/Xu years
  } else {
    start = 2; // 寅巳申亥 Yin/Si/Shen/Hai years
  }
  return _wrap9(start - monthIndex);
}

Map<Direction, int> monthlyChart(int liChunYear, int monthIndex) =>
    flyStars(monthlyCentreStar(liChunYear, monthIndex));
