import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:inkstone_engine/inkstone_engine.dart';

import 'local_store.dart';
import 'quick_check.dart';
import 'sample_data.dart' show Palace;

/// The home the floor reading and house check use. Starts as an example
/// home; the quick check or floor-plan screen replaces it and saves it
/// on the phone (SharedPreferences, backup off).
class CurrentHome {
  const CurrentHome({
    required this.label,
    required this.facingDegrees,
    required this.completionYear,
    required this.period,
    this.example = false,
    this.address,
    this.postalCode,
    this.floor,
    this.unit,
    this.type,
    this.planRotationDeg = 0,
  });
  final String label;
  final double facingDegrees;
  final int completionYear;
  final int period;
  final bool example;
  final String? address;
  final String? postalCode;
  final String? floor;
  final String? unit;
  final PropertyType? type;

  /// Rotation of the saved plan photo so the front door sits at the bottom.
  final double planRotationDeg;

  FlyingStarChart get chart => natalChart(facingDegrees, period);
  FacingReading get facing => facingFromDegrees(facingDegrees);

  CurrentHome copyWith({
    String? label,
    double? facingDegrees,
    int? completionYear,
    int? period,
    bool? example,
    String? address,
    String? postalCode,
    String? floor,
    String? unit,
    PropertyType? type,
    double? planRotationDeg,
    bool clearAddress = false,
  }) => CurrentHome(
    label: label ?? this.label,
    facingDegrees: facingDegrees ?? this.facingDegrees,
    completionYear: completionYear ?? this.completionYear,
    period: period ?? this.period,
    example: example ?? this.example,
    address: clearAddress ? address : (address ?? this.address),
    postalCode: clearAddress ? postalCode : (postalCode ?? this.postalCode),
    floor: clearAddress ? floor : (floor ?? this.floor),
    unit: clearAddress ? unit : (unit ?? this.unit),
    type: type ?? this.type,
    planRotationDeg: planRotationDeg ?? this.planRotationDeg,
  );

  Map<String, Object?> toJson() => {
    'label': label,
    'facingDegrees': facingDegrees,
    'completionYear': completionYear,
    'period': period,
    'example': example,
    'address': address,
    'postalCode': postalCode,
    'floor': floor,
    'unit': unit,
    'type': type?.name,
    'planRotationDeg': planRotationDeg,
  };

  factory CurrentHome.fromJson(Map<String, Object?> m) {
    PropertyType? type;
    for (final t in PropertyType.values) {
      if (t.name == m['type']) type = t;
    }
    return CurrentHome(
      label: '${m['label'] ?? exampleHome.label}',
      facingDegrees:
          (m['facingDegrees'] as num?)?.toDouble() ?? exampleHome.facingDegrees,
      completionYear:
          (m['completionYear'] as num?)?.toInt() ?? exampleHome.completionYear,
      period: (m['period'] as num?)?.toInt() ?? exampleHome.period,
      example: m['example'] == true,
      address: m['address'] as String?,
      postalCode: m['postalCode'] as String?,
      floor: m['floor'] as String?,
      unit: m['unit'] as String?,
      type: type,
      planRotationDeg: (m['planRotationDeg'] as num?)?.toDouble() ?? 0,
    );
  }
}

const exampleHome = CurrentHome(
  label: 'Example 4-room HDB, Tampines',
  facingDegrees: 142,
  completionYear: 2012,
  period: 8,
  example: true,
);

final currentHome = ValueNotifier<CurrentHome>(exampleHome);

/// Grid order used by the plan widget: NW, N, NE, W, Centre, E, SW, S, SE.
const planGridOrder = [
  Direction.nw,
  Direction.n,
  Direction.ne,
  Direction.w,
  Direction.centre,
  Direction.e,
  Direction.sw,
  Direction.s,
  Direction.se,
];

/// Is [star] timely (current or next period star) for [period]?
bool isTimelyStar(int star, int period) =>
    star == period || star == period % 9 + 1;

/// Short rule-based tip for one palace of the natal chart.
String palaceTip(PalaceStars p, int period) {
  final m = p.mountain, w = p.facing;
  if (m == 5 || w == 5)
    return 'Five Yellow in the chart: keep this area quiet; avoid heavy use or knocking.';
  if (isTimelyStar(w, period) && isTimelyStar(m, period)) {
    return 'Both stars timely: strong area for the door, living room, desk or bed.';
  }
  if (isTimelyStar(w, period))
    return 'Timely water star $w: good for the door, living room or an active desk.';
  if (isTimelyStar(m, period))
    return 'Timely mountain star $m: good for a bed, a quiet room or tall furniture.';
  if (m == 2 || w == 2)
    return 'Two Black (illness star): keep it calm and tidy; avoid long sleep here.';
  if ({3, 7}.contains(m) || {3, 7}.contains(w))
    return 'Quarrel or loss star (3 or 7): keep it tidy; a calm room suits it.';
  return 'Ordinary area. Use it as you like and keep it clear.';
}

