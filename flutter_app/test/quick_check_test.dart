import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inkstone/app.dart';
import 'package:inkstone/data/household.dart';
import 'package:inkstone/data/local_store.dart';
import 'package:inkstone/data/sample_data.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone_engine/inkstone_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sample profile Mei Lin shows the engine Kua (7)', () {
    final k = computeKua(DateTime(1992, 3, 12, 8, 15), Gender.female);
    expect(k.kua, 7);
    expect(meiLin.kua, k.kua);
    expect(savedProfiles.first.kua.kua, 7);
    expect(savedProfiles[1].kua.kua, 2); // Wei Hao, male 1989
    expect(kuaGoodDirections, dirs(k.lucky));
    expect(kuaCareDirections, dirs(k.unlucky));
  });

  testWidgets('example result: Kua and verdicts for both facings', (tester) async {
    await _open(tester, Routes.quickCheckResult);
    expect(find.textContaining('Period 8'), findsWidgets);
    final list = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('Mei Lin · Kua 7'), 300, scrollable: list);
    expect(find.text('Mei Lin · Kua 7'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Wei Hao · Kua 2'), 300, scrollable: list);
    expect(find.text('Wei Hao · Kua 2'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Shared good directions'), 300, scrollable: list);
    expect(find.textContaining('NE, SW, W, NW: good for both'), findsOneWidget);
  });

  testWidgets('example result shows the facing verdicts', (tester) async {
    await _open(tester, Routes.quickCheckResult);
    final list = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.textContaining('Not good for either'), 200, scrollable: list);
    expect(find.textContaining('Not good for either'), findsOneWidget); // main door SE
    await tester.scrollUntilVisible(find.textContaining('Good for both'), 200, scrollable: list);
    expect(find.textContaining('Good for both'), findsOneWidget); // balcony NW
  });

  testWidgets('quick check asks HDB users which facing method to use', (tester) async {
    await _open(tester, Routes.quickCheck);
    await tester.tap(find.text('HDB'));
    await tester.pump();
    expect(find.textContaining('masters differ'), findsOneWidget);
    expect(find.text('Not sure, show both'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('qc-year')), '2024');
    await tester.pump();
    expect(find.textContaining('before Li Chun'), findsOneWidget);
  });

  testWidgets('checklist: answering flags an issue and saves locally', (tester) async {
    await _open(tester, Routes.homeChecklist);
    // Asset loading is real I/O: let it finish outside the fake clock.
    for (var i = 0; i < 20 && find.text('Flagged issues · 0').evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    expect(find.text('Flagged issues · 0'), findsOneWidget);
    expect(find.textContaining('never moved'), findsOneWidget);
    if (DateTime.now().year == 2026) {
      expect(find.textContaining('2026 renovation note'), findsWidgets);
    }
    // First item in "All homes" is the shape question (flag on "No").
    final list = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('No').first, 200, scrollable: list);
    await tester.tap(find.text('No').first);
    await tester.pump();
    expect(find.text('Flagged issues · 1'), findsOneWidget);
    final saved = (await tester.runAsync(() => LocalStore.instance.loadAnswers(PropertyType.hdb)))!;
    expect(saved['shape_regular'], Answer.no);
  });
}
