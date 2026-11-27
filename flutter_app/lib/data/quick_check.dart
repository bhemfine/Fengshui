import 'package:inkstone_engine/inkstone_engine.dart';

import 'household.dart';

/// Where the facing is read from. HDB asks; "unsure" shows both.
enum FacingMethod { mainDoor, balcony, block, unsure }

const facingMethodLabel = {
  FacingMethod.mainDoor: 'Main door',
  FacingMethod.balcony: 'Balcony or living-room opening',
  FacingMethod.block: 'Block facing',
  FacingMethod.unsure: 'Not sure, show both',
};

/// Everything the result screen needs. The form itself is in memory; tapping through saves the home via useAsCurrentHome.
class QuickCheckInput {
  const QuickCheckInput({
    required this.type,
    required this.completionYear,
    this.beforeLiChun,
    required this.method,
    required this.facings,
    required this.people,
    this.example = false,
    this.home,
  });

  final PropertyType type;
  final int completionYear;

  /// Only asked when the completion year starts a new period (e.g. 2024).
  final bool? beforeLiChun;
  final FacingMethod method;

  /// One bearing per method read (two when the method is "unsure").
  final Map<FacingMethod, double> facings;
  final List<KuaPerson> people;
  final bool example;

  /// Address details typed in or imported from a listing. Saved with the current home when the result is applied.
  final HomeDetails? home;

  PeriodResult get period => beforeLiChun == null
      ? periodForCompletion(completionYear)
      : periodForCompletion(completionYear, month: beforeLiChun! ? 1 : 3);
}

/// Methods whose facing the user must enter.
List<FacingMethod> methodsToRead(FacingMethod m) =>
    m == FacingMethod.unsure ? const [FacingMethod.mainDoor, FacingMethod.balcony] : [m];

final exampleQuickCheck = QuickCheckInput(
  type: PropertyType.hdb,
  completionYear: 2012,
  method: FacingMethod.unsure,
  facings: const {FacingMethod.mainDoor: 142, FacingMethod.balcony: 322},
  people: [mainUser, partner],
  example: true,
);

/// Home details for the quick check, typed in or imported from a listing.
class HomeDetails {
  const HomeDetails({
    this.address,
    this.postalCode,
    this.floor,
    this.unit,
    this.lat,
    this.lng,
    this.source,
  });
  final String? address;
  final String? postalCode;

  /// Storey number or words ("12", "High", "1 to 5").
  final String? floor;
  final String? unit;
  final double? lat;
  final double? lng;

  /// e.g. "PropertyGuru listing 500236540".
  final String? source;

  bool get isEmpty => [address, postalCode, floor, unit].every((s) => s == null || s.trim().isEmpty);

  String get summary => [
        if (address != null && address!.isNotEmpty) address!,
        if (postalCode != null && postalCode!.isNotEmpty) 'Singapore $postalCode',
        if (floor != null && floor!.isNotEmpty) 'Floor $floor',
        if (unit != null && unit!.isNotEmpty && !(address ?? '').contains(unit!)) unit!,
      ].join(' · ');
}

/// What the quick check is pre-filled with (from a listing import).
/// The facing is never pre-filled: [facingHint] is only shown as a hint.
class QuickCheckPrefill {
  const QuickCheckPrefill({this.type, this.completionYear, this.completionApprox = false, this.home, this.facingHint});
  final PropertyType? type;
  final int? completionYear;
  final bool completionApprox;
  final HomeDetails? home;
  final String? facingHint;
}
