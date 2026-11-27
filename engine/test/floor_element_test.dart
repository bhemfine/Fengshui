import 'package:inkstone_engine/inkstone_engine.dart';
import 'package:test/test.dart';

void main() {
  group('floor element (He Tu last digit)', () {
    test('maps last digits to the popular elements', () {
      expect(floorElementForDigit(1), FiveElement.water);
      expect(floorElementForDigit(6), FiveElement.water);
      expect(floorElementForDigit(11), FiveElement.water);
      expect(floorElementForDigit(2), FiveElement.fire);
      expect(floorElementForDigit(7), FiveElement.fire);
      expect(floorElementForDigit(3), FiveElement.wood);
      expect(floorElementForDigit(18), FiveElement.wood);
      expect(floorElementForDigit(4), FiveElement.metal);
      expect(floorElementForDigit(9), FiveElement.metal);
      expect(floorElementForDigit(5), FiveElement.earth);
      expect(floorElementForDigit(10), FiveElement.earth);
      expect(floorElementForDigit(20), FiveElement.earth);
    });

    test('parses floor strings', () {
      expect(parseFloorNumber('12'), 12);
      expect(parseFloorNumber('12th'), 12);
      expect(parseFloorNumber('level 7'), 7);
      expect(parseFloorNumber('#10-234'), 10);
      expect(parseFloorNumber(''), null);
      expect(parseFloorNumber(null), null);
      expect(parseFloorNumber('ground'), null);
    });

    test('favourable and unfavourable copy', () {
      final good = floorElementNote(
        floorNumber: 16,
        favourable: [FiveElement.water],
        unfavourable: [FiveElement.fire],
      );
      expect(good.element, FiveElement.water);
      expect(good.lastDigit, 6);
      expect(good.fit, FloorElementFit.favourable);
      expect(good.body, contains('Water'));
      expect(FloorElementNote.disclaimer, contains('not classical Flying Stars'));

      final bad = floorElementNote(
        floorRaw: '27',
        favourable: [FiveElement.water],
        unfavourable: [FiveElement.fire],
      );
      expect(bad.element, FiveElement.fire);
      expect(bad.fit, FloorElementFit.unfavourable);
    });

    test('couple mixed fit', () {
      final n = floorElementNote(
        floorNumber: 3,
        favourable: [FiveElement.wood],
        unfavourable: [FiveElement.metal],
        partnerFavourable: [FiveElement.fire],
      );
      expect(n.element, FiveElement.wood);
      expect(n.fit, FloorElementFit.mixed);
      expect(n.body, contains('main person'));
    });

    test('missing floor', () {
      final n = floorElementNote(favourable: [FiveElement.water]);
      expect(n.fit, FloorElementFit.unknown);
      expect(n.element, isNull);
    });
  });

  group('plan grid (facing at the bottom)', () {
    test('snaps bearings to eight palaces', () {
      expect(nearestPalace(0), Direction.n);
      expect(nearestPalace(22), Direction.n);
      expect(nearestPalace(23), Direction.ne);
      expect(nearestPalace(142), Direction.se);
      expect(nearestPalace(180), Direction.s);
      expect(nearestPalace(359), Direction.n);
    });

    test('facing south puts south at the bottom and west on the right', () {
      expect(palaceCell(Direction.s, Direction.s), (row: 2, col: 1));
      expect(palaceCell(Direction.n, Direction.s), (row: 0, col: 1));
      expect(palaceCell(Direction.w, Direction.s), (row: 1, col: 2));
      expect(palaceCell(Direction.e, Direction.s), (row: 1, col: 0));
      expect(palaceCell(Direction.sw, Direction.s), (row: 2, col: 2));
      expect(palaceCell(Direction.centre, Direction.s), (row: 1, col: 1));
    });

    test('facing east puts east at the bottom and south on the right', () {
      expect(palaceCell(Direction.e, Direction.e), (row: 2, col: 1));
      expect(palaceCell(Direction.w, Direction.e), (row: 0, col: 1));
      expect(palaceCell(Direction.s, Direction.e), (row: 1, col: 2));
      expect(palaceCell(Direction.n, Direction.e), (row: 1, col: 0));
    });

    test('every facing fills the nine cells uniquely', () {
      for (final facing in Direction.values) {
        if (facing == Direction.centre) continue;
        final cells = <(int, int)>{};
        for (final d in Direction.values) {
          cells.add((palaceCell(d, facing).row, palaceCell(d, facing).col));
        }
        expect(cells.length, 9, reason: 'facing $facing');
        expect(palacesInGridOrder(facing)[7], facing); // bottom centre index 7
      }
    });
  });
}
