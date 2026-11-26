import 'package:inkstone_engine/inkstone_engine.dart';
import 'package:test/test.dart';

void main() {
  test('day anchors', () {
    expect(dayPillarForDate(2000, 1, 1).chinese, '戊午');
    expect(dayPillarForDate(1949, 10, 1).chinese, '甲子');
  });
  test('year pillars across Li Chun', () {
    final a = computeBazi(birthLocal: DateTime(2026, 3, 1, 12), utcOffsetHours: 8);
    expect(a.year.chinese, '丙午');
    final b = computeBazi(birthLocal: DateTime(2026, 1, 20, 12), utcOffsetHours: 8);
    expect(b.year.chinese, '乙巳');
  });
  test('1992-03-12 08:15 +8', () {
    final c = computeBazi(birthLocal: DateTime(1992, 3, 12, 8, 15), utcOffsetHours: 8);
    expect(c.year.chinese, '壬申');
    expect(c.month.chinese, '癸卯');
    // TODO-verify: day 丁亥 Ding-Hai, hour 甲辰 Jia-Chen (computed, not cross-checked).
    expect(c.day.chinese, '丁亥');
    expect(c.hour?.chinese, '甲辰');
    expect(c.toJson()['dayMaster'], isNotNull);
  });
  test('23:00 boundary', () {
    final early = computeBazi(birthLocal: DateTime(2000, 1, 1, 23, 30), utcOffsetHours: 8);
    expect(early.day.chinese, '己未');
    expect(early.hour!.branch.chinese, '子');
    final late = computeBazi(
        birthLocal: DateTime(2000, 1, 1, 23, 30),
        utcOffsetHours: 8,
        zi: ZiConvention.dayChangesAtMidnight);
    expect(late.day.chinese, '戊午');
    expect(late.hour!.stem.chinese, early.hour!.stem.chinese);
  });
  test('hour unknown', () {
    final c = computeBazi(birthLocal: DateTime(1990, 5, 5), utcOffsetHours: 8, hourKnown: false);
    expect(c.hour, isNull);
    expect(c.elementCounts.values.fold<int>(0, (a, b) => a + b), 6);
  });

  test('luck pillars: male 26 Jun 1990 (yang Geng year) runs forward from Ren Wu', () {
    final birth = DateTime(1990, 6, 26, 12);
    final c = computeBazi(birthLocal: birth, utcOffsetHours: 8, hourKnown: false);
    expect(c.year.chinese, '庚午');
    expect(c.month.chinese, '壬午');
    expect(c.day.chinese, '壬戌');
    final l = luckPillarsFor(chart: c, birthUtc: DateTime.utc(1990, 6, 26, 4), gender: Gender.male, count: 3);
    expect(l.map((p) => p.pillar.chinese), ['癸未', '甲申', '乙酉']);
    expect(l.first.startAge, 4); // Xiao Shu ~7 Jul 1990: ~11 days / 3
  });
  test('luck pillars: female yang year runs backward', () {
    final c = computeBazi(birthLocal: DateTime(1990, 6, 26, 12), utcOffsetHours: 8, hourKnown: false);
    final l = luckPillarsFor(chart: c, birthUtc: DateTime.utc(1990, 6, 26, 4), gender: Gender.female, count: 2);
    expect(l.map((p) => p.pillar.chinese), ['辛巳', '庚辰']);
  });
}
