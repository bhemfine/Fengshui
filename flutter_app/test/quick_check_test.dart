import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inkstone/app.dart';
import 'package:inkstone/data/household.dart';
import 'package:inkstone/data/local_store.dart';
import 'package:inkstone/data/example_charts.dart';
import 'package:inkstone/data/quick_check.dart';
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

  test('only the example couple remain; Boon Eng is the main user', () {
    expect(savedProfiles.map((p) => p.name), [
      'Chua Boon Eng',
      'Chou Jiahui Victoria',
    ]);
    expect(mainUser.name, 'Chua Boon Eng');
    expect(partner.name, 'Chou Jiahui Victoria');
    expect(exampleQuickCheck.people.map((p) => p.name), [
      'Chua Boon Eng',
      'Chou Jiahui Victoria',
    ]);
    expect(
      mainUser.kua.kua,
      computeKua(DateTime(1990, 6, 26, 12), Gender.male).kua,
    );
  });

  test('example verdicts come from the engine', () {
    final se = matchFacing(Direction.se, [
      ('B', mainUser.kua),
      ('V', partner.kua),
    ]);
    expect(
      se.fit,
      FacingFit.goodForSome,
    ); // SE is Sheng Qi for Kua 1, bad for Kua 6
    expect(homeFitFor(mainUser, Direction.se).good, isTrue);
    expect(homeFitFor(partner, Direction.se).good, isFalse);
    expect(sharedGoodDirections([mainUser.kua, partner.kua]), isEmpty);
    final (verdict, line, _, _) = dayMasterFit(
      PersonChart(mainUser),
      PersonChart(partner),
    );
    expect(PersonChart(mainUser).dayMaster, 'Ren Water');
    expect(PersonChart(partner).dayMaster, 'Xin Metal');
    expect(verdict, 'Good fit'); // Metal feeds Water
    expect(line, contains('Metal feeds Water'));
  });

  test(
    'example couple profiles: Boon Eng Kua 1 (East), Jiahui Kua 6 (West)',
    () {
      final b = profileNamed('Chua Boon Eng').kua;
      final v = profileNamed('Chou Jiahui Victoria').kua;
      expect((b.kua, b.eastGroup, dirs(b.lucky)), (1, true, 'SE, E, S, N'));
      expect((v.kua, v.eastGroup, dirs(v.lucky)), (6, false, 'W, NE, SW, NW'));
      expect(profileNamed('Chua Boon Eng').timeKnown, isFalse);
    },
  );

  testWidgets(
    'quick check: both examples picked by default, listing import button',
    (tester) async {
      await _open(tester, Routes.quickCheck);
      expect(find.byKey(const Key('qc-import')), findsOneWidget);
    },
  );

  testWidgets('quick check lists the example couple', (tester) async {
    await _open(tester, Routes.quickCheck);
    final list = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Chua Boon Eng (example)'),
      300,
      scrollable: list,
    );
    expect(find.text('Chua Boon Eng (example)'), findsOneWidget);
    expect(find.text('Chou Jiahui Victoria (example)'), findsOneWidget);
  });

  testWidgets('example result: Kua and verdicts for both facings', (
    tester,
  ) async {
    await _open(tester, Routes.quickCheckResult);
    expect(find.textContaining('Period 8'), findsWidgets);
    final list = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Chua Boon Eng · Kua 1'),
      300,
      scrollable: list,
    );
    expect(find.text('Chua Boon Eng · Kua 1'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Chou Jiahui Victoria · Kua 6'),
      300,
      scrollable: list,
    );
    expect(find.text('Chou Jiahui Victoria · Kua 6'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Shared good directions'),
      300,
      scrollable: list,
    );
    expect(
      find.textContaining('No direction is good for both'),
      findsOneWidget,
    );
  });

  testWidgets('example result shows the facing verdicts', (tester) async {
    await _open(tester, Routes.quickCheckResult);
    final list = find.byType(Scrollable).first;
    // Main door SE suits Boon Eng (Kua 1); balcony NW suits Jiahui (Kua 6).
    await tester.scrollUntilVisible(
      find.textContaining('Suits Chua Boon Eng only'),
      200,
      scrollable: list,
    );
    expect(find.textContaining('Suits Chua Boon Eng only'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Suits Chou Jiahui Victoria only'),
      200,
      scrollable: list,
    );
    expect(
      find.textContaining('Suits Chou Jiahui Victoria only'),
      findsOneWidget,
    );
  });

  testWidgets('quick check asks HDB users which facing method to use', (
    tester,
  ) async {
    await _open(tester, Routes.quickCheck);
    await tester.tap(find.text('HDB'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Not sure, show both'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('masters differ'), findsOneWidget);
    expect(find.text('Not sure, show both'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('qc-year')),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byKey(const Key('qc-year')), '2024');
    await tester.pump();
    expect(find.textContaining('before Li Chun'), findsOneWidget);
  });

  testWidgets('checklist: answering flags an issue and saves locally', (
    tester,
  ) async {
    await _open(tester, Routes.homeChecklist);
    // Asset loading is real I/O: let it finish outside the fake clock.
    for (
      var i = 0;
      i < 20 && find.text('Flagged issues · 0').evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    expect(find.text('Flagged issues · 0'), findsOneWidget);
    expect(find.textContaining('never moved'), findsOneWidget);
    if (DateTime.now().year == 2026) {
      expect(find.textContaining('2026 renovation note'), findsWidgets);
    }
    // First item in "All homes" is the shape question (flag on "No").
    final list = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('No'), 200, scrollable: list);
    await tester.ensureVisible(find.text('No').first);
    await tester.pump();
    await tester.tap(find.text('No').first);
    await tester.pump();
    await tester.scrollUntilVisible(
      find.textContaining('Flagged issues'),
      -200,
      scrollable: list,
    );
    expect(find.text('Flagged issues · 1'), findsOneWidget);
    final saved = (await tester.runAsync(
      () => LocalStore.instance.loadAnswers(PropertyType.hdb),
    ))!;
    expect(saved['shape_regular'], Answer.no);
  });
}
