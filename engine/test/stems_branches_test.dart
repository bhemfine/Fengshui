import 'package:inkstone_engine/inkstone_engine.dart';
import 'package:test/test.dart';

void main() {
  test('counts and elements', () {
    expect(stems.length, 10);
    expect(branches.length, 12);
    expect(stems[4].element, FiveElement.earth);
    expect(branches[6].animal, 'Horse');
  });
  test('sexagenary index', () {
    expect(sexagenaryIndex(0, 0), 0);
    expect(sexagenaryIndex(4, 6), 54);
    expect(sexagenaryIndex(9, 11), 59);
    expect(sexagenaryIndex(0, 1), -1);
    for (var n = 0; n < 60; n++) {
      expect(Pillar.fromCycleIndex(n).cycleIndex, n);
    }
  });
  test('element relations', () {
    expect(FiveElement.wood.produces, FiveElement.fire);
    expect(FiveElement.metal.controls, FiveElement.wood);
    expect(FiveElement.water.controls, FiveElement.fire);
    expect(FiveElement.fire.producedBy, FiveElement.wood);
  });
  test('harmonies', () {
    expect(sixHarmonyPartner(0), 1);
    expect(sixHarmonyPartner(6), 7);
    expect(clashPartner(0), 6);
    expect(inThreeHarmony(8, 0), isTrue);
  });
}
