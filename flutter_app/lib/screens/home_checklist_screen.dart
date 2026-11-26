import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone_engine/inkstone_engine.dart';

import 'package:inkstone/data/local_store.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

/// Rule-based home checklist for HDB, condo and landed homes.
/// Answers are kept on this phone only.
class HomeChecklistScreen extends StatefulWidget {
  const HomeChecklistScreen({super.key});
  @override
  State<HomeChecklistScreen> createState() => _HomeChecklistScreenState();
}

class _HomeChecklistScreenState extends State<HomeChecklistScreen> {
  static Future<HomeChecklist>? _cache;

  HomeChecklist? _list;
  String? _error;
  PropertyType _type = PropertyType.hdb;
  Set<RuleSchool> _schools = {...RuleSchool.values};
  Map<String, Answer> _answers = {};
  bool _showFlagged = false;
  final int _year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _cache ??= rootBundle
          .loadString('assets/content/home_checklist.json')
          .then(HomeChecklist.fromJsonString);
      final list = await _cache!;
      final t = await LocalStore.instance.loadPropertyType() ?? PropertyType.hdb;
      final a = await LocalStore.instance.loadAnswers(t);
      if (!mounted) return;
      setState(() {
        _list = list;
        _type = t;
        _answers = a;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load the checklist.');
    }
  }

  Future<void> _setType(PropertyType t) async {
    final a = await LocalStore.instance.loadAnswers(t);
    await LocalStore.instance.savePropertyType(t);
    if (!mounted) return;
    setState(() {
      _type = t;
      _answers = a;
    });
  }

