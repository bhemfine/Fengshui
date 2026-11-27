import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inkstone/data/tarot_catalog.dart';
import 'package:inkstone/data/tarot_classifier.dart';
import 'package:inkstone/data/tarot_reading.dart';
import 'package:inkstone/screens/tarot_screen.dart';
import 'package:inkstone/theme/app_theme.dart';

Map<String, Object?> _j(String rel) =>
    jsonDecode(File(rel).readAsStringSync()) as Map<String, Object?>;

TarotCatalog _catalog() => TarotCatalog.parse(
  readings: _j('assets/content/tarot/readings.json'),
  classifier: _j('assets/content/tarot/classifier.json'),
  spreads: _j('assets/content/tarot/spreads.json'),
);

TarotReading _threeCard(TarotCatalog cat) {
  final q = TarotClassifier(
    cat.classifier,
  ).classify('Do you see a future with my partner?');
  return TarotComposer(cat.spreads, disclaimer: cat.disclaimer).compose(
    draws: [
      TarotDrawn(card: cat.cardById('the-fool'), reversed: false),
      TarotDrawn(card: cat.cardById('the-lovers'), reversed: false),
      TarotDrawn(card: cat.cardById('the-star'), reversed: true),
    ],
    spread: cat.spreads.byId('past_present_future'),
    question: q,
  );
}

Widget _app({required Widget home}) {
  final theme = buildInkTheme();
  return MaterialApp.router(
    theme: theme,
    darkTheme: theme,
    themeMode: ThemeMode.dark,
    routerConfig: GoRouter(
      initialLocation: '/tarot',
      routes: [
        GoRoute(path: '/tarot', builder: (_, __) => home),
        GoRoute(path: '/readings', builder: (_, __) => const SizedBox()),
      ],
    ),
  );
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  late TarotCatalog cat;
  late TarotReading reading;

  setUpAll(() {
    cat = _catalog();
    reading = _threeCard(cat);
  });

  for (final size in const [Size(360, 740), Size(412, 915)]) {
    testWidgets(
      'idle tarot fits at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_app(home: TarotScreen(catalog: cat)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('tarot-setup')), findsOneWidget);
        expect(find.byKey(const Key('tarot-deck')), findsOneWidget);
        expect(find.text('Shuffle'), findsOneWidget);
        expect(find.byKey(const Key('tarot-reading-sheet')), findsNothing);
      },
    );

    testWidgets(
      'revealed cards stay above the reading sheet at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _app(
            home: TarotScreen(catalog: cat, initialReading: reading),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('tarot-setup')), findsNothing);
        expect(find.byKey(const Key('tarot-collapsed-setup')), findsOneWidget);
        expect(find.byKey(const Key('tarot-revealed-row')), findsOneWidget);
        expect(find.byKey(const Key('tarot-reading-sheet')), findsOneWidget);
        expect(find.text('Shuffle again'), findsOneWidget);

        final card = find.byKey(const Key('tarot-reveal-card-the-fool'));
        expect(card, findsOneWidget);
        final sheet = tester.getRect(
          find.byKey(const Key('tarot-reading-sheet')),
        );
        final cardBox = tester.getRect(card);
        // The cards sit in the space above the reading panel, not under it.
        expect(cardBox.bottom, lessThanOrEqualTo(sheet.top + 8));
        expect(cardBox.height, greaterThan(80));
        expect(cardBox.width, greaterThan(50));

        await tester.tap(card);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(TarotCardViewer), findsOneWidget);
        expect(find.text('The Fool'), findsWidgets);
        expect(find.textContaining('Upright'), findsWidgets);
        await tester.tap(find.text('Close'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(TarotCardViewer), findsNothing);
      },
    );
  }
}
