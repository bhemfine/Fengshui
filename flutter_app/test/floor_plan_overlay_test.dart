import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inkstone/data/current_home.dart';
import 'package:inkstone/widgets/floor_plan_overlay.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets(
    '3x3 grid fits a 280-tall box and the facing cell stays tappable',
    (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      int? tapped;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloorPlanOverlay(
              home: exampleHome,
              height: 280,
              onZoneTap: (i) => tapped = i,
            ),
          ),
        ),
      );
      expect(find.text('Facing'), findsOneWidget);
      expect(find.text('Centre'), findsOneWidget);
      expect(find.text('Sitting'), findsOneWidget);
      await tester.tap(find.text('Facing'));
      await tester.pump();
      expect(tapped, isNotNull);
      await tester.tap(find.text('Sitting'));
      await tester.pump();
      expect(
        tapped,
        isNot(8),
      ); // sitting is opposite the bottom-centre facing cell
    },
  );
}
