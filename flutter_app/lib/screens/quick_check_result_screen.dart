import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone_engine/inkstone_engine.dart';

import 'package:inkstone/data/current_home.dart';
import 'package:inkstone/data/house_records.dart';
import 'package:inkstone/data/household.dart';
import 'package:inkstone/data/your_year.dart' show currentSolarYear;
import 'package:inkstone/data/quick_check.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/house_save.dart';
import 'package:inkstone/widgets/widgets.dart';

/// Quick check result: each person's Kua, good directions, facing verdict, period.
class QuickCheckResultScreen extends StatelessWidget {
  const QuickCheckResultScreen({super.key, this.input});

  /// Null when opened directly: shows the example household.
  final QuickCheckInput? input;

  Future<void> _save(BuildContext context, QuickCheckInput q) async {
    useAsCurrentHome(q);
    final name = await showHouseNameDialog(
      context,
      title: 'Save this result',
      initial: defaultHouseName(currentHome.value, input: q),
    );
    if (name == null) return;
    await saveHouseResult(name: name, home: currentHome.value, quickCheck: q);
    if (context.mounted) showInkSnack(context, 'Saved $name');
  }

  @override
  Widget build(BuildContext context) {
    final q = input ?? exampleQuickCheck;
    final period = q.period;
    final people = [for (final p in q.people) (p, p.kua)];
    final shared = people.length > 1
        ? sharedGoodDirections([for (final p in people) p.$2])
        : null;
    final charts = [for (final p in q.people) _chartOf(p)];
    return InkstoneScaffold(
      title: 'Quick check result',
      showBack: true,
      example: q.example,
      fallbackRoute: Routes.quickCheck,
      actions: [savedHomesAction(context)],
      children: [
        if (q.home != null && !q.home!.isEmpty)
          InkstoneCard(
            title: 'The home',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.home!.summary, style: InkText.body()),
                if (q.home!.source != null)
                  Text('From ${q.home!.source}', style: InkText.small),
              ],
            ),
          ),
        InkstoneCard(
          title: '${propertyLabel[q.type]} · Period ${period.period}',
          source: SourceBadge.calculated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Completed ${q.completionYear}. '
                '${period.period == 9
                    ? 'Period 9 runs from Li Chun 2024 to early 2044.'
                    : period.period == 8
                    ? 'Period 8 ran from Li Chun 2004 to Li Chun 2024.'
                    : 'Outside Periods 8 and 9.'}',
                style: InkText.body(),
              ),
              if (period.ambiguous)
                Text(
                  'Completed in a year when the period changes; the date was not given, so this assumes after Li Chun.',
                  style: InkText.body(size: 14, color: AppColors.care),
                ),
              const SizedBox(height: 4),
              Text(
                'The full Flying Stars chart for this period is on the floor reading.',
                style: InkText.small,
              ),
            ],
          ),
        ),
        FloorElementCard(
          floorRaw: q.home?.floor,
          favourable: charts.isEmpty
              ? const []
              : charts.first.favourableElements,
          unfavourable: charts.isEmpty
              ? const []
              : unfavourableElements(charts.first),
          partnerFavourable: charts.length > 1
              ? charts[1].favourableElements
              : const [],
        ),
        for (final m in methodsToRead(q.method))
          if (q.facings[m] != null)
            _FacingCard(
              methodLabel: facingMethodLabel[m]!,
              reading: facingFromDegrees(q.facings[m]!),
              people: people,
            ),
        if (q.method == FacingMethod.unsure)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Schools disagree on which opening counts. Both readings are shown; a master can help you choose.',
              style: InkText.small,
            ),
          ),
        const SectionHeader(title: 'Each person'),
        for (final (p, k) in people) _PersonCard(person: p, kua: k),
        if (shared != null)
          InkstoneCard(
            title: 'Shared good directions',
            child: Text(
              shared.isEmpty
                  ? 'No direction is good for both (one East group, one West group). Use each person\'s own bed and desk directions.'
                  : '${shared.map((d) => directionShort[d]).join(', ')}: good for both. Use these for a shared bed headboard or the main door.',
              style: InkText.body(),
            ),
          ),
        YearAfflictionsCard(year: currentSolarYear()),
        YearAfflictionsCard(year: currentSolarYear() + 1),
        const SizedBox(height: 14),
        MidnightButton(
          label: 'Floor reading (Flying Stars)',
          onPressed: () => context.go(Routes.floorResult),
        ),
        const SizedBox(height: 10),
        ButtonRow(
          first: MidnightButton(
            label: 'Save result',
            onPressed: () => _save(context, q),
          ),
          second: GhostButton(
            label: 'Saved homes',
            onPressed: () => context.push(Routes.savedHomes),
          ),
        ),
        const SizedBox(height: 10),
        ButtonRow(
          first: MidnightButton(
            label: 'Home checklist',
            onPressed: () => context.push(Routes.homeChecklist),
          ),
          second: GhostButton(
            label: 'Check again',
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(Routes.quickCheck),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Kua uses the solar year: births before Li Chun (about 4 Feb) count as the previous year. '
          'For reflection and entertainment. Not professional advice.',
          style: InkText.caption,
        ),
      ],
    );
  }
}

