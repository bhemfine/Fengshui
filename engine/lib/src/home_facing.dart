import 'dart:math' as math;

import 'flying_stars.dart';
import 'models.dart';
import 'solar_terms.dart';

// Quick check (PLAN.md Module 3): facing, 24 Mountains, period, couple match,
// and the compass maths used by the direction calculator. Pure Dart, offline.

/// The eight compass directions in clockwise order from north.
const List<Direction> compassDirections = [
  Direction.n,
  Direction.ne,
  Direction.e,
  Direction.se,
  Direction.s,
  Direction.sw,
  Direction.w,
  Direction.nw,
];

const Map<Direction, String> directionShort = {
  Direction.n: 'N',
  Direction.ne: 'NE',
  Direction.e: 'E',
  Direction.se: 'SE',
  Direction.s: 'S',
  Direction.sw: 'SW',
  Direction.w: 'W',
  Direction.nw: 'NW',
  Direction.centre: 'Centre',
};

const Map<Direction, String> directionLong = {
  Direction.n: 'North',
  Direction.ne: 'North-east',
  Direction.e: 'East',
  Direction.se: 'South-east',
  Direction.s: 'South',
  Direction.sw: 'South-west',
  Direction.w: 'West',
  Direction.nw: 'North-west',
  Direction.centre: 'Centre',
};

/// Centre bearing of each of the eight directions.
double directionCentreDegrees(Direction d) {
  final i = compassDirections.indexOf(d);
  if (i < 0) throw ArgumentError.value(d, 'd', 'centre has no bearing');
  return i * 45.0;
}

/// Normalises any bearing to [0, 360).
double normaliseDegrees(double deg) {
  final r = deg % 360.0;
  return r < 0 ? r + 360.0 : r;
}

/// 337.5°–22.5° is N, then every 45°.
Direction directionAt(double degrees) {
  final d = normaliseDegrees(degrees);
  return compassDirections[(((d + 22.5) % 360.0) ~/ 45).toInt() % 8];
}

/// Degrees a bearing must be within of a boundary to count as a "line" facing.
const double lineFacingToleranceDegrees = 3.0;

/// A facing bearing resolved to direction and mountain, with line-facing flags.
class FacingReading {
  const FacingReading({
    required this.degrees,
    required this.direction,
    required this.mountain,
    required this.distanceToMountainBoundary,
    required this.distanceToDirectionBoundary,
  });

  final double degrees;
  final Direction direction;
  final Mountain mountain;

  /// Degrees to the nearest 15° mountain boundary.
  final double distanceToMountainBoundary;

  /// Degrees to the nearest 45° direction boundary (22.5°, 67.5°, ...).
  final double distanceToDirectionBoundary;

  /// Within 3° of any mountain boundary: ask the user to re-check.
  bool get isLineFacing => distanceToMountainBoundary <= lineFacingToleranceDegrees;

  /// Line facing that also sits between two of the eight directions
  /// (classically the more serious "empty line", 空亡 Kong Wang).
  bool get isDirectionLine => distanceToDirectionBoundary <= lineFacingToleranceDegrees;

  String get label =>
      '${directionLong[direction]} · ${degrees.toStringAsFixed(0)}° · ${mountain.chinese} ${mountain.pinyin}';

  Map<String, Object?> toJson() => {
    'degrees': degrees,
    'direction': direction.name,
    'mountain': mountain.pinyin,
    'mountainIndex': mountain.index,
    'lineFacing': isLineFacing,
    'directionLine': isDirectionLine,
  };
}

FacingReading facingFromDegrees(double degrees) {
  final d = normaliseDegrees(degrees);
  // Mountain boundaries are at 7.5° + 15k; direction boundaries at 22.5° + 45k.
  final m = (d - 7.5) % 15.0;
  final toMountain = math.min(m, 15.0 - m);
  final q = (d - 22.5) % 45.0;
  final toDirection = math.min(q, 45.0 - q);
  return FacingReading(
    degrees: d,
    direction: directionAt(d),
    mountain: mountainAt(d),
    distanceToMountainBoundary: toMountain,
    distanceToDirectionBoundary: toDirection,
  );
}

/// Facing from a picked direction (its centre bearing, never a line facing).
FacingReading facingFromDirection(Direction d) => facingFromDegrees(directionCentreDegrees(d));

// ---------------------------------------------------------------------------
// Period from completion / TOP year.

class PeriodResult {
  const PeriodResult({required this.period, required this.solarYear, required this.ambiguous});

  /// Flying Star period (8 or 9 for most Singapore homes).
  final int period;

  /// Li Chun-adjusted year used.
  final int solarYear;

  /// True when only a year was given and that year starts a new period
  /// (2004, 2024, 2044...): completion before Li Chun belongs to the previous
  /// period, so the app should ask.
  final bool ambiguous;
}

/// Li Chun (立春) instant in UTC for [year].
DateTime liChunUtc(int year) => solarTermUtc(year, 0);

/// Period for a building completed in [year] (optionally [month]/[day], local SG time).
///
/// Period 8: Li Chun 2004 to just before Li Chun 2024. Period 9: Li Chun 2024
/// to just before Li Chun 2044. The year flips at Li Chun, not 1 January.
PeriodResult periodForCompletion(int year, {int? month, int? day, double utcOffsetHours = 8.0}) {
  if (month != null) {
    final local = DateTime.utc(year, month, day ?? 15, 12);
    final utc = local.subtract(Duration(minutes: (utcOffsetHours * 60).round()));
    final y = liChunYear(utc);
    return PeriodResult(period: periodForYear(y), solarYear: y, ambiguous: false);
  }
  final startsPeriod = (year - 1864) % 20 == 0;
  return PeriodResult(period: periodForYear(year), solarYear: year, ambiguous: startsPeriod);
}

