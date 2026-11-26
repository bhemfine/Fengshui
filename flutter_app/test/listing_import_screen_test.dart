import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inkstone/app.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/screens/listing_import_screen.dart';
import 'package:inkstone/screens/map_bearing_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _open(WidgetTester tester, String path, {Object? extra}) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const InkstoneApp());
  appRouter.go(Routes.floorUpload);
  await tester.pump(const Duration(milliseconds: 100));
  if (path != Routes.floorUpload) appRouter.push(path, extra: extra);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));
  ListingImportScreen.networkEnabled = false;
  MapBearingScreen.tilesEnabled = false;

  testWidgets('House tab has "Paste a listing link"', (tester) async {
    await _open(tester, Routes.floorUpload);
    expect(find.byKey(const Key('fu-import')), findsOneWidget);
  });

  testWidgets('a 99.co link fills the review card from the link (offline)', (tester) async {
    await _open(tester, Routes.listingImport,
        extra: const ListingImportArgs(
            text: 'https://www.99.co/singapore/sale/property/303b-anchorvale-link-hdb-eGDp7aWY44FaAneFoLkVsQ'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('li-review')), findsOneWidget);
    expect(find.textContaining('99.co listing eGDp7aWY44FaAneFoLkVsQ'), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(const Key('li-block'))).controller!.text, '303B');
    expect(tester.widget<TextField>(find.byKey(const Key('li-street'))).controller!.text, 'Anchorvale Link');
  });

  testWidgets('a PropertyGuru short link keeps the id; other links are refused', (tester) async {
    await _open(tester, Routes.listingImport);
    await tester.enterText(find.byKey(const Key('li-link')), 'https://example.com/house');
    await tester.tap(find.byKey(const Key('li-read')));
    await tester.pump();
    expect(find.textContaining('not a PropertyGuru, 99.co or HDB Flat Portal'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('li-link')), 'https://www.propertyguru.com.sg/l/500236540');
    await tester.tap(find.byKey(const Key('li-read')));
    await tester.pump();
    expect(find.textContaining('PropertyGuru listing 500236540'), findsOneWidget);
  });

  testWidgets('use in quick check pre-fills the home but never the facing', (tester) async {
    await _open(tester, Routes.listingImport,
        extra: const ListingImportArgs(
            text: 'https://www.propertyguru.com.sg/listing/hdb-for-sale-210-boon-lay-place-500248942'));
    await tester.pump(const Duration(milliseconds: 300));
    final list = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.byKey(const Key('li-year')), 200, scrollable: list);
    await tester.enterText(find.byKey(const Key('li-postal')), '640210');
    await tester.enterText(find.byKey(const Key('li-year')), '1977');
    await tester.pump();
    await tester.tap(find.byKey(const Key('li-use')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 2));
    final qc = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.byKey(const Key('qc-postal')), 200, scrollable: qc);
    expect(tester.widget<TextField>(find.byKey(const Key('qc-year'))).controller!.text, '1977');
    expect(tester.widget<TextField>(find.byKey(const Key('qc-postal'))).controller!.text, '640210');
    expect(tester.widget<TextField>(find.byKey(const Key('qc-address'))).controller!.text, '210 Boon Lay Place');
    expect(find.textContaining('Filled in from PropertyGuru listing 500248942'), findsOneWidget);
    // Facing is not chosen: the result button stays disabled until the user picks.
    expect(find.text('Answer each step to see the result'), findsOneWidget);
  });
}
