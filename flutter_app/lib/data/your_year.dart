import 'package:inkstone_engine/inkstone_engine.dart';

import 'content_repo.dart';
import 'household.dart';

/// Everything the "Your year" screen shows for one person and one year. Offline.
class YourYear {
  YourYear._({
    required this.person,
    required this.year,
    required this.zodiac,
    required this.chart,
    required this.taiSui,
    required this.afflictions,
    required this.lucky,
    required this.template,
  });

  factory YourYear.compute(KuaPerson person, int year, AppContent? content) {
    final birth = person.timeKnown ? person.birth : DateTime(person.birth.year, person.birth.month, person.birth.day, 12);
    final z = zodiacForBirth(birth);
    final chart = computeBazi(birthLocal: person.birth, utcOffsetHours: 8, hourKnown: person.timeKnown);
    return YourYear._(
      person: person,
      year: year,
      zodiac: z,
      chart: chart,
      taiSui: taiSuiReading(z.branch.index, year),
      afflictions: yearAfflictions(year),
      lucky: luckyProfile(
        chart: chart,
        kua: person.kua,
        year: year,
        crystals: content?.crystals ?? const [],
        rituals: content?.rituals ?? const [],
      ),
      template: content?.year(year, z.animal),
    );
  }

  final KuaPerson person;
  final int year;
  final ZodiacYear zodiac;
  final BaziChart chart;
  final TaiSuiReading taiSui;
  final YearAfflictions afflictions;
  final LuckyProfile lucky;

  /// Null if the year's text is not written (only 2026 and 2027 ship).
  final YearTemplate? template;

  /// Template avoids first, then the rule-based ones.
  List<String> get allAvoids => [...?template?.avoids, ...lucky.avoids];
}

/// Years with written forecasts.
const forecastYears = [2026, 2027];

/// The Li Chun year for "today" in Singapore time.
int currentSolarYear([DateTime? now]) {
  final n = (now ?? DateTime.now()).toUtc();
  return liChunYear(n);
}

String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