  void _answer(String id, Answer a) {
    setState(() {
      if (_answers[id] == a) {
        _answers.remove(id);
      } else {
        _answers[id] = a;
      }
    });
    LocalStore.instance.saveAnswers(_type, _answers);
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    if (list == null) {
      return InkstoneScaffold(
        title: 'Home checklist',
        showBack: true,
        fallbackRoute: Routes.floorUpload,
        children: [
          const SizedBox(height: 40),
          Center(
            child: _error == null
                ? const CircularProgressIndicator(color: AppColors.gold)
                : Text(_error!, style: InkText.body(color: AppColors.care)),
          ),
        ],
      );
    }
    final items = list.itemsFor(_type, schools: _schools, year: _year);
    final answered = items.where((i) => _answers.containsKey(i.id)).length;
    final findings = evaluateChecklist(list, _type, _answers, schools: _schools, year: _year);
    final issues = findings.where((f) => f.confirmed).toList();
    final unsure = findings.where((f) => !f.confirmed).toList();

    return InkstoneScaffold(
      title: 'Home checklist',
      showBack: true,
      fallbackRoute: Routes.floorUpload,
      children: [
        Text('Tick what you see at the home. Answers stay on this phone.', style: InkText.small),
        FieldBlock(
          label: 'Property type',
          child: ChoicePills<PropertyType>(
            options: [for (final t in PropertyType.values) (t, propertyLabel[t]!)],
            selected: _type,
            onSelected: _setType,
          ),
        ),
        FieldBlock(
          label: 'Schools to include',
          hint: 'Where schools disagree, rules are tagged, not hard-coded.',
          child: ChoicePills<RuleSchool>(
            options: [for (final s in RuleSchool.values) (s, schoolLabel[s]!)],
            selected: null,
            isSelected: _schools.contains,
            onSelected: (s) => setState(() {
              final next = {..._schools};
              if (!next.remove(s)) next.add(s);
              if (next.isNotEmpty) _schools = next;
            }),
          ),
        ),
        InkstoneCard(
          key: const Key('hc-summary'),
          title: 'Flagged issues · ${issues.length}',
          borderColor: issues.isEmpty ? null : AppColors.care.withValues(alpha: 0.6),
          onTap: findings.isEmpty ? null : () => setState(() => _showFlagged = !_showFlagged),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$answered of ${items.length} answered · ${unsure.length} to check on site', style: InkText.small),
            if (findings.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_showFlagged ? 'Hide issues and cures' : 'Show issues and cures',
                    style: InkText.body(size: 15, color: AppColors.gold2)),
              ),
            if (_showFlagged)
              for (final f in findings) _FindingTile(finding: f),
          ]),
        ),
        if (_type == PropertyType.hdb) _Note(text: list.notes['hdb_cures'] ?? ''),
        if (_year == 2026 && list.notes['reno_2026'] != null) _Note(text: list.notes['reno_2026']!, care: true),
        YearAfflictionsCard(key: const Key('hc-afflictions'), year: _year, title: 'Reno tips: $_year directions to respect'),
        for (final s in list.sections) ..._section(s, items.where((i) => i.section == s.id).toList()),
        if (list.notes['myths'] != null) _Note(text: list.notes['myths']!),
        const SizedBox(height: 14),
        ButtonRow(
          first: GhostButton(label: 'Quick check', onPressed: () => context.push(Routes.quickCheck)),
          second: GhostButton(
            label: 'Clear answers',
            onPressed: _answers.isEmpty
                ? null
                : () {
                    setState(() => _answers = {});
                    LocalStore.instance.clearAnswers(_type);
                  },
          ),
        ),
        const SizedBox(height: 12),
        Text(list.notes['disclaimer'] ?? '', style: InkText.caption),
      ],
    );
  }

  List<Widget> _section(ChecklistSection s, List<ChecklistItem> items) {
    if (items.isEmpty) return const [];
    return [
      SectionHeader(title: s.title),
      if (s.intro.isNotEmpty) Text(s.intro, style: InkText.small),
      for (final i in items)
        _ItemCard(item: i, answer: _answers[i.id], onAnswer: (a) => _answer(i.id, a)),
    ];
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.answer, required this.onAnswer});
  final ChecklistItem item;
  final Answer? answer;
  final ValueChanged<Answer> onAnswer;

  @override
  Widget build(BuildContext context) {
    final flagged = answer == item.flagOn;
    return InkstoneCard(
      borderColor: flagged ? AppColors.care.withValues(alpha: 0.6) : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 6, runSpacing: 4, children: [
          InkTag(label: schoolLabel[item.school]!),
          if (item.contested) const InkTag(label: 'Schools differ', color: AppColors.care),
          if (item.year != null) InkTag(label: '${item.year}', color: AppColors.gold2),
        ]),
        const SizedBox(height: 6),
        Text(item.question, style: InkText.body(size: 15)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final (a, l) in const [(Answer.yes, 'Yes'), (Answer.no, 'No'), (Answer.unsure, 'Unsure')])
            InkPill(
              label: l,
              selected: answer == a,
              color: a == Answer.unsure ? AppColors.gold2 : (a == item.flagOn ? AppColors.care : AppColors.good),
              onTap: () => onAnswer(a),
            ),
        ]),
        if (flagged) ...[
          const SizedBox(height: 8),
          Text(item.issue, style: InkText.body(size: 14, color: AppColors.care)),
        ],
      ]),
    );
  }
}

class _FindingTile extends StatelessWidget {
  const _FindingTile({required this.finding});
  final ChecklistFinding finding;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.hairline))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 6, runSpacing: 4, children: [
            InkTag(
                label: finding.confirmed ? 'Issue' : 'Check on site',
                color: finding.confirmed ? AppColors.care : AppColors.gold2),
            InkTag(label: schoolLabel[finding.item.school]!),
          ]),
          const SizedBox(height: 4),
          Text(finding.item.issue, style: InkText.body(size: 15)),
          const SizedBox(height: 2),
          Text('Cure: ${finding.cure}', style: InkText.body(size: 14, color: AppColors.good)),
        ]),
      );
}

class _Note extends StatelessWidget {
  const _Note({required this.text, this.care = false});
  final String text;
  final bool care;

  @override
  Widget build(BuildContext context) => InkstoneCard(
        borderColor: care ? AppColors.care.withValues(alpha: 0.6) : null,
        child: Text(text, style: InkText.body(size: 14, color: care ? AppColors.care : AppColors.ivory2)),
      );
}
