import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inkstone/app.dart';
import 'package:inkstone/data/household.dart';
import 'package:inkstone/data/local_store.dart';
import 'package:inkstone/data/onboarding.dart';
import 'package:inkstone/data/user_data.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone_engine/inkstone_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    resetOnboardingForTest();
    resetHouseholdDefaults();
  });

  tearDown(() {
    resetOnboardingForTest();
    resetHouseholdDefaults();
  });

  test(
    'a saved household from an older build marks onboarding complete',
    () async {
      await setMainUser(
        KuaPerson(
          name: 'Chua Boon Eng',
          birth: DateTime.parse('1990-06-26T12:00:00'),
          gender: Gender.male,
          saved: true,
          example: true,
          timeKnown: false,
        ),
      );
      expect(onboardingComplete, isFalse);
      await bootstrapOnboarding();
      expect(onboardingComplete, isTrue);
      expect(await LocalStore.instance.loadBool(onboardingKey), isTrue);
    },
  );

  test(
    'Delete my data keeps onboarding complete so birth is not re-asked',
    () async {
      await markOnboardingComplete();
      await deleteAllUserData();
      expect(onboardingComplete, isTrue);
      expect(await LocalStore.instance.loadBool(onboardingKey), isTrue);
      expect(mainUser.name, 'Chua Boon Eng');
    },
  );

  testWidgets('cold start without the flag still opens Welcome', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const InkstoneApp());
    appRouter.go(Routes.welcome);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Begin'), findsOneWidget);
    expect(find.text('Your birth details'), findsNothing);
  });

  testWidgets('after onboarding is complete, Welcome redirects to Today', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await markOnboardingComplete();
    await tester.pumpWidget(const InkstoneApp());
    appRouter.go(Routes.welcome);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Begin'), findsNothing);
    expect(find.text('Your birth details'), findsNothing);
    expect(find.text('for Boon Eng'), findsOneWidget);
  });
}
