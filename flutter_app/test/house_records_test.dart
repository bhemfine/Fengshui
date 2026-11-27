import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inkstone/app.dart';
import 'package:inkstone/data/current_home.dart';
import 'package:inkstone/data/house_records.dart';
import 'package:inkstone/data/onboarding.dart';
import 'package:inkstone/data/quick_check.dart';
import 'package:inkstone/data/user_data.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone_engine/inkstone_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

CurrentHome _home() => const CurrentHome(
  label: '912 Hougang Street 91',
  facingDegrees: 142,
  completionYear: 2012,
  period: 8,
  example: false,
  address: '912 Hougang Street 91',
  postalCode: '530912',
  floor: '12',
  type: PropertyType.hdb,
);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    resetHouseRecords();
    currentHome.value = exampleHome;
    resetOnboardingForTest();
  });

  tearDown(() {
    resetHouseRecords();
    resetOnboardingForTest();
  });

  test('a result and a draft persist and reload', () async {
    await saveHouseResult(name: 'Hougang flat', home: _home());
    await saveHouseDraft(
      name: 'Condo draft',
      draft: const QuickCheckPrefill(
        type: PropertyType.condo,
        yearText: '2018',
        completionYear: 2018,
        home: HomeDetails(address: 'A condo', postalCode: '098765'),
      ),
    );
    expect(houseRecords.value, hasLength(2));
    expect(
      houseRecords.value.map((r) => r.name),
      containsAll(['Hougang flat', 'Condo draft']),
    );
    houseRecords.value = const [];
    await bootstrapHouseRecords();
    expect(houseRecords.value, hasLength(2));
    final result = houseRecords.value.firstWhere((r) => !r.isDraft);
    expect(result.home!.facingDegrees, 142);
    expect(result.home!.floor, '12');
    expect(result.summary, contains('door'));
    final draft = houseRecords.value.firstWhere((r) => r.isDraft);
    expect(draft.draft!.type, PropertyType.condo);
    expect(draft.draft!.yearText, '2018');
    expect(draft.draft!.home!.postalCode, '098765');
  });

  test('rename, delete, and Delete my data clear saved homes', () async {
    final a = await saveHouseResult(name: 'Keep me', home: _home());
    await saveHouseDraft(
      name: 'Temp draft',
      draft: const QuickCheckPrefill(type: PropertyType.hdb, yearText: '2008'),
    );
    await renameHouseRecord(a.id, 'Renamed flat');
    expect(
      houseRecords.value.firstWhere((r) => r.id == a.id).name,
      'Renamed flat',
    );
    await removeHouseRecord(a.id);
    expect(houseRecords.value, hasLength(1));
    expect(houseRecords.value.single.isDraft, isTrue);

    await deleteAllUserData();
    expect(houseRecords.value, isEmpty);
    await bootstrapHouseRecords();
    expect(houseRecords.value, isEmpty);
  });

  test('QuickCheckInput JSON round-trips facings and people', () {
    final input = QuickCheckInput(
      type: PropertyType.hdb,
      completionYear: 2012,
      method: FacingMethod.unsure,
      facings: const {FacingMethod.mainDoor: 142, FacingMethod.balcony: 322},
      people: const [],
      home: const HomeDetails(address: '912 Hougang', floor: '12'),
    );
    final copy = QuickCheckInput.fromJson(input.toJson());
    expect(copy.type, PropertyType.hdb);
    expect(copy.facings[FacingMethod.mainDoor], 142);
    expect(copy.home!.floor, '12');
  });

  testWidgets('saved homes list can open, rename and delete a result', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await saveHouseResult(name: 'Hougang flat', home: _home());
    await tester.pumpWidget(const InkstoneApp());
    appRouter.go(Routes.savedHomes);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Hougang flat'), findsOneWidget);
    expect(find.text('Saved results'), findsOneWidget);

    await tester.tap(find.text('Rename'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField).last, 'New name');
    await tester.tap(find.text('Rename').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('New name'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Delete').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('New name'), findsNothing);
    expect(find.textContaining('No saved homes yet'), findsOneWidget);
  });
}