/// Engine stars for the plan widget, in [planGridOrder].
List<Palace> planPalaces(CurrentHome h) {
  final c = h.chart;
  return [
    for (final d in planGridOrder)
      Palace(
        direction: directionLong[d]!,
        mountain: c.palaces[d]!.mountain,
        water: c.palaces[d]!.facing,
        tip: palaceTip(c.palaces[d]!, c.period),
      ),
  ];
}

/// Rule-based placement tips from the chart and this year's afflictions.
List<(String, String, bool)> placementTips(CurrentHome h, int year) {
  final c = h.chart;
  final p = c.period;
  final ps = [
    for (final d in planGridOrder)
      if (d != Direction.centre) (d, c.palaces[d]!),
  ];
  int rank(int star) => star == p ? 2 : (star == p % 9 + 1 ? 1 : 0);
  final bestWater =
      (ps.toList()
            ..sort((a, b) => rank(b.$2.facing).compareTo(rank(a.$2.facing))))
          .first;
  final bestMountain =
      (ps.toList()..sort(
            (a, b) => rank(b.$2.mountain).compareTo(rank(a.$2.mountain)),
          ))
          .first;
  final fives = [
    for (final (d, s) in ps)
      if (s.mountain == 5 || s.facing == 5) d,
  ];
  final a = yearAfflictions(year);
  return [
    (
      directionLong[bestWater.$1]!,
      'water star ${bestWater.$2.facing}: living area, door side or desk.',
      true,
    ),
    (
      directionLong[bestMountain.$1]!,
      'mountain star ${bestMountain.$2.mountain}: bed head or a quiet room.',
      true,
    ),
    if (fives.isNotEmpty)
      (
        fives.map((d) => directionLong[d]!).join(', '),
        'Five Yellow in the chart: keep quiet.',
        false,
      ),
    (
      '$year renovation',
      'avoid starting works in the ${directionLong[a.taiSui]} (Tai Sui), ${directionLong[a.yearBreaker]} (Year Breaker), '
          '${directionLong[a.threeKillings]} (Three Killings) and ${directionLong[a.fiveYellow]} (Five Yellow).',
      false,
    ),
  ];
}

String directionShortLabel(CurrentHome h) =>
    directionShort[h.facing.direction]!;

/// Which of the year's afflictions sit in [d].
List<String> yearAfflictionsHits(Direction d, int year) {
  final a = yearAfflictions(year);
  return [
    if (a.taiSui == d) 'Tai Sui',
    if (a.yearBreaker == d) 'the Year Breaker',
    if (a.threeKillings == d) 'the Three Killings',
    if (a.fiveYellow == d) 'the Five Yellow',
  ];
}

/// A [CurrentHome] from a finished quick check. With two facings ("not sure"),
/// the main door reading is used.
CurrentHome currentHomeFromQuickCheck(QuickCheckInput q) {
  final deg = q.facings[FacingMethod.mainDoor] ?? q.facings.values.first;
  return CurrentHome(
    label: q.home?.summary.isNotEmpty == true
        ? q.home!.summary
        : propertyLabel[q.type]!,
    facingDegrees: deg,
    completionYear: q.completionYear,
    period: q.period.period,
    example: q.example,
    address: q.home?.address,
    postalCode: q.home?.postalCode,
    floor: q.home?.floor,
    unit: q.home?.unit,
    type: q.type,
  );
}

/// Apply a quick-check result as the current home and save it on the phone.
void useAsCurrentHome(QuickCheckInput q) {
  unawaited(setCurrentHome(currentHomeFromQuickCheck(q)));
}

/// Load the saved home at startup. Falls back to [exampleHome] if none is saved.
Future<void> bootstrapCurrentHome() async {
  final raw = await LocalStore.instance.loadString(currentHomeKey);
  if (raw == null || raw.isEmpty) return;
  try {
    currentHome.value = CurrentHome.fromJson(
      jsonDecode(raw) as Map<String, Object?>,
    );
  } catch (_) {
    // Keep the example home if the saved record is damaged.
  }
}

Future<void> setCurrentHome(CurrentHome home) async {
  currentHome.value = home;
  await LocalStore.instance.saveString(
    currentHomeKey,
    jsonEncode(home.toJson()),
  );
}

Future<void> clearCurrentHome() async {
  currentHome.value = exampleHome;
  await LocalStore.instance.remove(currentHomeKey);
}

const currentHomeKey = 'current_home.v1';
