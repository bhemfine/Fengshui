import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inkstone/app.dart';
import 'package:inkstone/data/onboarding.dart';
import 'package:inkstone/data/sample_data.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/screens/masters_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _open(WidgetTester tester, String path, {Object? extra}) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await markOnboardingComplete();
  await tester.pumpWidget(const InkstoneApp());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  if (extra != null) {
    appRouter.go(path, extra: extra);
  } else {
    appRouter.go(path);
  }
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetOnboardingForTest();
  });

  tearDown(resetOnboardingForTest);

  test('master filter chips match specialities and languages', () {
    final tan = sampleMasters[0];
    final lim = sampleMasters[1];
    final nur = sampleMasters[2];
    expect(masterMatchesFilters(tan, {'BaZi'}), isTrue);
    expect(masterMatchesFilters(lim, {'BaZi'}), isFalse);
    expect(masterMatchesFilters(tan, {'Feng shui'}), isTrue);
    expect(masterMatchesFilters(lim, {'Feng shui'}), isTrue);
    expect(masterMatchesFilters(nur, {'Feng shui'}), isFalse);
    expect(masterMatchesFilters(nur, {'Mandarin'}), isFalse);
    expect(masterMatchesFilters(tan, {'BaZi', 'Mandarin'}), isTrue);
    expect(masterMatchesFilters(nur, {'BaZi', 'Mandarin'}), isFalse);
  });

  testWidgets('masters list follows the selected filters', (tester) async {
    await _open(tester, Routes.masters);
    expect(find.text('Tan Su Ling'), findsOneWidget);
    expect(find.text('Lim Boon Kiat'), findsOneWidget);
    expect(find.text('Nur Aisyah Rahman'), findsOneWidget);

    await tester.tap(find.text('BaZi'));
    await tester.pump();
    expect(find.text('Tan Su Ling'), findsOneWidget);
    expect(find.text('Nur Aisyah Rahman'), findsOneWidget);
    expect(find.text('Lim Boon Kiat'), findsNothing);

    await tester.tap(find.text('Mandarin'));
    await tester.pump();
    expect(find.text('Tan Su Ling'), findsOneWidget);
    expect(find.text('Nur Aisyah Rahman'), findsNothing);
    expect(find.text('Lim Boon Kiat'), findsNothing);
  });

  testWidgets('booking screens show the time slot the user picked', (
    tester,
  ) async {
    const slot = 'Wed 25 Nov, 8:00pm SGT';
    await _open(tester, Routes.bookingPending, extra: slot);
    expect(find.textContaining(slot), findsOneWidget);
    await tester.tap(find.text('Preview: master accepts (example)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining(slot), findsWidgets);
  });

  testWidgets('compass error offers Try again and does not stay stuck', (
    tester,
  ) async {
    await _open(tester, Routes.directionCalculator);
    expect(find.text('Start compass'), findsOneWidget);
    await tester.tap(find.text('Start compass'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Start compass'), findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(find.text('Try again'), findsNothing);
    // Timer was cancelled/restarted; no pending timer leak after dispose.
  });
}
