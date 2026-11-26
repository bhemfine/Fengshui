import 'dart:convert';
import 'dart:io';

import 'package:inkstone_engine/inkstone_engine.dart';
import 'package:test/test.dart';

void main() {
  final crystals = [
    for (final c in (jsonDecode(File('../content/crystals.json').readAsStringSync())['crystals'] as List))
      CrystalItem.fromJson(c as Map<String, Object?>)
  ];
  final rituals = [
    for (final r in (jsonDecode(File('../content/rituals.json').readAsStringSync())['rituals'] as List))
      RitualItem.fromJson(r as Map<String, Object?>)
  ];
  BaziChart chart(DateTime d) => computeBazi(birthLocal: d, utcOffsetHours: 8, hourKnown: false);

  final boonBirth = DateTime(1990, 6, 26, 12);
  final vicBirth = DateTime(1991, 10, 28, 12);
  LuckyProfile p(DateTime b, Gender g, int y) => luckyProfile(
      chart: chart(b), kua: computeKua(b, g), year: y, crystals: crystals, rituals: rituals);

  test('He Tu numbers and element colours cover all elements', () {
    expect(heTuNumbers[FiveElement.water], [1, 6]);
    expect(heTuNumbers[FiveElement.metal], [4, 9]);
    expect(heTuNumbers[FiveElement.earth], [5, 0]);
    for (final e in FiveElement.values) {
      expect(elementColours[e], isNotEmpty);
    }
  });

  group('Boon Eng (壬 Water Day Master, weak, time unknown)', () {
    test('2026: Metal/Water favourable, Fire/Earth unfavourable', () {
      final r = p(boonBirth, Gender.male, 2026);
      expect(r.favourable, [FiveElement.metal, FiveElement.water]);
      expect(r.unfavourable, [FiveElement.fire, FiveElement.earth]);
      expect(r.luckyNumbers, [4, 9, 1, 6]);
      expect(r.unluckyNumbers, [2, 7, 5, 0]);
      expect(r.luckyColours, containsAll(['white', 'gold', 'black', 'blue']));
      expect(r.unluckyColours, containsAll(['red', 'yellow']));
      // Kua 1: SE, E, S, N good. 2026: S = Tai Sui + Five Yellow, N = Year Breaker + Three Killings.
      expect(r.luckyDirections.map((d) => d.info.direction), [Direction.se, Direction.e, Direction.s, Direction.n]);
      expect(r.luckyDirections[0].caution, isNull);
      expect(r.luckyDirections[2].caution, contains('Tai Sui'));
      expect(r.luckyDirections[3].caution, contains('Three Killings'));
      expect(r.luckyCrystals, isNotEmpty);
      expect(r.luckyCrystals.every((c) => r.favourable.contains(c.element)), isTrue);
      expect(r.luckyRituals.first.id, 'lucky_red_thread'); // 本命年
      expect(r.avoids.join(' '), contains('本命年·自刑'));
      expect(r.avoids.first, contains('South (Tai Sui, Five Yellow) or North (Year Breaker, Three Killings)'));
      expect(r.yearElementNote, contains('Wealth'));
    });
    test('2027: no red-thread ritual, Tai Sui SW not in his good directions', () {
      final r = p(boonBirth, Gender.male, 2027);
      expect(r.luckyRituals.any((x) => x.id == 'lucky_red_thread'), isFalse);
      expect(r.luckyDirections.firstWhere((d) => d.info.direction == Direction.n).caution, contains('Five Yellow'));
      expect(r.unluckyDirections.join(' '), contains('South-west'));
    });
  });

  group('Victoria (辛 Metal Day Master, strong, time unknown)', () {
    test('2026: Water/Wood/Fire favourable, Earth/Metal unfavourable', () {
      final r = p(vicBirth, Gender.female, 2026);
      expect(r.favourable, [FiveElement.water, FiveElement.wood, FiveElement.fire]);
      expect(r.unfavourable, [FiveElement.earth, FiveElement.metal]);
      expect(r.luckyNumbers, [1, 6, 3, 8, 2, 7]);
      expect(r.unluckyNumbers, [5, 0, 4, 9]);
      // Kua 6: W, NE, SW, NW good; NW holds the 2026 Two Black.
      expect(r.luckyDirections.firstWhere((d) => d.info.direction == Direction.nw).caution, contains('Two Black'));
      expect(r.yearElementNote, contains('Power'));
    });
    test('2027: W holds Three Killings and Two Black, SW is Tai Sui', () {
      final r = p(vicBirth, Gender.female, 2027);
      final w = r.luckyDirections.firstWhere((d) => d.info.direction == Direction.w);
      expect(w.caution, allOf(contains('Three Killings'), contains('Two Black')));
      expect(r.luckyDirections.firstWhere((d) => d.info.direction == Direction.sw).caution, contains('Tai Sui'));
      // 2027 is her own Goat year (本命年).
      expect(r.luckyRituals.first.id, 'lucky_red_thread');
      expect(r.avoids.first, contains('South-west (Tai Sui)'));
    });
  });

  test('works without content lists (items empty, rest filled)', () {
    final r = luckyProfile(chart: chart(boonBirth), kua: computeKua(boonBirth, Gender.male), year: 2026);
    expect(r.luckyCrystals, isEmpty);
    expect(r.luckyColours, isNotEmpty);
  });
}
