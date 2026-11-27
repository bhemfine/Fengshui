import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:inkstone_engine/inkstone_engine.dart';

import 'current_home.dart';
import 'example_charts.dart';
import 'household.dart';
import 'local_store.dart';
import 'quick_check.dart';

const houseRecordsKey = 'house.records.v1';

enum HouseRecordKind { draft, result }

/// A named house-check result or an in-progress quick-check draft, stored
/// on the phone only.
class HouseRecord {
  const HouseRecord({
    required this.id,
    required this.name,
    required this.kind,
    required this.updatedAt,
    this.home,
    this.draft,
    this.quickCheck,
    this.summary,
  });

  final String id;
  final String name;
  final HouseRecordKind kind;
  final DateTime updatedAt;
  final CurrentHome? home;

  /// Incomplete (or complete) quick-check form, used to resume a draft.
  final QuickCheckPrefill? draft;

  /// The finished quick-check input, so a saved result can reopen the
  /// result screen.
  final QuickCheckInput? quickCheck;
  final String? summary;

  bool get isDraft => kind == HouseRecordKind.draft;

  HouseRecord copyWith({
    String? name,
    DateTime? updatedAt,
    CurrentHome? home,
    QuickCheckPrefill? draft,
    QuickCheckInput? quickCheck,
    String? summary,
    HouseRecordKind? kind,
  }) => HouseRecord(
    id: id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    updatedAt: updatedAt ?? this.updatedAt,
    home: home ?? this.home,
    draft: draft ?? this.draft,
    quickCheck: quickCheck ?? this.quickCheck,
    summary: summary ?? this.summary,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'updatedAt': updatedAt.toIso8601String(),
    'home': home?.toJson(),
    'draft': draft?.toJson(),
    'quickCheck': quickCheck?.toJson(),
    'summary': summary,
  };

  factory HouseRecord.fromJson(Map<String, Object?> m) {
    final kindName = '${m['kind'] ?? ''}';
    final kind = kindName == HouseRecordKind.draft.name
        ? HouseRecordKind.draft
        : HouseRecordKind.result;
    CurrentHome? home;
    final rawHome = m['home'];
    if (rawHome is Map) {
      home = CurrentHome.fromJson(Map<String, Object?>.from(rawHome));
    }
    QuickCheckPrefill? draft;
    final rawDraft = m['draft'];
    if (rawDraft is Map) {
      draft = QuickCheckPrefill.fromJson(Map<String, Object?>.from(rawDraft));
    }
    QuickCheckInput? input;
    final rawInput = m['quickCheck'];
    if (rawInput is Map) {
      input = QuickCheckInput.fromJson(Map<String, Object?>.from(rawInput));
    }
    return HouseRecord(
      id: '${m['id'] ?? ''}',
      name: '${m['name'] ?? 'Untitled'}',
      kind: kind,
      updatedAt: DateTime.tryParse('${m['updatedAt']}') ?? DateTime.now(),
      home: home,
      draft: draft,
      quickCheck: input,
      summary: m['summary'] as String?,
    );
  }
}

final houseRecords = ValueNotifier<List<HouseRecord>>([]);

String newHouseRecordId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  final n = Random().nextInt(1 << 32);
  return '$now-$n';
}

String defaultHouseName(
  CurrentHome? home, {
  QuickCheckPrefill? draft,
  QuickCheckInput? input,
}) {
  final fromHome = home?.label.trim();
  if (fromHome != null && fromHome.isNotEmpty) return fromHome;
  final details = input?.home ?? draft?.home;
  final summary = details?.summary.trim();
  if (summary != null && summary.isNotEmpty) return summary;
  if (input != null) return propertyLabel[input.type] ?? 'House check';
  if (draft?.type != null) return propertyLabel[draft!.type!] ?? 'Draft';
  return 'Untitled home';
}

String houseResultSummary(CurrentHome home) {
  final facing = home.facing.direction;
  final fits = [
    for (final p in [mainUser, partner]) homeFitFor(p, facing),
  ];
  final people = [
    for (final f in fits)
      f.good
          ? 'suits ${shortName(f.person)}'
          : 'take care for ${shortName(f.person)}',
  ];
  return [
    '${home.facing.label} door',
    'Period ${home.period}',
    ...people,
  ].join(' · ');
}

Future<void> bootstrapHouseRecords() async {
  final raw = await LocalStore.instance.loadString(houseRecordsKey);
  if (raw == null || raw.isEmpty) {
    houseRecords.value = const [];
    return;
  }
  try {
    final list = jsonDecode(raw) as List<dynamic>;
    houseRecords.value = [
      for (final e in list)
        if (e is Map) HouseRecord.fromJson(Map<String, Object?>.from(e)),
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  } catch (_) {
    houseRecords.value = const [];
  }
}

Future<void> _persist() async {
  await LocalStore.instance.saveString(
    houseRecordsKey,
    jsonEncode([for (final r in houseRecords.value) r.toJson()]),
  );
}

void _put(HouseRecord record) {
  final next = [
    record,
    for (final r in houseRecords.value)
      if (r.id != record.id) r,
  ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  houseRecords.value = next;
}

Future<HouseRecord> saveHouseResult({
  String? id,
  required String name,
  required CurrentHome home,
  QuickCheckInput? quickCheck,
  String? summary,
}) async {
  final record = HouseRecord(
    id: id ?? newHouseRecordId(),
    name: name.trim().isEmpty
        ? defaultHouseName(home, input: quickCheck)
        : name.trim(),
    kind: HouseRecordKind.result,
    updatedAt: DateTime.now(),
    home: home.copyWith(example: false),
    quickCheck: quickCheck,
    summary: summary ?? houseResultSummary(home),
  );
  _put(record);
  await _persist();
  return record;
}

Future<HouseRecord> saveHouseDraft({
  String? id,
  required String name,
  required QuickCheckPrefill draft,
  CurrentHome? home,
}) async {
  final record = HouseRecord(
    id: id ?? newHouseRecordId(),
    name: name.trim().isEmpty
        ? defaultHouseName(home, draft: draft)
        : name.trim(),
    kind: HouseRecordKind.draft,
    updatedAt: DateTime.now(),
    home: home,
    draft: draft,
    summary: draft.home?.summary.isNotEmpty == true
        ? draft.home!.summary
        : 'In-progress draft',
  );
  _put(record);
  await _persist();
  return record;
}

Future<void> renameHouseRecord(String id, String name) async {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return;
  houseRecords.value = [
    for (final r in houseRecords.value)
      if (r.id == id)
        r.copyWith(name: trimmed, updatedAt: DateTime.now())
      else
        r,
  ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  await _persist();
}

Future<void> removeHouseRecord(String id) async {
  houseRecords.value = [
    for (final r in houseRecords.value)
      if (r.id != id) r,
  ];
  await _persist();
}

/// In-memory reset after prefs have already been wiped.
void resetHouseRecords() {
  houseRecords.value = const [];
}

/// Clear the store and the on-disk list. Used by tests; delete-my-data
/// wipes prefs first then calls [resetHouseRecords].
Future<void> clearHouseRecords() async {
  houseRecords.value = const [];
  await LocalStore.instance.remove(houseRecordsKey);
}
