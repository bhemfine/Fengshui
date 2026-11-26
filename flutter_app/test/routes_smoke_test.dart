// Smoke test: every route builds and lays out without throwing on a small and a large phone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inkstone/app.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/screens/map_bearing_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const paths = [
  '/welcome', '/birth', '/today', '/monthly', '/yearly', '/floor-upload', '/floor-result',
  '/house-check', '/readings', '/tarot', '/palm', '/bazi', '/compatibility', '/shop', '/masters',
  '/master-profile', '/booking-pending', '/booking-confirm', '/prescription', '/profile', '/paywall',
  '/quick-check', '/quick-check-result', '/direction-calculator', '/home-checklist', '/map-bearing',
];

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues({});
  MapBearingScreen.tilesEnabled = false;
  for (final size in const [Size(360, 740), Size(412, 915)]) {
    for (final p in paths) {
      testWidgets('route $p builds at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(const InkstoneApp());
        appRouter.go(p);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(seconds: 2));
        expect(find.byType(InkstoneApp), findsOneWidget);
      });
    }
  }
}
