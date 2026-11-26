import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inkstone/app.dart';
import 'package:inkstone/data/address_search.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/screens/map_bearing_screen.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  MapBearingScreen.tilesEnabled = false;

  test('parses Nominatim results and marks postcode hits approximate', () {
    const body = '[{"lat":"1.3456239","lon":"103.9535846","type":"postcode","addresstype":"postcode",'
        '"display_name":"520123, Tampines, East Region, Singapore"},'
        '{"lat":"1.3458","lon":"103.9489","type":"apartments","addresstype":"building",'
        '"display_name":"123, Tampines Street 11, Singapore"}]';
    final hits = parseNominatim(body);
    expect(hits.length, 2);
    expect(hits.first.approximate, isTrue);
    expect(hits.first.label, '520123, Tampines, East Region');
    expect(hits.last.approximate, isFalse);
    expect(hits.last.lat, closeTo(1.3458, 1e-9));
  });

  testWidgets('map bearing: pin then facing point gives a bearing', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const InkstoneApp());
    appRouter.go(Routes.mapBearing);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('drop a pin'), findsOneWidget);
    final map = find.byType(FlutterMap);
    final c = tester.getCenter(map);
    await tester.tapAt(c);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('straight out from the opening'), findsOneWidget);
    // The bottom panel can change height, which keeps the map centre (the pin)
    // at the new middle of the map. Tap to the right of it: due east.
    await tester.tapAt(tester.getCenter(map) + const Offset(120, 0));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('East ·'), findsOneWidget);
    final label = tester.widget<Text>(find.textContaining('East ·')).data!;
    expect(label, matches(RegExp(r'East · (89|90|91)°')));
  });
}
