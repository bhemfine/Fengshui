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

/// Everything the result screen needs. Held in memory only, never stored.
class QuickCheckInput {
  const QuickCheckInput({
    required this.type,
    required this.completionYear,
    this.beforeLiChun,
    required this.method,
    required this.facings,
    required this.people,
    this.example = false,
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
  people: savedProfiles,
  example: true,
);
