import 'package:inkstone_engine/inkstone_engine.dart';
import 'package:test/test.dart';

void main() {
  int k(int y, int m, int d, Gender g, {int h = 12, int min = 0}) =>
      computeKua(DateTime(y, m, d, h, min), g).kua;

  group('PLAN.md example checks', () {
    test('female 12 Mar 1992 = 7 (sample profile Mei Lin)', () {
      expect(k(1992, 3, 12, Gender.female, h: 8, min: 15), 7);
    });
    test('male 1992 = 8', () => expect(k(1992, 6, 1, Gender.male), 8));
    test('male 2000 = 9', () => expect(k(2000, 6, 1, Gender.male), 9));
    test('female 2 Feb 1990 counts as solar year 1989', () {
      final r = computeKua(DateTime(1990, 2, 2, 12), Gender.female);
      expect(r.adjustedYear, 1989);
      // PLAN.md said 8 here, but 8 is the value for solar year 1990.
      // Solar year 1989, female: r = 1989 % 9 = 0, (0 + 4) % 9 = 4.
      expect(r.kua, 4);
      expect(k(1990, 2, 10, Gender.female), 8);
    });
  });

  test('formula matches digit-sum method across 25 birthdays (incl. <1950, >2030)', () {
    // Expected values from the classic digit-sum method used by common
    // online Kua calculators (independent implementation).
    const cases = <(int, Gender, int)>[
      (1938, Gender.male, 8),
      (1945, Gender.female, 8),
      (1949, Gender.male, 6),
      (1950, Gender.female, 1),
      (1963, Gender.male, 1),
      (1971, Gender.female, 4),
      (1976, Gender.male, 6),
      (1980, Gender.female, 4),
      (1985, Gender.male, 6),
      (1985, Gender.female, 9),
      (1988, Gender.male, 3),
      (1989, Gender.female, 4),
      (1990, Gender.female, 8),
      (1995, Gender.female, 1),
      (1999, Gender.male, 1),
      (2001, Gender.female, 7),
      (2004, Gender.male, 2),
      (2008, Gender.female, 8),
      (2015, Gender.male, 3),
      (2019, Gender.female, 7),
      (2023, Gender.male, 4),
      (2024, Gender.female, 3),
      (2031, Gender.male, 2),
      (2035, Gender.female, 8),
      (2041, Gender.male, 4),
    ];
    for (final (y, g, want) in cases) {
      expect(kuaForYear(y, g), want, reason: '$y ${g.name}');
      expect(k(y, 7, 15, g), want, reason: 'mid-year birth $y ${g.name}');
    }
  });

  test('Kua is never 5 and 0 becomes 9', () {
    for (var y = 1900; y < 2100; y++) {
      for (final g in Gender.values) {
        final v = kuaForYear(y, g);
        expect(v, inInclusiveRange(1, 9));
        expect(v, isNot(5));
      }
    }
    expect(kuaForYear(1995, Gender.male), 2); // would be 5
    expect(kuaForYear(1990, Gender.female), 8); // would be 5
    expect(kuaForYear(2009, Gender.male), 9); // would be 0
  });

  group('Li Chun boundary', () {
    test('before Li Chun uses previous year', () {
      final r = computeKua(DateTime(1992, 1, 20, 12), Gender.female);
      expect(r.adjustedYear, 1991);
      expect(r.kua, 6);
      expect(k(1992, 1, 20, Gender.male), 9);
    });
    test('3 Feb vs 5 Feb across several years', () {
      for (final y in [1949, 1975, 1990, 2010, 2026, 2033]) {
        expect(computeKua(DateTime(y, 2, 3, 0, 30), Gender.male).adjustedYear, y - 1, reason: '$y');
        expect(computeKua(DateTime(y, 2, 5, 23), Gender.male).adjustedYear, y, reason: '$y');
      }
    });
    test('Li Chun 2024 at ~16:27 SGT switches within the day', () {
      expect(computeKua(DateTime(2024, 2, 4, 16, 0), Gender.male).adjustedYear, 2023);
      expect(computeKua(DateTime(2024, 2, 4, 17, 0), Gender.male).adjustedYear, 2024);
      expect(k(2024, 2, 4, Gender.male, h: 16), 4);
      expect(k(2024, 2, 4, Gender.male, h: 17), 3);
    });
    test('January births belong to the previous year', () {
      expect(k(2000, 1, 15, Gender.male), kuaForYear(1999, Gender.male));
      expect(k(1950, 1, 1, Gender.female), kuaForYear(1949, Gender.female));
    });
  });

  test('directions and groups', () {
    final r = computeKua(DateTime(1992, 6, 1), Gender.male);
    expect(r.eastGroup, isFalse);
    expect(r.lucky.first.direction, Direction.sw);
    expect(r.unlucky.length, 4);
    final meiLin = kuaResultFor(7);
    expect(meiLin.lucky.map((d) => d.direction), [
      Direction.nw,
      Direction.sw,
      Direction.ne,
      Direction.w,
    ]);
    for (final kua in [1, 3, 4, 9]) {
      expect(kuaResultFor(kua).eastGroup, isTrue);
    }
    for (final kua in [2, 6, 7, 8]) {
      expect(kuaResultFor(kua).eastGroup, isFalse);
    }
    expect(() => kuaResultFor(5), throwsArgumentError);
  });

  test('every Kua has 8 distinct directions and good set matches its group', () {
    const east = {Direction.n, Direction.s, Direction.e, Direction.se};
    const west = {Direction.w, Direction.nw, Direction.sw, Direction.ne};
    for (final kua in [1, 2, 3, 4, 6, 7, 8, 9]) {
      final r = kuaResultFor(kua);
      expect(r.directions.map((d) => d.direction).toSet().length, 8);
      expect(r.lucky.map((d) => d.direction).toSet(), r.eastGroup ? east : west);
    }
  });

  test('example couple: Chua Boon Eng and Chou Jiahui Victoria', () {
    final boonEng = computeKua(DateTime(1990, 6, 26, 12), Gender.male);
    expect(boonEng.kua, 1);
    expect(boonEng.eastGroup, isTrue);
    expect(boonEng.lucky.map((d) => d.direction),
        [Direction.se, Direction.e, Direction.s, Direction.n]);
    final victoria = computeKua(DateTime(1991, 10, 28, 12), Gender.female);
    expect(victoria.kua, 6);
    expect(victoria.eastGroup, isFalse);
    expect(victoria.lucky.map((d) => d.direction),
        [Direction.w, Direction.ne, Direction.sw, Direction.nw]);
    // Birth time unknown: any hour that day gives the same answer.
    for (final h in [0, 23]) {
      expect(computeKua(DateTime(1990, 6, 26, h), Gender.male).kua, 1);
      expect(computeKua(DateTime(1991, 10, 28, h), Gender.female).kua, 6);
    }
    expect(sharedGoodDirections([boonEng, victoria]), isEmpty);
  });
}
