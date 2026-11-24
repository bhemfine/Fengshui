import 'package:inkstone_engine/inkstone_engine.dart';
import 'package:test/test.dart';

void main() {
  int k(int y, int m, int d, Gender g) => computeKua(DateTime(y, m, d, 12), g).kua;
  test('known values', () {
    expect(k(1992, 6, 1, Gender.male), 8);
    expect(k(1992, 6, 1, Gender.female), 7);
    expect(k(2001, 6, 1, Gender.male), 8);
    expect(k(2001, 6, 1, Gender.female), 7);
  });
  test('before Li Chun uses previous year', () {
    final r = computeKua(DateTime(1992, 1, 20, 12), Gender.female);
    expect(r.adjustedYear, 1991);
    expect(r.kua, 6);
    expect(k(1992, 1, 20, Gender.male), 9);
  });
  test('kua 5 replacement and zero', () {
    expect(kuaForYear(1990, Gender.female), 8);
    expect(kuaForYear(1995, Gender.male), 2);
    expect(kuaForYear(2009, Gender.male), 9);
  });
  test('directions', () {
    final r = computeKua(DateTime(1992, 6, 1), Gender.male);
    expect(r.eastGroup, isFalse);
    expect(r.lucky.first.direction, Direction.sw);
    expect(r.unlucky.length, 4);
  });
}
