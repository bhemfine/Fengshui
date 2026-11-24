import 'package:inkstone_engine/inkstone_engine.dart';
import 'package:test/test.dart';

void main() {
  test('periods', () {
    expect(periodForYear(1984), 7);
    expect(periodForYear(2004), 8);
    expect(periodForYear(2023), 8);
    expect(periodForYear(2024), 9);
  });
  test('period 8 base chart', () {
    final b = flyStars(8);
    expect(b[Direction.centre], 8);
    expect(b[Direction.nw], 9);
    expect(b[Direction.se], 7);
  });
  test('annual 2026', () {
    expect(annualCentreStar(2026), 1);
    final a = annualChart(2026);
    expect(a[Direction.nw], 2);
    expect(a[Direction.se], 9);
  });
  test('mountains', () {
    expect(mountainAt(0).chinese, '子');
    expect(mountainAt(135).code, 'SE2');
  });
  test('Period 8 facing SE2 (TODO-verify)', () {
    final c = natalChart(135, 8);
    final se = c.palaces[Direction.se]!;
    expect([se.base, se.mountain, se.facing], [7, 1, 8]);
    final nw = c.palaces[Direction.nw]!;
    expect([nw.base, nw.mountain, nw.facing], [9, 8, 6]);
    expect(c.formations, contains('wang_shan_wang_shui'));
  });
}
