import 'dart:convert';

// Rule-based home checklist (PLAN.md Module 2, "Home checklist by property type").
// Content lives in content/home_checklist.json (bundled in the app as an asset).

enum PropertyType { hdb, condo, landed }

enum RuleSchool { classical, blackHat, popular, practical }

enum Answer { yes, no, unsure }

const Map<RuleSchool, String> schoolLabel = {
  RuleSchool.classical: 'Classical',
  RuleSchool.blackHat: 'Black Hat',
  RuleSchool.popular: 'Popular belief',
  RuleSchool.practical: 'Practical',
};

const Map<PropertyType, String> propertyLabel = {
  PropertyType.hdb: 'HDB',
  PropertyType.condo: 'Condo',
  PropertyType.landed: 'Landed',
};

PropertyType _type(String s) => PropertyType.values.firstWhere((t) => t.name == s);

RuleSchool _school(String s) => switch (s) {
  'classical' => RuleSchool.classical,
  'black_hat' => RuleSchool.blackHat,
  'popular' => RuleSchool.popular,
  'practical' => RuleSchool.practical,
  _ => throw FormatException('unknown school $s'),
};

class ChecklistSection {
  const ChecklistSection(this.id, this.title, this.intro);
  final String id;
  final String title;
  final String intro;
}

class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.section,
    required this.types,
    required this.school,
    required this.question,
    required this.flagOn,
    required this.issue,
    required this.cure,
    this.cureHdb,
    this.contested = false,
    this.year,
  });

  final String id;
  final String section;
  final Set<PropertyType> types;
  final RuleSchool school;
  final String question;

  /// Which answer means a problem.
  final Answer flagOn;
  final String issue;
  final String cure;

  /// HDB-safe cure (no structural change, never moving the household shelter).
  final String? cureHdb;

  /// Schools disagree; shown with a note instead of a firm rule.
  final bool contested;

  /// Only relevant in this calendar year (e.g. 2026 renovation sectors).
  final int? year;

  String cureFor(PropertyType t) => t == PropertyType.hdb ? (cureHdb ?? cure) : cure;

  factory ChecklistItem.fromJson(Map<String, Object?> j) => ChecklistItem(
    id: j['id']! as String,
    section: j['section']! as String,
    types: {for (final t in (j['types']! as List)) _type(t as String)},
    school: _school(j['school']! as String),
    question: j['question']! as String,
    flagOn: (j['flag_on'] as String? ?? 'yes') == 'no' ? Answer.no : Answer.yes,
    issue: j['issue']! as String,
    cure: j['cure']! as String,
    cureHdb: j['cure_hdb'] as String?,
    contested: j['contested'] as bool? ?? false,
    year: j['year'] as int?,
  );
}

class HomeChecklist {
  const HomeChecklist({required this.sections, required this.items, required this.notes});
  final List<ChecklistSection> sections;
  final List<ChecklistItem> items;

  /// Short notes shown above the list (e.g. the 2026 reno note), keyed by id.
  final Map<String, String> notes;

  factory HomeChecklist.fromJsonString(String s) {
    final j = jsonDecode(s) as Map<String, Object?>;
    return HomeChecklist(
      sections: [
        for (final x in (j['sections']! as List).cast<Map<String, Object?>>())
          ChecklistSection(x['id']! as String, x['title']! as String, x['intro'] as String? ?? ''),
      ],
      items: [
        for (final x in (j['items']! as List).cast<Map<String, Object?>>())
          ChecklistItem.fromJson(x),
      ],
      notes: {
        for (final e in ((j['notes'] as Map?) ?? const {}).entries)
          e.key as String: e.value as String,
      },
    );
  }

  /// Items for a property type, optionally limited to some schools and a year.
  List<ChecklistItem> itemsFor(PropertyType t, {Set<RuleSchool>? schools, int? year}) => [
    for (final i in items)
      if (i.types.contains(t) &&
          (schools == null || schools.contains(i.school)) &&
          (i.year == null || year == null || i.year == year))
        i,
  ];
}

class ChecklistFinding {
  const ChecklistFinding({required this.item, required this.answer, required this.cure});
  final ChecklistItem item;
  final Answer answer;
  final String cure;

  /// Unsure answers are listed as "check on site", not as problems.
  bool get confirmed => answer == item.flagOn;
}

/// Flagged issues (answer matches flagOn) and unsure items, with cures for [t].
List<ChecklistFinding> evaluateChecklist(
  HomeChecklist list,
  PropertyType t,
  Map<String, Answer> answers, {
  Set<RuleSchool>? schools,
  int? year,
}) {
  final out = <ChecklistFinding>[];
  for (final i in list.itemsFor(t, schools: schools, year: year)) {
    final a = answers[i.id];
    if (a == null) continue;
    if (a == i.flagOn || a == Answer.unsure) {
      out.add(ChecklistFinding(item: i, answer: a, cure: i.cureFor(t)));
    }
  }
  out.sort((a, b) => (a.confirmed ? 0 : 1).compareTo(b.confirmed ? 0 : 1));
  return out;
}
