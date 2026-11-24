import 'package:inkstone_engine/inkstone_engine.dart';
import 'package:test/test.dart';

void main() {
  final user = computeBazi(birthLocal: DateTime(1992, 3, 12, 8, 15), utcOffsetHours: 8);
  test('determinism and bounds', () {
    for (var i = 0; i < 400; i++) {
      final d = DateTime(2026, 1, 1).add(Duration(days: i));
      final s = dailyScore(user, d);
      expect(s, inInclusiveRange(0, 100));
      expect(dailyScore(user, d), s);
    }
  });
  test('almanac fields', () {
    final a = computeAlmanac(DateTime(2000, 1, 1));
    expect(a.dayPillar.chinese, '戊午');
    expect(a.clashBranch.animal, 'Rat');
    expect(a.officerIndex, inInclusiveRange(0, 11));
    expect(a.luckyHourBranches.isNotEmpty, isTrue);
    expect(a.toJson()['date'], '2000-01-01');
  });
}
