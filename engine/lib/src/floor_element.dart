import 'models.dart';

/// Last-digit "floor element" used in popular Singapore property marketing
/// (He Tu number–element pairings). This is folk practice, not classical
/// Flying Stars, and is labelled as such in the app.
///
/// Last digits: 1/6 Water, 2/7 Fire, 3/8 Wood, 4/9 Metal, 5/0 Earth.
FiveElement floorElementForDigit(int digit) {
  switch (digit.abs() % 10) {
    case 1:
    case 6:
      return FiveElement.water;
    case 2:
    case 7:
      return FiveElement.fire;
    case 3:
    case 8:
      return FiveElement.wood;
    case 4:
    case 9:
      return FiveElement.metal;
    default:
      return FiveElement.earth; // 5 or 0
  }
}

/// Pulls the first integer from a floor string such as "12", "12th" or "level 12".
int? parseFloorNumber(String? raw) {
  if (raw == null) return null;
  final m = RegExp(r'(\d+)').firstMatch(raw.trim());
  if (m == null) return null;
  return int.tryParse(m.group(1)!);
}

/// How the floor's popular element sits against the person's lucky elements.
enum FloorElementFit { favourable, unfavourable, mixed, unknown }

class FloorElementNote {
  const FloorElementNote({
    required this.floor,
    required this.lastDigit,
    required this.element,
    required this.fit,
    required this.body,
  });

  final int? floor;
  final int? lastDigit;
  final FiveElement? element;
  final FloorElementFit fit;
  final String body;

  /// Always shown with the note so it is not mistaken for Flying Stars.
  static const disclaimer =
      'Popular belief, not classical Flying Stars. Some Singapore listings pair the last digit of the floor with a He Tu element.';
}

/// Builds the floor-element note for a person (or a couple, if [partnerFavourable]
/// is passed).
FloorElementNote floorElementNote({
  String? floorRaw,
  int? floorNumber,
  List<FiveElement> favourable = const [],
  List<FiveElement> unfavourable = const [],
  List<FiveElement> partnerFavourable = const [],
}) {
  final floor = floorNumber ?? parseFloorNumber(floorRaw);
  if (floor == null) {
    return const FloorElementNote(
      floor: null,
      lastDigit: null,
      element: null,
      fit: FloorElementFit.unknown,
      body: 'Enter the floor number to see the popular floor-element note.',
    );
  }
  final digit = floor.abs() % 10;
  final el = floorElementForDigit(digit);
  final mineGood = favourable.contains(el);
  final mineBad = unfavourable.contains(el);
  final partnerGood = partnerFavourable.isEmpty ? null : partnerFavourable.contains(el);

  FloorElementFit fit;
  final buf = StringBuffer(
    'Floor $floor ends in $digit, which popular practice reads as ${el.english} (${el.chinese}). ',
  );
  if (favourable.isEmpty && unfavourable.isEmpty) {
    fit = FloorElementFit.unknown;
    buf.write('Add a birth profile to compare it with lucky elements.');
  } else if (partnerGood != null) {
    if (mineGood && partnerGood) {
      fit = FloorElementFit.favourable;
      buf.write('That element is lucky for both of you in this reading.');
    } else if (mineBad && partnerGood == false) {
      fit = FloorElementFit.unfavourable;
      buf.write('That element is not in either of your lucky lists.');
    } else {
      fit = FloorElementFit.mixed;
      if (mineGood && partnerGood == false) {
        buf.write('Lucky for the main person, less so for the partner.');
      } else if (!mineGood && partnerGood) {
        buf.write('Lucky for the partner, less so for the main person.');
      } else {
        buf.write('A mixed fit against your lucky elements.');
      }
    }
  } else if (mineGood) {
    fit = FloorElementFit.favourable;
    buf.write('That sits in your lucky elements.');
  } else if (mineBad) {
    fit = FloorElementFit.unfavourable;
    buf.write('That is not in your lucky elements for this reading.');
  } else {
    fit = FloorElementFit.mixed;
    buf.write('A neutral fit against your lucky elements.');
  }

  return FloorElementNote(
    floor: floor,
    lastDigit: digit,
    element: el,
    fit: fit,
    body: buf.toString(),
  );
}
