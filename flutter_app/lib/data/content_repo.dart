import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:inkstone_engine/inkstone_engine.dart';

/// Offline content bundled from content/ (kept byte-identical; an engine test checks).
class ContentRepo {
  ContentRepo._();
  static Future<AppContent>? _cache;

  static Future<AppContent> load() => _cache ??= _load();

  /// For tests: inject decoded JSON.
  static void setForTest(AppContent c) => _cache = Future.value(c);

  static Future<AppContent> _load() async {
    Future<Map<String, Object?>> j(String f) async =>
        jsonDecode(await rootBundle.loadString('assets/content/$f.json'))
            as Map<String, Object?>;
    final results = await Future.wait([
      j('forecast_templates'),
      j('crystals'),
      j('rituals'),
    ]);
    return AppContent.fromJson(
      forecast: results[0],
      crystals: results[1],
      rituals: results[2],
    );
  }
}

class YearTemplate {
  const YearTemplate({
    required this.year,
    required this.yearName,
    required this.overview,
    required this.career,
    required this.money,
    required this.love,
    required this.health,
    required this.dos,
    required this.avoids,
    required this.luckyMonths,
    required this.taiSuiNote,
  });
  final int year;
  final String yearName;
  final String overview, career, money, love, health, taiSuiNote;
  final List<String> dos, avoids, luckyMonths;

  YearTemplate copyWith({List<String>? luckyMonths}) => YearTemplate(
    year: year,
    yearName: yearName,
    overview: overview,
    career: career,
    money: money,
    love: love,
    health: health,
    dos: dos,
    avoids: avoids,
    luckyMonths: luckyMonths ?? this.luckyMonths,
    taiSuiNote: taiSuiNote,
  );
}

class MonthTemplate {
  const MonthTemplate({
    required this.en,
    required this.zh,
    required this.theme,
    required this.dos,
    required this.avoids,
    required this.focus,
  });
  final String en, zh, theme;
  final List<String> dos, avoids;
  final Map<String, String> focus;
}

class AppContent {
  const AppContent({
    required this.forecast,
    required this.crystals,
    required this.rituals,
  });
  final Map<String, Object?> forecast;
  final List<CrystalItem> crystals;
  final List<RitualItem> rituals;

  factory AppContent.fromJson({
    required Map<String, Object?> forecast,
    required Map<String, Object?> crystals,
    required Map<String, Object?> rituals,
  }) => AppContent(
    forecast: forecast,
    crystals: [
      for (final c in crystals['crystals']! as List)
        CrystalItem.fromJson(c as Map<String, Object?>),
    ],
    rituals: [
      for (final r in rituals['rituals']! as List)
        RitualItem.fromJson(r as Map<String, Object?>),
    ],
  );

  static List<String> _strs(Object? l) => [
    for (final x in (l as List? ?? const [])) '$x',
  ];

  /// Yearly template for an animal ("horse"), or null if the year is not written yet.
  YearTemplate? year(int year, String animal) {
    final y = (forecast['yearly'] as Map?)?['$year'] as Map?;
    final a = (y?['animals'] as Map?)?[animal.toLowerCase()] as Map?;
    if (y == null || a == null) return null;
    return YearTemplate(
      year: year,
      yearName: '${y['zh']} ${y['en']}',
      overview: '${a['overview']}',
      career: '${a['career']}',
      money: '${a['money']}',
      love: '${a['love']}',
      health: '${a['health_wellbeing']}',
      dos: _strs(a['dos']),
      avoids: _strs(a['avoids']),
      luckyMonths: _strs(a['lucky_months']),
      taiSuiNote: '${a['tai_sui_note']}',
    );
  }

  /// Month template by solar month index (0 = 寅 Tiger month from Li Chun).
  MonthTemplate? month(int solarMonthIndex) {
    final list = forecast['monthly'] as List?;
    if (list == null || solarMonthIndex < 0 || solarMonthIndex >= list.length)
      return null;
    final m = list[solarMonthIndex] as Map;
    return MonthTemplate(
      en: '${m['en']}',
      zh: '${m['zh']}',
      theme: '${m['theme']}',
      dos: _strs(m['dos']),
      avoids: _strs(m['avoids']),
      focus: {
        for (final e in (m['focus'] as Map? ?? const {}).entries)
          '${e.key}': '${e.value}',
      },
    );
  }

  /// Daily headline/body for a score, with placeholders filled.
  (String, String) daily(int score, int seed, Map<String, String> fill) {
    final bands =
        (forecast['daily'] as Map?)?['by_score_band'] as Map? ?? const {};
    Map? band;
    for (final b in bands.values) {
      final r = (b as Map)['range'] as List;
      if (score >= (r[0] as num) && score <= (r[1] as num)) band = b;
    }
    if (band == null) return ('Today', '');
    String pick(String k) {
      final l = _strs(band![k]);
      if (l.isEmpty) return '';
      var s = l[seed % l.length];
      for (final e in fill.entries) {
        s = s.replaceAll('{${e.key}}', e.value);
      }
      return s;
    }

    return (pick('headlines'), pick('bodies'));
  }

  /// Day officer text (建除) by index 0..11.
  (String, String)? officer(int index) {
    final l = (forecast['daily'] as Map?)?['day_officers'] as List?;
    if (l == null || index >= l.length) return null;
    final o = l[index] as Map;
    return ('${o['zh']} ${o['en']}', '${o['meaning']}');
  }

  /// "moving_house" -> "Moving house" (from activity_tags when present).
  String activityLabel(String tag) {
    final t =
        ((forecast['daily'] as Map?)?['activity_tags'] as Map?)?[tag] as Map?;
    if (t != null) return '${t['label']}';
    final w = tag.replaceAll('_', ' ');
    return w.isEmpty ? w : w[0].toUpperCase() + w.substring(1);
  }
}
