import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:inkstone_engine/inkstone_engine.dart';

import 'local_store.dart';

/// A person for the quick check: a saved profile or a quick entry.
/// Quick entries live only in memory for the current check.
class KuaPerson {
  const KuaPerson({
    required this.name,
    required this.birth,
    required this.gender,
    this.saved = false,
    this.example = false,
    this.timeKnown = true,
  });

  final String name;
  final DateTime birth;
  final Gender gender;
  final bool saved;
  final bool example;
  final bool timeKnown;

  KuaResult get kua => computeKua(
    timeKnown ? birth : DateTime(birth.year, birth.month, birth.day, 12),
    gender,
  );

  /// Birth falls on or next to Li Chun day, where an unknown time matters.
  bool get nearLiChun => birth.month == 2 && birth.day >= 3 && birth.day <= 5;

  KuaPerson copyWith({
    String? name,
    DateTime? birth,
    Gender? gender,
    bool? saved,
    bool? example,
    bool? timeKnown,
  }) => KuaPerson(
    name: name ?? this.name,
    birth: birth ?? this.birth,
    gender: gender ?? this.gender,
    saved: saved ?? this.saved,
    example: example ?? this.example,
    timeKnown: timeKnown ?? this.timeKnown,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'birth': birth.toIso8601String(),
    'gender': gender.name,
    'saved': saved,
    'example': example,
    'timeKnown': timeKnown,
  };

  factory KuaPerson.fromJson(Map<String, Object?> m) {
    final genderName = '${m['gender'] ?? ''}';
    final gender = Gender.values.firstWhere(
      (g) => g.name == genderName,
      orElse: () => Gender.male,
    );
    return KuaPerson(
      name: '${m['name'] ?? ''}',
      birth: DateTime.tryParse('${m['birth']}') ?? defaultMainUser.birth,
      gender: gender,
      saved: m['saved'] == true,
      example: m['example'] == true,
      timeKnown: m['timeKnown'] == true,
    );
  }
}

/// Shipped default: the main user ("You") on every screen.
final defaultMainUser = KuaPerson(
  name: 'Chua Boon Eng',
  birth: DateTime(1990, 6, 26, 12),
  gender: Gender.male,
  saved: true,
  example: true,
  timeKnown: false,
);

/// Shipped default: the partner in compatibility, Your year and the quick check.
final defaultPartner = KuaPerson(
  name: 'Chou Jiahui Victoria',
  birth: DateTime(1991, 10, 28, 12),
  gender: Gender.female,
  saved: true,
  example: true,
  timeKnown: false,
);

const householdKey = 'household.profiles.v1';

/// The two household profiles. Starts as the shipped couple; Save on the
/// birth screen writes a new main user; Delete my data restores the defaults.
final household = ValueNotifier<List<KuaPerson>>([
  defaultMainUser,
  defaultPartner,
]);

/// Saved household profiles (main user first, partner second).
List<KuaPerson> get savedProfiles => household.value;

KuaPerson profileNamed(String name) =>
    savedProfiles.firstWhere((p) => p.name == name);

/// The main user ("me") on every screen.
KuaPerson get mainUser =>
    savedProfiles.isNotEmpty ? savedProfiles.first : defaultMainUser;

/// The partner (person 2 in compatibility and the quick check).
KuaPerson get partner =>
    savedProfiles.length > 1 ? savedProfiles[1] : defaultPartner;

String dirs(Iterable<DirectionInfo> list) =>
    list.map((d) => directionShort[d.direction]).join(', ');

String genderLabel(Gender g) => g == Gender.male ? 'Male' : 'Female';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "26 Jun 1990" (plus the time when it is known).
String birthLabel(KuaPerson p) =>
    '${p.birth.day} ${_months[p.birth.month - 1]} ${p.birth.year}${p.timeKnown ? ', ${p.birth.hour.toString().padLeft(2, '0')}:${p.birth.minute.toString().padLeft(2, '0')}' : ''}';

/// Short given name used on screens ("Boon Eng", "Jiahui").
String shortName(KuaPerson p) => switch (p.name) {
  'Chua Boon Eng' => 'Boon Eng',
  'Chou Jiahui Victoria' => 'Jiahui',
  _ => p.name,
};

bool _samePerson(KuaPerson a, KuaPerson b) =>
    a.name == b.name &&
    a.gender == b.gender &&
    a.timeKnown == b.timeKnown &&
    a.birth.year == b.birth.year &&
    a.birth.month == b.birth.month &&
    a.birth.day == b.birth.day &&
    (!a.timeKnown ||
        (a.birth.hour == b.birth.hour && a.birth.minute == b.birth.minute));

Future<void> _persistHousehold() async {
  final encoded = jsonEncode([for (final p in household.value) p.toJson()]);
  await LocalStore.instance.saveString(householdKey, encoded);
}

/// Replace the main user, keep the partner, and save both on the phone.
Future<void> setMainUser(KuaPerson person) async {
  household.value = [person, partner];
  await _persistHousehold();
}

/// Load any saved household, or keep the shipped Boon Eng / Jiahui defaults.
Future<void> bootstrapHousehold() async {
  final raw = await LocalStore.instance.loadString(householdKey);
  if (raw == null || raw.isEmpty) {
    household.value = [defaultMainUser, defaultPartner];
    return;
  }
  try {
    final list = jsonDecode(raw) as List;
    final people = <KuaPerson>[
      for (final x in list)
        if (x is Map) KuaPerson.fromJson(Map<String, Object?>.from(x)),
    ];
    if (people.isEmpty) {
      household.value = [defaultMainUser, defaultPartner];
      return;
    }
    if (people.length == 1) people.add(defaultPartner);
    household.value = people;
  } catch (_) {
    household.value = [defaultMainUser, defaultPartner];
  }
}

/// Restore the shipped couple in memory. Call after wiping prefs.
void resetHouseholdDefaults() {
  household.value = [defaultMainUser, defaultPartner];
}

/// True when the main user is still the shipped Boon Eng example.
bool get mainUserIsDefault => _samePerson(mainUser, defaultMainUser);
