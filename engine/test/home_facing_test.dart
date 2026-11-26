import 'dart:io';
import 'dart:math' as math;

import 'package:inkstone_engine/inkstone_engine.dart';
import 'package:test/test.dart';

void main() {
  group('degrees to direction', () {
    test('8 directions with boundaries at 22.5° steps', () {
      expect(directionAt(0), Direction.n);
      expect(directionAt(337.5), Direction.n);
      expect(directionAt(22.4), Direction.n);
      expect(directionAt(22.5), Direction.ne);
      expect(directionAt(90), Direction.e);
      expect(directionAt(142), Direction.se);
      expect(directionAt(180), Direction.s);
      expect(directionAt(225), Direction.sw);
      expect(directionAt(270), Direction.w);
      expect(directionAt(315), Direction.nw);
      expect(directionAt(337.4), Direction.nw);
      expect(directionAt(-10), Direction.n);
      expect(directionAt(725), Direction.n);
    });
    test('24 mountains', () {
      expect(facingFromDegrees(0).mountain.pinyin, 'Zi');
      expect(facingFromDegrees(345).mountain.pinyin, 'Ren');
      expect(facingFromDegrees(15).mountain.pinyin, 'Gui');
      expect(facingFromDegrees(142).mountain.pinyin, 'Xun');
      expect(facingFromDegrees(120).mountain.pinyin, 'Chen');
      expect(facingFromDegrees(142).isLineFacing, isTrue); // 0.5° from Xun|Si
      expect(facingFromDegrees(180).mountain.pinyin, 'Wu');
      expect(facingFromDegrees(315).mountain.pinyin, 'Qian');
      // Each mountain sits inside its direction (3 mountains per direction, Ren first).
      for (var d = 0.0; d < 360; d += 0.5) {
        final f = facingFromDegrees(d);
        expect(compassDirections[f.mountain.index ~/ 3], f.direction, reason: '$d');
      }
    });
    test('line facing within 3° of a boundary', () {
      expect(facingFromDegrees(0).isLineFacing, isFalse);
      expect(facingFromDegrees(7.5).isLineFacing, isTrue);
      expect(facingFromDegrees(10.4).isLineFacing, isTrue);
      expect(facingFromDegrees(10.6).isLineFacing, isFalse);
      expect(facingFromDegrees(20).isDirectionLine, isTrue);
      expect(facingFromDegrees(20).isLineFacing, isTrue);
      expect(facingFromDegrees(10).isDirectionLine, isFalse);
      expect(facingFromDegrees(336).isDirectionLine, isTrue);
      for (final d in compassDirections) {
        expect(facingFromDirection(d).isLineFacing, isFalse);
      }
    });
  });

  group('period from completion year', () {
    test('Period 8 and 9', () {
      expect(periodForCompletion(2004, month: 3).period, 8);
      expect(periodForCompletion(2012).period, 8);
      expect(periodForCompletion(2023).period, 8);
      expect(periodForCompletion(2024, month: 1, day: 20).period, 8);
      expect(periodForCompletion(2024, month: 2, day: 3).period, 8);
      expect(periodForCompletion(2024, month: 2, day: 5).period, 9);
      expect(periodForCompletion(2030).period, 9);
      expect(periodForCompletion(2043).period, 9);
      expect(periodForCompletion(2044, month: 6).period, 1);
      expect(periodForCompletion(2003).period, 7);
    });
    test('year-only boundary years are flagged', () {
      expect(periodForCompletion(2024).ambiguous, isTrue);
      expect(periodForCompletion(2004).ambiguous, isTrue);
      expect(periodForCompletion(2012).ambiguous, isFalse);
      expect(periodForCompletion(2024, month: 3).ambiguous, isFalse);
    });
  });

  group('couple match', () {
    final mei = kuaResultFor(7); // good NW SW NE W
    final wei = kuaResultFor(2); // good NE W NW SW
    final east = kuaResultFor(1); // good SE E S N
    test('good for both', () {
      final m = matchFacing(Direction.nw, [('A', mei), ('B', wei)]);
      expect(m.fit, FacingFit.goodForAll);
      expect(m.people.first.info.key, 'sheng_qi');
    });
    test('good for one', () {
      final m = matchFacing(Direction.se, [('A', east), ('B', wei)]);
      expect(m.fit, FacingFit.goodForSome);
      expect(m.verdict, contains('A'));
    });
    test('good for neither', () {
      final m = matchFacing(Direction.se, [('A', mei), ('B', wei)]);
      expect(m.fit, FacingFit.goodForNone);
    });
    test('single person', () {
      expect(matchFacing(Direction.n, [('A', east)]).fit, FacingFit.goodForAll);
      expect(sharedGoodDirections([mei, wei]).toSet(), {
        Direction.nw,
        Direction.sw,
        Direction.ne,
        Direction.w,
      });
      expect(sharedGoodDirections([mei, east]), isEmpty);
    });
  });

  group('compass maths', () {
    double rad(double d) => d * math.pi / 180;
    // Field ~41 µT, nearly horizontal in Singapore (small downward part).
    // Phone flat, top pointing [headingDeg]: north lies at (-sin h, cos h) in
    // device x/y, with a small downward (-z) part.
    (double, double, double) fieldFor(double headingDeg) =>
        (-40 * math.sin(rad(headingDeg)), 40 * math.cos(rad(headingDeg)), -8);
    double diff(double a, double b) => ((a - b + 540) % 360 - 180).abs();

    test('flat phone heading', () {
      for (final h in const <double>[0, 45, 90, 142, 180, 270, 359]) {
        final (mx, my, mz) = fieldFor(h);
        expect(diff(compassHeading(0, 0, 9.81, mx, my, mz)!, h), closeTo(0, 0.01), reason: '$h');
      }
    });
    test('tilt-compensated', () {
      // Tilt top edge up by 20°: gravity gains a +y component.
      final t = rad(20);
      final h = compassHeading(
        0,
        9.81 * math.sin(t),
        9.81 * math.cos(t),
        0,
        40 * math.cos(t),
        40 * -math.sin(t),
      );
      expect(diff(h!, 0), closeTo(0, 0.5));
      expect(tiltDegrees(0, 9.81 * math.sin(t), 9.81 * math.cos(t)), closeTo(20, 0.01));
      expect(tiltDegrees(0, 0, 9.81), closeTo(0, 0.01));
    });
    test('interference and averaging', () {
      expect(isInterference(41), isFalse);
      expect(isInterference(90), isTrue);
      expect(isInterference(12), isTrue);
      expect(fieldStrength(3, 4, 0), 5);
      expect(diff(circularMeanDegrees([359, 1, 0]), 0), closeTo(0, 1e-9));
      expect(circularMeanDegrees([140, 142, 144]), closeTo(142, 1e-9));
      expect(maxDeviationDegrees([358, 2]), closeTo(2, 1e-9));
      expect(magneticToTrue(359.95), closeTo(0.05, 1e-9));
      expect(compassHeading(0, 0, 0, 1, 1, 1), isNull);
    });
  });

  group('home checklist content', () {
    final file = File('../content/home_checklist.json');
    final list = HomeChecklist.fromJsonString(file.readAsStringSync());

    test('bundled app copy matches content/', () {
      final app = File('../flutter_app/assets/content/home_checklist.json');
      expect(app.readAsStringSync(), file.readAsStringSync());
    });
    test('covers all sections and types', () {
      final sections = list.items.map((i) => i.section).toSet();
      expect(sections, {'all', 'hdb', 'condo', 'landed', 'buying', 'reno'});
      expect(list.sections.map((s) => s.id).toSet(), sections);
      for (final t in PropertyType.values) {
        expect(list.itemsFor(t).length, greaterThan(40));
      }
      expect(list.items.map((i) => i.id).toSet().length, list.items.length);
      expect(
        list.items.map((i) => i.school).toSet(),
        containsAll([RuleSchool.classical, RuleSchool.blackHat, RuleSchool.popular]),
      );
      expect(list.itemsFor(PropertyType.hdb).any((i) => i.section == 'landed'), isFalse);
      expect(list.itemsFor(PropertyType.landed).any((i) => i.section == 'hdb'), isFalse);
    });
    test('2026 reno note: avoid hacking south and north', () {
      final reno = list
          .itemsFor(PropertyType.hdb, year: 2026)
          .where((i) => i.year == 2026)
          .toList();
      expect(reno.map((i) => i.id), containsAll(['reno_2026_south', 'reno_2026_north']));
      expect(list.notes['reno_2026'], allOf(contains('south'), contains('north')));
      expect(list.itemsFor(PropertyType.hdb, year: 2027).any((i) => i.year == 2026), isFalse);
    });
    test('HDB cures never move the shelter or change structure', () {
      final bad = RegExp(
        r'(move|relocat|shift|hack|remov|demolish|enlarg)\w*\s+(the\s+)?(household\s+)?shelter',
        caseSensitive: false,
      );
      final structural = RegExp(
        r'\b(hack (the|a) wall|knock down|extend the|move the (main )?door)\b',
        caseSensitive: false,
      );
      for (final i in list.itemsFor(PropertyType.hdb)) {
        final c = i.cureFor(PropertyType.hdb);
        expect(bad.hasMatch(c), isFalse, reason: i.id);
        expect(structural.hasMatch(c), isFalse, reason: i.id);
      }
    });
    test('evaluate flags issues with cures for the property type', () {
      final f = evaluateChecklist(list, PropertyType.hdb, {
        'toilet_centre': Answer.yes,
        'shape_regular': Answer.no,
        'bright_hall': Answer.yes,
        'centre_heavy': Answer.unsure,
        'landed_garage': Answer.yes, // not HDB, ignored
      });
      expect(f.map((x) => x.item.id), ['shape_regular', 'toilet_centre', 'centre_heavy']);
      expect(f.last.confirmed, isFalse);
      expect(f.first.cure, contains('No hacking'));
      final c = evaluateChecklist(list, PropertyType.condo, {'shape_regular': Answer.no});
      expect(c.single.cure, isNot(contains('No hacking')));
    });
  });
}
