import 'package:inkstone_engine/inkstone_engine.dart';

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

  KuaResult get kua => computeKua(timeKnown ? birth : DateTime(birth.year, birth.month, birth.day, 12), gender);

  /// Birth falls on or next to Li Chun day, where an unknown time matters.
  bool get nearLiChun => birth.month == 2 && birth.day >= 3 && birth.day <= 5;
}

/// Saved household profiles (example data until local profiles ship).
final savedProfiles = <KuaPerson>[
  // Example couple supplied for testing (birth times unknown).
  KuaPerson(
      name: 'Chua Boon Eng',
      birth: DateTime(1990, 6, 26, 12),
      gender: Gender.male,
      saved: true,
      example: true,
      timeKnown: false),
  KuaPerson(
      name: 'Chou Jiahui Victoria',
      birth: DateTime(1991, 10, 28, 12),
      gender: Gender.female,
      saved: true,
      example: true,
      timeKnown: false),
  KuaPerson(
      name: 'Mei Lin', birth: DateTime(1992, 3, 12, 8, 15), gender: Gender.female, saved: true, example: true),
  KuaPerson(
      name: 'Wei Hao',
      birth: DateTime(1989, 8, 3, 12),
      gender: Gender.male,
      saved: true,
      example: true,
      timeKnown: false),
];

String dirs(Iterable<DirectionInfo> list) => list.map((d) => directionShort[d.direction]).join(', ');

KuaPerson profileNamed(String name) => savedProfiles.firstWhere((p) => p.name == name);