// ---------------------------------------------------------------------------
// Couple match.

enum FacingFit { goodForAll, goodForSome, goodForNone }

class PersonFacingFit {
  const PersonFacingFit({required this.name, required this.kua, required this.info});
  final String name;
  final KuaResult kua;

  /// Which of the 8 mansions the facing is for this person.
  final DirectionInfo info;

  bool get good => info.lucky;
}

class FacingMatch {
  const FacingMatch({required this.facing, required this.people});
  final Direction facing;
  final List<PersonFacingFit> people;

  FacingFit get fit {
    final good = people.where((p) => p.good).length;
    if (good == people.length) return FacingFit.goodForAll;
    if (good == 0) return FacingFit.goodForNone;
    return FacingFit.goodForSome;
  }

  /// Plain-English verdict (PLAN.md Module 3, step 4).
  String get verdict {
    if (people.length == 1) {
      return people.first.good
          ? 'Good facing for ${people.first.name}'
          : 'Not one of ${people.first.name}\'s good directions';
    }
    switch (fit) {
      case FacingFit.goodForAll:
        return 'Good for both: strong fit';
      case FacingFit.goodForSome:
        final who = people.where((p) => p.good).map((p) => p.name).join(' and ');
        return 'Suits $who only: use bed and desk directions and cures for the other';
      case FacingFit.goodForNone:
        return 'Not good for either: weak fit, see cures and compare other units';
    }
  }
}

/// Matches a home facing against one or more people's Kua.
FacingMatch matchFacing(Direction facing, List<(String, KuaResult)> people) {
  if (facing == Direction.centre) throw ArgumentError('facing cannot be centre');
  return FacingMatch(
    facing: facing,
    people: [
      for (final (name, k) in people)
        PersonFacingFit(
          name: name,
          kua: k,
          info: k.directions.firstWhere((d) => d.direction == facing),
        ),
    ],
  );
}

/// Directions good for everyone in [kuas] (for shared beds, desks, doors).
List<Direction> sharedGoodDirections(List<KuaResult> kuas) => [
  for (final d in compassDirections)
    if (kuas.every((k) => k.lucky.any((x) => x.direction == d))) d,
];

// ---------------------------------------------------------------------------
// Compass maths (Android sensor axes: x right, y to top of screen, z out of screen).

/// Singapore magnetic declination (true = magnetic + declination). Approx.
/// +0.1° (WMM2025); kept as a constant because it is so small locally.
const double singaporeDeclinationDegrees = 0.1;

/// Tilt-compensated heading of the phone's top edge, in degrees from
/// magnetic north, from accelerometer (with gravity) and magnetometer readings.
/// Same maths as Android's SensorManager.getRotationMatrix/getOrientation.
/// Returns null if the readings are degenerate (free fall or no field).
double? compassHeading(double ax, double ay, double az, double mx, double my, double mz) {
  var hx = my * az - mz * ay;
  var hy = mz * ax - mx * az;
  var hz = mx * ay - my * ax;
  final normH = math.sqrt(hx * hx + hy * hy + hz * hz);
  final normA = math.sqrt(ax * ax + ay * ay + az * az);
  if (normH < 0.1 || normA < 0.1) return null;
  hx /= normH;
  hy /= normH;
  hz /= normH;
  final gx = ax / normA, gz = az / normA;
  final my2 = gz * hx - gx * hz;
  final heading = math.atan2(hy, my2) * 180.0 / math.pi;
  return normaliseDegrees(heading);
}

/// Degrees the phone is tilted away from lying flat.
double tiltDegrees(double ax, double ay, double az) {
  final n = math.sqrt(ax * ax + ay * ay + az * az);
  if (n == 0) return 90;
  return math.acos((az / n).clamp(-1.0, 1.0)) * 180.0 / math.pi;
}

/// Magnetic field strength in microtesla.
double fieldStrength(double mx, double my, double mz) => math.sqrt(mx * mx + my * my + mz * mz);

/// Warn above this tilt.
const double maxTiltDegrees = 10.0;

/// Earth's field in Singapore is about 41 µT; outside this band suggests
/// interference from steel, grilles, speakers or electronics.
const double minFieldMicroTesla = 25.0;
const double maxFieldMicroTesla = 65.0;

bool isInterference(double microTesla) =>
    microTesla < minFieldMicroTesla || microTesla > maxFieldMicroTesla;

/// Circular mean of bearings (so 359° and 1° average to 0°, not 180°).
double circularMeanDegrees(List<double> bearings) {
  if (bearings.isEmpty) throw ArgumentError('no bearings');
  var s = 0.0, c = 0.0;
  for (final b in bearings) {
    s += math.sin(b * math.pi / 180.0);
    c += math.cos(b * math.pi / 180.0);
  }
  return normaliseDegrees(math.atan2(s, c) * 180.0 / math.pi);
}

/// Largest angular gap between any reading and the mean (spread check).
double maxDeviationDegrees(List<double> bearings) {
  final m = circularMeanDegrees(bearings);
  var worst = 0.0;
  for (final b in bearings) {
    final d = (normaliseDegrees(b - m + 180.0) - 180.0).abs();
    if (d > worst) worst = d;
  }
  return worst;
}

/// Magnetic compass bearing to true bearing.
double magneticToTrue(double magnetic, {double declination = singaporeDeclinationDegrees}) =>
    normaliseDegrees(magnetic + declination);
