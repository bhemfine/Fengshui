// v4: Your year, lucky lists, afflictions and engine-wired screens, offline.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inkstone/app.dart';
import 'package:inkstone/data/content_repo.dart';
import 'package:inkstone/data/current_home.dart';
import 'package:inkstone/data/household.dart';
import 'package:inkstone/data/your_year.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone_engine/inkstone_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, Object?> _j(String f) =>
    jsonDecode(File('assets/content/$f.json').readAsStringSync()) as Map<String, Object?>;

Future<void> _open(WidgetTester tester, String path) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const InkstoneApp());
  appRouter.go(path);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  late AppContent content;
  setUpAll(() {
    content = AppContent.fromJson(forecast: _j('forecast_templates'), crystals: _j('crystals'), rituals: _j('rituals'));
    ContentRepo.setForTest(content);
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('bundled content matches content/ byte for byte', () {
    for (final f in ['forecast_templates', 'crystals', 'rituals']) {
      expect(File('assets/content/$f.json').readAsStringSync(), File('../content/$f.json').readAsStringSync(), reason: f);
    }
  });

  test('Boon Eng 2026: Metal Horse, 本命年·自刑, template and lucky lists', () {
    final y = YourYear.compute(mainUser, 2026, content);
    expect(y.zodiac.name, 'Metal Horse');
    expect(y.zodiac.naYin.chinese, '路旁土');
    expect(y.taiSui.chineseLabel, '本命年·自刑');
    expect(y.template, isNotNull);
    expect(y.template!.dos, isNotEmpty);
    expect(y.lucky.favourable, [FiveElement.metal, FiveElement.water]);
    expect(y.lucky.luckyNumbers, [4, 9, 1, 6]);
    expect(y.lucky.luckyColours, contains('white'));
    expect(y.lucky.unluckyColours, contains('red'));
    expect(y.lucky.luckyRituals.first.id, 'lucky_red_thread');
  });

  test('Boon Eng 2027: 六合; Victoria 2026 六合, 2027 本命年', () {
    expect(YourYear.compute(mainUser, 2027, content).taiSui.relations, contains(TaiSuiRelation.sixHarmony));
    expect(YourYear.compute(partner, 2026, content).taiSui.relations, contains(TaiSuiRelation.sixHarmony));
    expect(YourYear.compute(partner, 2027, content).taiSui.relations, contains(TaiSuiRelation.benMing));
  });

  test('floor plan palaces come from the engine for the current home', () {
    final h = currentHome.value;
    final ps = planPalaces(h);
    expect(ps, hasLength(9));
    final chart = natalChart(h.facingDegrees, h.period);
    final centre = chart.palaces[Direction.centre]!;
    final c = ps[planGridOrder.indexOf(Direction.centre)];
    expect(c.mountain, centre.mountain);
    expect(c.water, centre.facing);
    expect(h.period, 8);
  });

  testWidgets('Your year screen shows zodiac, Tai Sui, lucky and unlucky cards', (tester) async {
    await _open(tester, Routes.yearly);
    for (final k in ['yy-zodiac', 'yy-taisui', 'yy-lucky']) {
      expect(find.byKey(Key(k)), findsOneWidget, reason: k);
    }
    expect(find.textContaining('Metal Horse'), findsWidgets);
  });

  testWidgets('BaZi and compatibility show the zodiac from the engine', (tester) async {
    await _open(tester, Routes.bazi);
    expect(find.byKey(const Key('bazi-zodiac')), findsOneWidget);
    await _open(tester, Routes.compatibility);
    expect(find.byKey(const Key('compat-zodiac')), findsOneWidget);
    expect(find.textContaining('Six Harmony'), findsWidgets);
  });
}
