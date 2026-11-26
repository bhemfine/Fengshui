import 'package:inkstone_engine/inkstone_engine.dart';
import 'package:test/test.dart';

void main() {
  test('cardinal bearings on the equator and meridian', () {
    expect(initialBearingDegrees(0, 0, 1, 0), closeTo(0, 1e-9));
    expect(initialBearingDegrees(0, 0, 0, 1), closeTo(90, 1e-9));
    expect(initialBearingDegrees(0, 0, -1, 0), closeTo(180, 1e-9));
    expect(initialBearingDegrees(0, 0, 0, -1), closeTo(270, 1e-9));
    expect(initialBearingDegrees(1.3, 103.8, 1.3, 103.8), isNull);
  });

  // Reference azimuths from the WGS84 geodesic (GeographicLib); the spherical
  // formula used on the phone agrees to within 0.3°.
  const cases = <(double, double, double, double, double, double)>[
    (51.5074, -0.1278, 48.8566, 2.3522, 148.046, 343923), // London -> Paris
    (1.3521, 103.8198, 1.2903, 103.8520, 152.327, 7716), // SG centre -> Marina Bay
    (1.3456, 103.9536, 1.3470, 103.9520, 311.003, 236), // Tampines, short NW hop
    (1.3000, 103.8000, 1.3010, 103.8010, 45.185, 157), // ~NE
    (1.3000, 103.8000, 1.2990, 103.7990, 225.185, 157), // ~SW
  ];
  test('known coordinates', () {
    for (final (a, b, c, d, bearing, dist) in cases) {
      expect(initialBearingDegrees(a, b, c, d), closeTo(bearing, 0.3), reason: '$a,$b -> $c,$d');
      expect(distanceMeters(a, b, c, d), closeTo(dist, dist * 0.005 + 1));
    }
  });

  test('destination point round-trips the bearing', () {
    for (final br in [0.0, 37.5, 142.0, 225.0, 322.0]) {
      final (lat, lon) = destinationPoint(1.3456, 103.9536, br, 40);
      expect(initialBearingDegrees(1.3456, 103.9536, lat, lon), closeTo(br, 1e-6));
      expect(distanceMeters(1.3456, 103.9536, lat, lon), closeTo(40, 1e-6));
    }
  });

  test('map bearing feeds facing: 8 directions, mountain, line flag', () {
    final b = initialBearingDegrees(1.3000, 103.8000, 1.2990, 103.7990)!;
    final f = facingFromDegrees(b);
    expect(f.direction, Direction.sw);
    expect(f.mountain.pinyin, 'Kun');
    expect(f.isLineFacing, isFalse);
  });
}
