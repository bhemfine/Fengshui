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

/// Route extra when opening a quick-check result, optionally to update a draft.
class QuickCheckResultArgs {
  const QuickCheckResultArgs({required this.input, this.recordId});
  final QuickCheckInput input;

  /// Existing draft or result id to replace when the user saves.
  final String? recordId;
}

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

  Map<String, Object?> toJson() => {
    'type': type.name,
    'completionYear': completionYear,
    'beforeLiChun': beforeLiChun,
    'method': method.name,
    'facings': {for (final e in facings.entries) e.key.name: e.value},
    'people': [for (final p in people) p.toJson()],
    'example': example,
    'home': home?.toJson(),
  };

  factory QuickCheckInput.fromJson(Map<String, Object?> m) {
    var type = PropertyType.hdb;
    for (final t in PropertyType.values) {
      if (t.name == m['type']) type = t;
    }
    var method = FacingMethod.mainDoor;
    for (final f in FacingMethod.values) {
      if (f.name == m['method']) method = f;
    }
    final facings = <FacingMethod, double>{};
    final rawFacings = m['facings'];
    if (rawFacings is Map) {
      for (final e in rawFacings.entries) {
        for (final f in FacingMethod.values) {
          if (f.name == e.key) {
            facings[f] = (e.value as num).toDouble();
          }
        }
      }
    }
    final people = <KuaPerson>[];
    final rawPeople = m['people'];
    if (rawPeople is List) {
      for (final p in rawPeople) {
        if (p is Map) {
          people.add(KuaPerson.fromJson(Map<String, Object?>.from(p)));
        }
      }
    }
    HomeDetails? home;
    final rawHome = m['home'];
    if (rawHome is Map) {
      home = HomeDetails.fromJson(Map<String, Object?>.from(rawHome));
    }
    return QuickCheckInput(
      type: type,
      completionYear: (m['completionYear'] as num?)?.toInt() ?? 2000,
      beforeLiChun: m['beforeLiChun'] as bool?,
      method: method,
      facings: facings,
      people: people,
      example: m['example'] == true,
      home: home,
    );
  }
}

/// Methods whose facing the user must enter.
List<FacingMethod> methodsToRead(FacingMethod m) => m == FacingMethod.unsure
    ? const [FacingMethod.mainDoor, FacingMethod.balcony]
    : [m];

QuickCheckInput get exampleQuickCheck => QuickCheckInput(
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

  bool get isEmpty => [
    address,
    postalCode,
    floor,
    unit,
  ].every((s) => s == null || s.trim().isEmpty);

  String get summary => [
    if (address != null && address!.isNotEmpty) address!,
    if (postalCode != null && postalCode!.isNotEmpty) 'Singapore $postalCode',
    if (floor != null && floor!.isNotEmpty) 'Floor $floor',
    if (unit != null && unit!.isNotEmpty && !(address ?? '').contains(unit!))
      unit!,
  ].join(' · ');

  Map<String, Object?> toJson() => {
    'address': address,
    'postalCode': postalCode,
    'floor': floor,
    'unit': unit,
    'lat': lat,
    'lng': lng,
    'source': source,
  };

  factory HomeDetails.fromJson(Map<String, Object?> m) => HomeDetails(
    address: m['address'] as String?,
    postalCode: m['postalCode'] as String?,
    floor: m['floor'] as String?,
    unit: m['unit'] as String?,
    lat: (m['lat'] as num?)?.toDouble(),
    lng: (m['lng'] as num?)?.toDouble(),
    source: m['source'] as String?,
  );
}

/// What the quick check is pre-filled with (from a listing import).
/// The facing is never pre-filled: [facingHint] is only shown as a hint.
class QuickCheckPrefill {
  const QuickCheckPrefill({
    this.type,
    this.completionYear,
    this.completionApprox = false,
    this.home,
    this.facingHint,
    this.yearText,
    this.beforeLiChun,
    this.method,
    this.facings = const {},
    this.picked = const [],
  });
  final PropertyType? type;
  final int? completionYear;
  final bool completionApprox;
  final HomeDetails? home;
  final String? facingHint;

  /// Draft-only fields so an incomplete form can be restored.
  final String? yearText;
  final bool? beforeLiChun;
  final FacingMethod? method;
  final Map<FacingMethod, double> facings;
  final List<int> picked;

  Map<String, Object?> toJson() => {
    'type': type?.name,
    'completionYear': completionYear,
    'completionApprox': completionApprox,
    'home': home?.toJson(),
    'facingHint': facingHint,
    'yearText': yearText,
    'beforeLiChun': beforeLiChun,
    'method': method?.name,
    'facings': {for (final e in facings.entries) e.key.name: e.value},
    'picked': picked,
  };

  factory QuickCheckPrefill.fromJson(Map<String, Object?> m) {
    PropertyType? type;
    for (final t in PropertyType.values) {
      if (t.name == m['type']) type = t;
    }
    FacingMethod? method;
    for (final f in FacingMethod.values) {
      if (f.name == m['method']) method = f;
    }
    final facings = <FacingMethod, double>{};
    final rawFacings = m['facings'];
    if (rawFacings is Map) {
      for (final e in rawFacings.entries) {
        for (final f in FacingMethod.values) {
          if (f.name == e.key) {
            facings[f] = (e.value as num).toDouble();
          }
        }
      }
    }
    final picked = <int>[];
    final rawPicked = m['picked'];
    if (rawPicked is List) {
      for (final v in rawPicked) {
        if (v is num) picked.add(v.toInt());
      }
    }
    HomeDetails? home;
    final rawHome = m['home'];
    if (rawHome is Map) {
      home = HomeDetails.fromJson(Map<String, Object?>.from(rawHome));
    }
    return QuickCheckPrefill(
      type: type,
      completionYear: (m['completionYear'] as num?)?.toInt(),
      completionApprox: m['completionApprox'] == true,
      home: home,
      facingHint: m['facingHint'] as String?,
      yearText: m['yearText'] as String?,
      beforeLiChun: m['beforeLiChun'] as bool?,
      method: method,
      facings: facings,
      picked: picked,
    );
  }
}
