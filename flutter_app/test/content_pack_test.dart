import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkstone/data/your_year.dart';

Map<String, Object?> _root(String rel) =>
    jsonDecode(File(rel).readAsStringSync()) as Map<String, Object?>;

void main() {
  test('app copy of forecast_templates matches content/ byte for byte', () {
    expect(
      File('assets/content/forecast_templates.json').readAsBytesSync(),
      File('../content/forecast_templates.json').readAsBytesSync(),
    );
  });

  test('written packs exist for every animal in 2026–2035 with no empty or placeholder fields', () {
    final yearly = _root('assets/content/forecast_templates.json')['yearly'] as Map;
    const animals = [
      'rat', 'ox', 'tiger', 'rabbit', 'dragon', 'snake',
      'horse', 'goat', 'monkey', 'rooster', 'dog', 'pig',
    ];
    const prose = ['overview', 'career', 'money', 'love', 'health_wellbeing', 'tai_sui_note'];
    for (final year in forecastYears) {
      final block = yearly['$year'] as Map;
      expect(block['zh'], isNotEmpty, reason: '$year zh');
      expect(block['en'], isNotEmpty, reason: '$year en');
      final pack = block['animals'] as Map;
      expect(pack.keys.map((k) => '$k').toSet(), unorderedEquals(animals), reason: '$year animals');
      for (final animal in animals) {
        final a = pack[animal] as Map;
        for (final f in prose) {
          final text = '${a[f]}'.trim();
          expect(text, isNotEmpty, reason: '$year $animal.$f');
          expect(text.toLowerCase().contains('todo'), isFalse);
          expect(text.toLowerCase().contains('lorem'), isFalse);
          expect(text.toLowerCase().contains('placeholder'), isFalse);
          if (year >= 2028) {
            expect(text.length, greaterThanOrEqualTo(80), reason: '$year $animal.$f length');
          }
        }
        expect((a['dos'] as List), isNotEmpty, reason: '$year $animal.dos');
        expect((a['avoids'] as List), isNotEmpty, reason: '$year $animal.avoids');
        if (year >= 2028) {
          expect((a['dos'] as List).length, greaterThanOrEqualTo(4));
          expect((a['avoids'] as List).length, greaterThanOrEqualTo(4));
        }
      }
    }
  });
}
