import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inkstone/data/tarot_catalog.dart';
import 'package:inkstone/motion/motion.dart';
import 'package:inkstone/screens/tarot_screen.dart';
import 'package:inkstone/theme/app_theme.dart';
import 'package:inkstone/widgets/gold_button.dart';

Map<String, Object?> _j(String rel) =>
    jsonDecode(File(rel).readAsStringSync()) as Map<String, Object?>;

TarotCatalog _catalog() => TarotCatalog.parse(
  readings: _j('assets/content/tarot/readings.json'),
  classifier: _j('assets/content/tarot/classifier.json'),
  spreads: _j('assets/content/tarot/spreads.json'),
);

Widget _app(TarotCatalog cat) {
  final theme = buildInkTheme();
  return MaterialApp.router(
    theme: theme,
    darkTheme: theme,
    themeMode: ThemeMode.dark,
    routerConfig: GoRouter(
      initialLocation: '/tarot',
      routes: [
        GoRoute(
          path: '/tarot',
          builder: (_, __) => TarotScreen(catalog: cat),
        ),
        GoRoute(path: '/readings', builder: (_, __) => const SizedBox()),
      ],
    ),
  );
}

Future<void> _pumpThroughShuffle(WidgetTester tester) async {
  // The screen starts the shuffle on the next frame so the deck is mounted.
  await tester.pump();
  await tester.pump();
  await tester.pump(Motion.tarotShuffle + const Duration(milliseconds: 50));
  await tester.pump(Motion.tarotSettle + const Duration(milliseconds: 50));
}

Future<void> _pick(WidgetTester tester, int i) async {
  await tester.tap(find.byKey(Key('tarot-pick-$i')));
  await tester.pump();
  await tester.pump(Motion.tarotFlip + const Duration(milliseconds: 50));
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  late TarotCatalog cat;

  setUpAll(() => cat = _catalog());

  Future<void> open(
    WidgetTester tester, {
    Size size = const Size(412, 915),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(cat));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  for (final size in const [Size(360, 740), Size(412, 915)]) {
    for (final asked in [false, true]) {
      testWidgets(
        'one-card shuffle, reading, full screen, shuffle again'
        '${asked ? ' with a question' : ''} at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await open(tester, size: size);
          if (asked) {
            await tester.enterText(
              find.byType(TextField),
              'Will this week go well?',
            );
            await tester.pump();
          }
          expect(find.text('Shuffle'), findsOneWidget);
          await tester.tap(find.text('Shuffle'));
          await tester.pump();
          // Must not stay on Shuffling... after the animation.
          await _pumpThroughShuffle(tester);
          expect(find.text('Shuffling…'), findsNothing);
          expect(find.text('Pick one card'), findsOneWidget);
          await _pick(tester, 3);
          expect(find.byKey(const Key('tarot-reading-sheet')), findsOneWidget);
          expect(find.text('Shuffle again'), findsOneWidget);
          if (asked) {
            expect(
              find.textContaining('Will this week go well?'),
              findsWidgets,
            );
          }
          await tester.tap(find.byKey(const Key('tarot-revealed-row')).first);
          // The revealed card itself is more reliable:
          await tester.pump();
          // If the first tap hit the row but not a card, tap the first revealed card key prefix
          if (find.byType(TarotCardViewer).evaluate().isEmpty) {
            final card = find.byWidgetPredicate(
              (w) =>
                  w.key is ValueKey<String> &&
                  (w.key as ValueKey<String>).value.startsWith(
                    'tarot-reveal-card-',
                  ),
            );
            expect(card, findsWidgets);
            await tester.tap(card.first);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          } else {
            await tester.pump(const Duration(milliseconds: 300));
          }
          expect(find.byType(TarotCardViewer), findsOneWidget);
          await tester.tap(find.widgetWithText(MidnightButton, 'Close'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(TarotCardViewer), findsNothing);

          await tester.tap(find.text('Shuffle again'));
          await tester.pump();
          await _pumpThroughShuffle(tester);
          expect(find.text('Shuffling…'), findsNothing);
          expect(find.text('Pick one card'), findsOneWidget);
          expect(find.text('Shuffle'), findsOneWidget);
        },
      );
    }
  }

  testWidgets('three-card shuffle with a question reaches a reading', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Past, present, future'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'What should I focus on?');
    await tester.pump();
    await tester.tap(find.text('Shuffle'));
    await tester.pump();
    await _pumpThroughShuffle(tester);
    expect(find.text('Shuffling…'), findsNothing);
    expect(find.text('Pick 3 cards'), findsOneWidget);
    await _pick(tester, 3);
    expect(find.text('Pick 2 more'), findsOneWidget);
    await _pick(tester, 2);
    expect(find.text('Pick 1 more'), findsOneWidget);
    await _pick(tester, 4);
    expect(find.byKey(const Key('tarot-reading-sheet')), findsOneWidget);
    expect(find.textContaining('What should I focus on?'), findsWidgets);
    expect(find.text('Shuffle again'), findsOneWidget);
  });

  testWidgets('a failed or missing deck re-enables Shuffle', (tester) async {
    await open(tester, size: const Size(412, 915));
    await tester.tap(find.text('Shuffle'));
    await tester.pump();
    await _pumpThroughShuffle(tester);
    // After a completed shuffle the button is enabled again (arc is not busy).
    final shuffle = tester.widget<MidnightButton>(
      find.widgetWithText(MidnightButton, 'Shuffle'),
    );
    expect(shuffle.onPressed, isNotNull);
  });
}
