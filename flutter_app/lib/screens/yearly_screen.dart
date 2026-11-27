import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone_engine/inkstone_engine.dart';

import 'package:inkstone/data/content_repo.dart';
import 'package:inkstone/data/household.dart';
import 'package:inkstone/data/your_year.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

/// "Your year": zodiac with its three elements, Tai Sui status, a written
/// guide when bundled or a rule-based guide for any other year, and lucky lists. All offline.
class YearlyScreen extends StatefulWidget {
  const YearlyScreen({super.key, this.initialYear});
  final int? initialYear;
  @override
  State<YearlyScreen> createState() => _YearlyScreenState();
}

class _YearlyScreenState extends State<YearlyScreen> {
  late int _year = widget.initialYear ?? currentSolarYear();
  int _person = 0;
  late final Future<AppContent> _content = ContentRepo.load();

  @override
  Widget build(BuildContext context) {
    final people = savedProfiles;
    return FutureBuilder<AppContent>(
      future: _content,
      builder: (context, snap) {
        final y = YourYear.compute(people[_person], _year, snap.data);
        return InkstoneScaffold(
          children: [
            _YearSeg(
              onDay: () => context.go(Routes.today),
              onMonth: () => context.go(Routes.monthly),
            ),
            const SizedBox(height: 10),
            ScreenTitle(
              title: 'Your year · $_year',
              example: y.person.example,
              subtitle:
                  '${y.taiSui.yearPillar.chinese} ${yearEnglishName(_year)} · from Li Chun',
            ),
            const SizedBox(height: 8),
            ChoicePills<int>(
              key: const Key('yy-person'),
              options: [for (final (i, p) in people.indexed) (i, shortName(p))],
              selected: _person,
              onSelected: (i) => setState(() => _person = i),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                InkIconButton(
                  icon: Icons.remove,
                  semanticLabel: 'Previous year',
                  onTap: () =>
                      setState(() => _year = (_year - 1).clamp(1924, 2100)),
                ),
                Expanded(
                  child: Text(
                    '$_year',
                    textAlign: TextAlign.center,
                    style: InkText.display(size: 22),
                  ),
                ),
                InkIconButton(
                  icon: Icons.add,
                  semanticLabel: 'Next year',
                  onTap: () =>
                      setState(() => _year = (_year + 1).clamp(1924, 2100)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ChoicePills<int>(
              key: const Key('yy-year'),
              options: [
                for (final yr in {
                  ...forecastYears,
                  currentSolarYear(),
                  currentSolarYear() + 1,
                }.toList()..sort())
                  (yr, '$yr'),
              ],
              selected: _year,
              onSelected: (v) => setState(() => _year = v),
            ),
            YourYearBody(
              key: ValueKey('yy-body-$_year-$_person'),
              y: y,
              loading: snap.connectionState != ConnectionState.done,
            ),
          ],
        );
      },
    );
  }
}

/// The card stack, reusable in tests.
class YourYearBody extends StatelessWidget {
  const YourYearBody({super.key, required this.y, this.loading = false});
  final YourYear y;
  final bool loading;

  Widget _line(String label, String value, {Color? color}) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: InkText.body(weight: FontWeight.w600),
          ),
          TextSpan(
            text: value,
            style: InkText.body(height: 1.45, color: color ?? AppColors.ivory),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final z = y.zodiac;
    final t = y.guide;
    final l = y.lucky;
    final tai = y.taiSui;
    final offends = tai.status == TaiSuiStatus.offends;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkstoneCard(
          key: const Key('yy-this-year'),
          title: '${y.year} · ${yearEnglishName(y.year)}',
          source: SourceBadge.calculated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The year from Li Chun is the ${yearEnglishName(y.year)} (${y.taiSui.yearPillar.chinese}). '
                'Your birth animal, below, stays the same when you change year.',
                style: InkText.body(height: 1.45),
              ),
            ],
          ),
        ),
        InkstoneCard(
          key: const Key('yy-zodiac'),
          title: 'Your birth animal · ${z.name} ${z.pillar.chinese}',
          source: SourceBadge.calculated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${shortName(y.person)} · born ${birthLabel(y.person)} · solar year ${z.solarYear}',
                style: InkText.small,
              ),
              _line(
                'Year element (stem ${z.pillar.stem.chinese})',
                z.yearElement.english,
              ),
              _line(
                'Animal\'s fixed element (branch ${z.branch.chinese})',
                z.animalElement.english,
              ),
              _line(
                'Na Yin 纳音',
                '${z.naYin.chinese} ${z.naYin.english} (${z.naYin.element.english})',
              ),
              const SizedBox(height: 8),
              Text(
                z.explainer,
                style: InkText.body(
                  size: 15,
                  height: 1.45,
                  color: AppColors.ivory2,
                ),
              ),
            ],
          ),
        ),
        InkstoneCard(
          key: const Key('yy-taisui'),
          title: 'Tai Sui 太岁 · ${tai.chineseLabel}',
          source: SourceBadge.calculated,
          borderColor: offends ? AppColors.care.withValues(alpha: 0.6) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offends
                    ? 'Fan Tai Sui (犯太岁)'
                    : (tai.status == TaiSuiStatus.harmony
                          ? 'He Tai Sui (合太岁)'
                          : 'Neutral'),
                style: InkText.body(
                  weight: FontWeight.w600,
                  color: offends ? AppColors.care : AppColors.good,
                ),
              ),
              const SizedBox(height: 4),
              Text(tai.summary, style: InkText.body(height: 1.45)),
              const SizedBox(height: 6),
              Text(
                t.taiSuiNote,
                style: InkText.body(
                  size: 15,
                  height: 1.45,
                  color: AppColors.ivory2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.yearElementNote,
                style: InkText.body(size: 15, height: 1.45),
              ),
            ],
          ),
        ),
        InkstoneCard(
          key: const Key('yy-outlook'),
          title: '${y.year} outlook',
          source: y.hasWrittenGuide
              ? 'Written guide (offline)'
              : 'Rule-based (offline)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.overview, style: InkText.body(height: 1.45)),
              _line('Career', t.career),
              _line('Money', t.money),
              _line('Love', t.love),
              _line('Health', t.health),
              if (t.luckyMonths.isNotEmpty) ...[
                _line(
                  'Lucky months',
                  t.luckyMonths.map((m) => '${cap(m)} month').join(', '),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Months that sit well with the ${yearEnglishName(y.year)}, not with your birth animal.',
                    style: InkText.small,
                  ),
                ),
              ],
            ],
          ),
        ),
        InkstoneCard(
          key: const Key('yy-dos'),
          title: 'Do and avoid',
          child: AlmanacList(goodFor: t.dos, avoid: y.allAvoids),
        ),
        InkstoneCard(
          key: const Key('yy-lucky'),
          title: 'Lucky for you in ${y.year}',
          source: 'Rule-based',
          borderColor: AppColors.good.withValues(alpha: 0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.yearElementNote,
                style: InkText.body(size: 15, height: 1.45),
              ),
              _line(
                "This year's colours",
                (elementColours[y.taiSui.yearPillar.stem.element] ??
                        const <String>[])
                    .join(', '),
              ),
              _line(
                'From your chart · elements',
                l.favourable.map((e) => e.english).join(', '),
                color: AppColors.good,
              ),
              _line('From your chart · colours', l.luckyColours.join(', ')),
              _line('From your chart · numbers', l.luckyNumbers.join(', ')),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Directions (Kua ${y.person.kua.kua}) · cautions are for ${y.year}',
                  style: InkText.body(weight: FontWeight.w600),
                ),
              ),
              for (final d in l.luckyDirections)
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 8),
                  child: Text(
                    '${directionLong[d.info.direction]} · ${d.info.english}'
                    '${d.caution == null ? '' : ' — take care in ${y.year}: ${d.caution}'}',
                    style: InkText.body(
                      size: 15,
                      height: 1.4,
                      color: d.caution == null
                          ? AppColors.ivory
                          : AppColors.care,
                    ),
                  ),
                ),
              if (l.luckyCrystals.isNotEmpty)
                _line(
                  'Crystals',
                  l.luckyCrystals
                      .map((c) => '${c.name} (${c.element.english})')
                      .join(', '),
                ),
              if (l.luckyRituals.isNotEmpty)
                _line('Rituals', l.luckyRituals.map((r) => r.name).join(', ')),
            ],
          ),
        ),
        InkstoneCard(
          key: const Key('yy-unlucky'),
          title: 'Go easy on',
          source: 'Rule-based',
          borderColor: AppColors.care.withValues(alpha: 0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line(
                'Elements',
                l.unfavourable.map((e) => e.english).join(', '),
                color: AppColors.care,
              ),
              _line('Colours', l.unluckyColours.join(', ')),
              _line('Numbers', l.unluckyNumbers.join(', ')),
              _line('Directions', l.unluckyDirections.join('; ')),
              if (l.unluckyCrystals.isNotEmpty)
                _line(
                  'Crystals',
                  l.unluckyCrystals.map((c) => c.name).join(', '),
                ),
            ],
          ),
        ),
        YearAfflictionsCard(year: y.year),
        InkstoneCard(
          title: 'Not available',
          child: Text(
            y.person.timeKnown
                ? 'All items use the full birth time.'
                : 'Birth time unknown: hour pillar, lucky birth hour and hour-based items are left out. '
                      'Elements use 3 pillars, so treat them as a rough guide.',
            style: InkText.body(size: 15, height: 1.45),
          ),
        ),
        const SizedBox(height: 10),
        Text(LuckyProfile.methodNote, style: InkText.caption),
        const SizedBox(height: 6),
        Text(
          'For reflection and entertainment. Not professional advice.',
          style: InkText.caption,
        ),
      ],
    );
  }
}

class _YearSeg extends StatelessWidget {
  const _YearSeg({required this.onDay, required this.onMonth});
  final VoidCallback onDay;
  final VoidCallback onMonth;

  @override
  Widget build(BuildContext context) {
    Widget b(String l, VoidCallback? t, bool sel) => Expanded(
      child: Semantics(
        button: true,
        selected: sel,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: t,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: sel
                ? BoxDecoration(
                    color: AppColors.silver.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.6),
                    ),
                  )
                : null,
            child: Text(
              l,
              style: InkText.body(
                size: 15,
                weight: FontWeight.w600,
                color: sel ? AppColors.ivory : AppColors.ivory2,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xE00B1026),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.goldDim),
      ),
      child: Row(
        children: [
          b('Day', onDay, false),
          b('Month', onMonth, false),
          b('Year', null, true),
        ],
      ),
    );
  }
}
