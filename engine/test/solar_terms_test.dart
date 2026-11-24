import 'package:inkstone_engine/inkstone_engine.dart';
import 'package:test/test.dart';

void main() {
  const tol = Duration(minutes: 15);
  test('Li Chun 2024', () {
    final t = solarTermUtc(2024, 0);
    expect(t.difference(DateTime.utc(2024, 2, 4, 8, 27)).abs() <= tol, isTrue, reason: '$t');
  });
  test('Winter solstice 2025', () {
    final t = solarTermUtc(2025, 21);
    expect(t.difference(DateTime.utc(2025, 12, 21, 15, 3)).abs() <= tol, isTrue, reason: '$t');
  });
  test('terms increase monotonically', () {
    final list = solarTermsOfYear(2030);
    for (var i = 1; i < 24; i++) {
      expect(list[i].isAfter(list[i - 1]), isTrue);
    }
  });
  test('Li Chun year', () {
    expect(liChunYear(DateTime.utc(2026, 1, 20)), 2025);
    expect(liChunYear(DateTime.utc(2026, 3, 1)), 2026);
  });
}
