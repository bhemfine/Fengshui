import 'models.dart';

/// Compass mid-points of the eight palaces, in degrees from North, clockwise.
const Map<Direction, double> palaceDegrees = {
  Direction.n: 0,
  Direction.ne: 45,
  Direction.e: 90,
  Direction.se: 135,
  Direction.s: 180,
  Direction.sw: 225,
  Direction.w: 270,
  Direction.nw: 315,
  Direction.centre: 0,
};

/// Snap a bearing to the nearest of the eight palaces (45° sectors).
Direction nearestPalace(double degrees) {
  final d = ((degrees % 360) + 360) % 360;
  const order = [
    Direction.n,
    Direction.ne,
    Direction.e,
    Direction.se,
    Direction.s,
    Direction.sw,
    Direction.w,
    Direction.nw,
  ];
  return order[((d + 22.5) / 45).floor() % 8];
}

/// Row and column (0–2) of a palace on a 3×3 plan, with the home's facing
/// palace at the **bottom centre**. The sitting (opposite) palace is at the
/// top. The person looking out the front has their right on the right of the
/// screen, which is [facing] + 90°.
///
/// Facings are snapped to eight directions — a 3×3 grid cannot rotate by 45°
/// as a simple 90° permutation.
({int row, int col}) palaceCell(Direction palace, Direction facing) {
  if (palace == Direction.centre || facing == Direction.centre) {
    return (row: 1, col: 1);
  }
  final rel = (palaceDegrees[palace]! - palaceDegrees[facing]! + 360) % 360;
  // rel 0 = facing (bottom), 90 = right, 180 = sitting (top), 270 = left.
  const cells = <int, (int, int)>{
    0: (2, 1),
    45: (2, 2),
    90: (1, 2),
    135: (0, 2),
    180: (0, 1),
    225: (0, 0),
    270: (1, 0),
    315: (2, 0),
  };
  final pair = cells[rel.round()];
  if (pair == null) {
    throw StateError('Unexpected palace angle $rel for $palace facing $facing');
  }
  return (row: pair.$1, col: pair.$2);
}

/// The nine palaces in row-major order for a facing (including the centre).
List<Direction> palacesInGridOrder(Direction facing) {
  final out = List<Direction>.filled(9, Direction.centre);
  for (final d in Direction.values) {
    final c = palaceCell(d, facing);
    out[c.row * 3 + c.col] = d;
  }
  return out;
}