class _FacingCard extends StatelessWidget {
  const _FacingCard({
    required this.methodLabel,
    required this.reading,
    required this.people,
  });
  final String methodLabel;
  final FacingReading reading;
  final List<(KuaPerson, KuaResult)> people;

  @override
  Widget build(BuildContext context) {
    final match = matchFacing(reading.direction, [
      for (final (p, k) in people) (p.name, k),
    ]);
    final color = switch (match.fit) {
      FacingFit.goodForAll => AppColors.good,
      FacingFit.goodForSome => AppColors.gold2,
      FacingFit.goodForNone => AppColors.care,
    };
    return InkstoneCard(
      title: 'Facing: $methodLabel',
      source: SourceBadge.calculated,
      borderColor: color.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reading.label,
            style: InkText.body(
              color: AppColors.gold2,
              weight: FontWeight.w600,
            ),
          ),
          if (reading.isLineFacing)
            Text(
              'Line facing (within 3° of a boundary). Re-check with the compass on site.',
              style: InkText.body(size: 14, color: AppColors.care),
            ),
          const SizedBox(height: 8),
          Text(
            match.verdict,
            style: InkText.body(color: color, weight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          for (final pf in match.people)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${pf.name} (Kua ${pf.kua.kua}): ',
                      style: InkText.body(),
                    ),
                    TextSpan(
                      text:
                          '${pf.info.pinyin} ${pf.info.chinese}, ${pf.info.english}',
                      style: InkText.body(
                        color: pf.good ? AppColors.good : AppColors.care,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.person, required this.kua});
  final KuaPerson person;
  final KuaResult kua;

  @override
  Widget build(BuildContext context) => InkstoneCard(
    title: '${person.name} · Kua ${kua.kua}',
    example: person.example,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${kua.eastGroup ? 'East' : 'West'} group · solar year ${kua.adjustedYear}',
          style: InkText.small,
        ),
        const SizedBox(height: 6),
        for (final d in kua.lucky)
          Text(
            '${directionShort[d.direction]} · ${d.pinyin} ${d.chinese}: ${d.english}',
            style: InkText.body(size: 15, color: AppColors.good),
          ),
        const SizedBox(height: 6),
        Text(
          'Take care: ${dirs(kua.unlucky)}',
          style: InkText.body(size: 15, color: AppColors.care),
        ),
        if (!person.timeKnown && person.nearLiChun)
          Text(
            'Born near Li Chun: the birth time can change the Kua. Add the time for certainty.',
            style: InkText.body(size: 14, color: AppColors.care),
          ),
      ],
    ),
  );
}

BaziChart _chartOf(KuaPerson p) => computeBazi(
  birthLocal: p.timeKnown
      ? p.birth
      : DateTime(p.birth.year, p.birth.month, p.birth.day, 12),
  utcOffsetHours: 8,
  hourKnown: p.timeKnown,
);
