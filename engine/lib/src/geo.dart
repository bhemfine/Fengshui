import 'dart:math' as math;

// Map-bearing maths for the direction calculator (pure Dart, on the phone).

const double earthRadiusMeters = 6371008.8;

double _rad(double d) => d * math.pi / 180.0;
double _deg(double r) => r * 180.0 / math.pi;

/// Initial great-circle bearing from point 1 to point 2, degrees clockwise from
/// true north in [0, 360). Returns null if the points are the same.
double? initialBearingDegrees(double lat1, double lon1, double lat2, double lon2) {
  if (lat1 == lat2 && lon1 == lon2) return null;
  final p1 = _rad(lat1), p2 = _rad(lat2), dl = _rad(lon2 - lon1);
  final y = math.sin(dl) * math.cos(p2);
  final x = math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl);
  final b = _deg(math.atan2(y, x)) % 360.0;
  return b < 0 ? b + 360.0 : b;
}

/// Haversine distance in metres.
double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
  final p1 = _rad(lat1), p2 = _rad(lat2);
  final dp = p2 - p1, dl = _rad(lon2 - lon1);
  final a = math.sin(dp / 2) * math.sin(dp / 2) +
      math.cos(p1) * math.cos(p2) * math.sin(dl / 2) * math.sin(dl / 2);
  return 2 * earthRadiusMeters * math.asin(math.min(1.0, math.sqrt(a)));
}

/// Point reached from (lat, lon) travelling [meters] on initial [bearing].
(double, double) destinationPoint(double lat, double lon, double bearing, double meters) {
  final d = meters / earthRadiusMeters;
  final p1 = _rad(lat), l1 = _rad(lon), b = _rad(bearing);
  final p2 = math.asin(math.sin(p1) * math.cos(d) + math.cos(p1) * math.sin(d) * math.cos(b));
  final l2 = l1 +
      math.atan2(math.sin(b) * math.sin(d) * math.cos(p1), math.cos(d) - math.sin(p1) * math.sin(p2));
  return (_deg(p2), ((_deg(l2) + 540) % 360) - 180);
}

/// Minimum distance between pin and facing point for a usable bearing.
const double minBearingDistanceMeters = 3.0;
