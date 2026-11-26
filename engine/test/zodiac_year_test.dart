import 'package:inkstone_engine/inkstone_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Na Yin', () {
    test('60 pairs, spot checks', () {
      expect(naYinTable.length, 30);
      String ny(String gz) {
        for (var i = 0; i < 60; i++) {
          final p = Pillar.fromCycleIndex(i);
          if (p.chinese == gz) return naYinFor(p).chinese;
        }
        throw gz;
      }

      expect(ny('甲子'), '海中金');
      expect(ny('庚午'), '路旁土');
      expect(ny('辛未'), '路旁土');
      expect(ny('丙午'), '天河水');
      expect(ny('丁未'), '天河水');
      expect(ny('壬戌'), '大海水'); // Boon Eng's day pillar (almanac: 大海水)
      expect(ny('壬午'), '杨柳木'); // Boon Eng's month pillar (almanac: 杨柳木)
      expect(ny('戊戌'), '平地木'); // Victoria's month pillar (almanac: 平地木)
      expect(ny('癸亥'), '大海水');
    });
  });

  group('Zodiac year', () {
    test('Boon Eng 26 Jun 1990: 庚午 Metal Horse, Fire, 路旁土', () {
      final z = zodiacForBirth(DateTime(1990, 6, 26, 12));
      expect(z.pillar.chinese, '庚午');
      expect(z.name, 'Metal Horse');
      expect(z.yearElement, FiveElement.metal);
      expect(z.animalElement, FiveElement.fire);
      expect(z.naYin.chinese, '路旁土');
      expect(z.naYin.element, FiveElement.earth);
      expect(z.explainer, contains('Metal Horse'));
    });
    test('Victoria 28 Oct 1991: 辛未 Metal Goat', () {
      final z = zodiacForBirth(DateTime(1991, 10, 28, 12));
      expect(z.pillar.chinese, '辛未');
      expect(z.name, 'Metal Goat');
      expect(z.animalElement, FiveElement.earth);
      expect(z.naYin.chinese, '路旁土');
    });
    test('Fire Horse years 1966 and 2026; Li Chun switch', () {
      expect(zodiacForSolarYear(1966).name, 'Fire Horse');
      expect(zodiacForSolarYear(2026).name, 'Fire Horse');
      expect(zodiacForBirth(DateTime(1990, 2, 2, 12)).pillar.chinese, '己巳');
    });
  });

  group('Tai Sui relations', () {
    const horse = 6, goat = 7, rat = 0, ox = 1, tiger = 2, rabbit = 3, snake = 5, monkey = 8, rooster = 9;
    test('Horse 2026 = 本命年·自刑 (offends)', () {
      final r = taiSuiReading(horse, 2026);
      expect(r.yearPillar.chinese, '丙午');
      expect(r.relations, [TaiSuiRelation.benMing, TaiSuiRelation.selfPunishment]);
      expect(r.chineseLabel, '本命年·自刑');
      expect(r.status, TaiSuiStatus.offends);
    });
    test('Horse 2027 = 六合 (harmony)', () {
      final r = taiSuiReading(horse, 2027);
      expect(r.yearPillar.chinese, '丁未');
      expect(r.relations, [TaiSuiRelation.sixHarmony]);
      expect(r.status, TaiSuiStatus.harmony);
    });
    test('Goat 2026 六合, 2027 本命 (未 has no self-punishment)', () {
      expect(taiSuiReading(goat, 2026).relations, [TaiSuiRelation.sixHarmony]);
      expect(taiSuiReading(goat, 2027).relations, [TaiSuiRelation.benMing]);
    });
    test('2026 Horse year: Rat clash, Ox harm, Rabbit break, Tiger three harmony', () {
      expect(taiSuiRelations(rat, horse), [TaiSuiRelation.clash]);
      expect(taiSuiRelations(ox, horse), [TaiSuiRelation.harm]);
      expect(taiSuiRelations(rabbit, horse), [TaiSuiRelation.breaks]);
      expect(taiSuiRelations(tiger, horse), [TaiSuiRelation.threeHarmony]);
    });
    test('2027 Goat year: Ox clash + punishment, Rat harm, Dog punishment + break, Pig three harmony', () {
      expect(taiSuiRelations(ox, goat), [TaiSuiRelation.clash, TaiSuiRelation.punishment]);
      expect(taiSuiRelations(rat, goat), [TaiSuiRelation.harm]);
      expect(taiSuiRelations(10, goat), [TaiSuiRelation.punishment, TaiSuiRelation.breaks]);
      expect(taiSuiRelations(11, goat), [TaiSuiRelation.threeHarmony]);
    });
    test('寅巳申 punishment, 子卯 punishment, snake-monkey six harmony + punishment + break', () {
      expect(taiSuiRelations(tiger, snake), containsAll([TaiSuiRelation.punishment, TaiSuiRelation.harm]));
      expect(taiSuiRelations(rat, rabbit), [TaiSuiRelation.punishment]);
      expect(taiSuiRelations(snake, monkey),
          [TaiSuiRelation.punishment, TaiSuiRelation.breaks, TaiSuiRelation.sixHarmony]);
      expect(taiSuiRelations(rooster, rooster), [TaiSuiRelation.benMing, TaiSuiRelation.selfPunishment]);
    });
  });

  group('Year afflictions', () {
    test('2026: Tai Sui S, Year Breaker N, Three Killings N, Five Yellow S, Two Black NW', () {
      final a = yearAfflictions(2026);
      expect(a.taiSui, Direction.s);
      expect(a.taiSuiMountain.chinese, '午');
      expect(a.yearBreaker, Direction.n);
      expect(a.yearBreakerMountain.chinese, '子');
      expect(a.threeKillings, Direction.n);
      expect(a.threeKillingsMountains.map((m) => m.chinese), ['亥', '子', '丑']);
      expect(a.fiveYellow, Direction.s);
      expect(a.twoBlack, Direction.nw);
    });
    test('2027 (FortuneCloud): Tai Sui SW, Year Breaker NE, Three Killings W, Five Yellow N, Two Black W', () {
      final a = yearAfflictions(2027);
      expect(a.taiSui, Direction.sw);
      expect(a.taiSuiMountain.chinese, '未');
      expect(a.yearBreaker, Direction.ne);
      expect(a.yearBreakerMountain.chinese, '丑');
      expect(a.threeKillings, Direction.w);
      expect(a.threeKillingsMountains.map((m) => m.chinese), ['申', '酉', '戌']);
      expect(a.fiveYellow, Direction.n);
      expect(a.twoBlack, Direction.w);
    });
    test('2028 Monkey: Tai Sui SW, Breaker NE, Three Killings S; 2029 Rooster: Three Killings E', () {
      expect(yearAfflictions(2028).threeKillings, Direction.s);
      expect(yearAfflictions(2029).threeKillings, Direction.e);
      expect(yearAfflictions(2029).taiSui, Direction.w);
    });
  });

  test('mountain centre degrees: 壬 345, 子 0, 午 180', () {
    expect(mountains[0].centreDegree, 345);
    expect(mountains[1].centreDegree, 0);
    expect(mountains[13].centreDegree, 180);
    for (final m in mountains) {
      expect(mountainAt(m.centreDegree).index, m.index);
    }
  });
}
