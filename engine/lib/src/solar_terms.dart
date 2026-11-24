import 'dart:math' as math;

/// The 24 solar terms (节气 Jie Qi). Index 0 = 立春 Li Chun (315°).
const List<(String, String, String)> solarTermNames = [
  ('立春', 'Li Chun', 'Start of Spring'),
  ('雨水', 'Yu Shui', 'Rain Water'),
  ('惊蛰', 'Jing Zhe', 'Awakening of Insects'),
  ('春分', 'Chun Fen', 'Spring Equinox'),
  ('清明', 'Qing Ming', 'Clear and Bright'),
  ('谷雨', 'Gu Yu', 'Grain Rain'),
  ('立夏', 'Li Xia', 'Start of Summer'),
  ('小满', 'Xiao Man', 'Grain Buds'),
  ('芒种', 'Mang Zhong', 'Grain in Ear'),
  ('夏至', 'Xia Zhi', 'Summer Solstice'),
  ('小暑', 'Xiao Shu', 'Minor Heat'),
  ('大暑', 'Da Shu', 'Major Heat'),
  ('立秋', 'Li Qiu', 'Start of Autumn'),
  ('处暑', 'Chu Shu', 'End of Heat'),
  ('白露', 'Bai Lu', 'White Dew'),
  ('秋分', 'Qiu Fen', 'Autumn Equinox'),
  ('寒露', 'Han Lu', 'Cold Dew'),
  ('霜降', 'Shuang Jiang', "Frost's Descent"),
  ('立冬', 'Li Dong', 'Start of Winter'),
  ('小雪', 'Xiao Xue', 'Minor Snow'),
  ('大雪', 'Da Xue', 'Major Snow'),
  ('冬至', 'Dong Zhi', 'Winter Solstice'),
  ('小寒', 'Xiao Han', 'Minor Cold'),
  ('大寒', 'Da Han', 'Major Cold'),
];

/// Approximate TT − UTC in seconds (constant; adequate 1950–2050).
const double deltaTSeconds = 69.0;

double julianDay(DateTime t) => t.toUtc().millisecondsSinceEpoch / 86400000.0 + 2440587.5;

double _rad(double d) => d * math.pi / 180.0;

/// Apparent geocentric ecliptic longitude of the Sun in degrees [0,360).
/// Meeus, Astronomical Algorithms ch. 25 (low accuracy, ~0.01°).
double sunApparentLongitude(DateTime utc) {
  final jde = julianDay(utc) + deltaTSeconds / 86400.0;
  final t = (jde - 2451545.0) / 36525.0;
  final l0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t;
  final m = 357.52911 + 35999.05029 * t - 0.0001537 * t * t;
  final mr = _rad(m);
  final c = (1.914602 - 0.004817 * t - 0.000014 * t * t) * math.sin(mr) +
      (0.019993 - 0.000101 * t) * math.sin(2 * mr) +
      0.000289 * math.sin(3 * mr);
  final trueLon = l0 + c;
  final omega = 125.04 - 1934.136 * t;
  final apparent = trueLon - 0.00569 - 0.00478 * math.sin(_rad(omega));
  return apparent % 360.0;
}

double _wrap180(double d) {
  final x = d % 360.0;
  return x > 180.0 ? x - 360.0 : x;
}

/// UTC instant of solar term [index] (0 = Li Chun of [year]). Indices 22, 23 fall in January of year+1.
DateTime solarTermUtc(int year, int index) {
  RangeError.checkValueInInterval(index, 0, 23, 'index');
  final target = (315.0 + 15.0 * index) % 360.0;
  final guess = DateTime.utc(year, 2, 4).millisecondsSinceEpoch + (index * 15.2184 * 86400000).round();
  var lo = guess - 6 * 86400000;
  var hi = guess + 6 * 86400000;
  double f(int ms) =>
      _wrap180(sunApparentLongitude(DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true)) - target);
  for (var i = 0; i < 60 && hi - lo > 1000; i++) {
    final mid = lo + (hi - lo) ~/ 2;
    if (f(mid) < 0) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return DateTime.fromMillisecondsSinceEpoch(lo + (hi - lo) ~/ 2, isUtc: true);
}

List<DateTime> solarTermsOfYear(int year) => [for (var i = 0; i < 24; i++) solarTermUtc(year, i)];

/// Solar month index 0..11 (0 = 寅 Yin month starting at Li Chun), bounded by the 12 jie 节 terms.
int solarMonthIndex(DateTime utc) => (((sunApparentLongitude(utc) - 315.0) % 360.0) ~/ 30).toInt();

/// Year number used for pillars/Kua: switches at Li Chun (立春, 315°).
int liChunYear(DateTime utc) {
  final u = utc.toUtc();
  final lon = sunApparentLongitude(u);
  if (u.month <= 3 && lon >= 270.0 && lon < 315.0) return u.year - 1;
  return u.year;
}
