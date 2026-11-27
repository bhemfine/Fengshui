import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone/data/example_charts.dart';
import 'package:inkstone/data/household.dart';
import 'package:inkstone/data/current_home.dart';
import 'package:inkstone/data/house_records.dart';
import 'package:inkstone/data/your_year.dart' show currentSolarYear;
import 'package:inkstone_engine/inkstone_engine.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/house_save.dart';
import 'package:inkstone/widgets/widgets.dart';

class HouseCheckScreen extends StatefulWidget {
  const HouseCheckScreen({super.key});
  @override
  State<HouseCheckScreen> createState() => _HouseCheckScreenState();
}

class _HouseCheckScreenState extends State<HouseCheckScreen> {
  late final _a = TextEditingController(text: currentHome.value.label);
  late final _f = TextEditingController(
    text:
        '${currentHome.value.facing.label}${currentHome.value.example ? ' (example)' : ''}',
  );

  @override
  void initState() {
    super.initState();
    currentHome.addListener(_onHome);
  }

  void _onHome() {
    final h = currentHome.value;
    if (_a.text != h.label) _a.text = h.label;
    _f.text = '${h.facing.label}${h.example ? ' (example)' : ''}';
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    currentHome.removeListener(_onHome);
    _a.dispose();
    _f.dispose();
    super.dispose();
  }

  Future<void> _saveResult() async {
    var home = currentHome.value;
    final label = _a.text.trim();
    if (label.isNotEmpty && (label != home.label || home.example)) {
      home = home.copyWith(label: label, example: false);
      await setCurrentHome(home);
    }
    if (!mounted) return;
    final name = await showHouseNameDialog(
      context,
      title: 'Save this result',
      initial: defaultHouseName(home),
    );
    if (name == null) return;
    await saveHouseResult(name: name, home: home);
    if (mounted) showInkSnack(context, 'Saved $name');
  }

  Widget _field(String l, TextEditingController c) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l, style: InkText.body(size: 15, color: AppColors.ivory2)),
        const SizedBox(height: 5),
        TextField(controller: c, style: InkText.body(size: 15)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final home = currentHome.value;
    final facing = home.facing.direction;
    final ex = home.example ? ' (example)' : '';
    final door = home.chart.palaces[facing]!;
    final year = currentSolarYear();
    final fits = [
      for (final p in [mainUser, partner]) homeFitFor(p, facing),
    ];
    final dirName = directionLong[facing]!;
    final reasons = [
      for (final f in fits)
        '$dirName door is ${f.info.pinyin} (${f.info.english}) for ${shortName(f.person)}\'s Kua ${f.person.kua.kua}'
            '${f.good ? '' : '; good directions are ${dirs(f.person.kua.lucky)}'}$ex.',
      'Period ${home.period}: water star ${door.facing} and mountain star ${door.mountain} sit at the ${dirName.toLowerCase()} door side. '
          '${palaceTip(door, home.period)}$ex',
      if (yearAfflictionsHits(facing, year).isNotEmpty)
        'In $year the $dirName holds ${yearAfflictionsHits(facing, year).join(', ')}: no renovation on that side this year.',
    ];
    return InkstoneScaffold(
      title: 'House check',
      showBack: true,
      actions: [savedHomesAction(context)],
      example: home.example,
      fallbackRoute: Routes.floorResult,
      children: [
        _field('Address', _a),
        _field('Front door', _f),
        InkstoneCard(
          title: 'Couple fit',
          example: home.example,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, f) in fits.indexed) ...[
                SizedBox(height: i == 0 ? 6 : 8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            '${shortName(f.person)} · Kua ${f.person.kua.kua} — ',
                        style: InkText.body(),
                      ),
                      TextSpan(
                        text: f.good ? 'Good fit' : 'Take care',
                        style: InkText.body(
                          color: f.good ? AppColors.good : AppColors.care,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ScoreBar(
                  value: f.score,
                  color: f.good ? AppColors.good : AppColors.care,
                ),
              ],
              const SizedBox(height: 6),
              Text(
                'Birth times unknown — hour-based checks left out. Scores rank the facing within each person\'s 8 directions.',
                style: InkText.small,
              ),
            ],
          ),
        ),
        FloorElementCard(
          floorRaw: home.floor,
          favourable: computeBazi(
            birthLocal: mainUser.timeKnown
                ? mainUser.birth
                : DateTime(
                    mainUser.birth.year,
                    mainUser.birth.month,
                    mainUser.birth.day,
                    12,
                  ),
            utcOffsetHours: 8,
            hourKnown: mainUser.timeKnown,
          ).favourableElements,
          unfavourable: unfavourableElements(
            computeBazi(
              birthLocal: mainUser.timeKnown
                  ? mainUser.birth
                  : DateTime(
                      mainUser.birth.year,
                      mainUser.birth.month,
                      mainUser.birth.day,
                      12,
                    ),
              utcOffsetHours: 8,
              hourKnown: mainUser.timeKnown,
            ),
          ),
          partnerFavourable: computeBazi(
            birthLocal: partner.timeKnown
                ? partner.birth
                : DateTime(
                    partner.birth.year,
                    partner.birth.month,
                    partner.birth.day,
                    12,
                  ),
            utcOffsetHours: 8,
            hourKnown: partner.timeKnown,
          ).favourableElements,
        ),
        const SizedBox(height: 12),
        MidnightButton(
          label: 'See the floor reading',
          onPressed: () => context.go(Routes.floorResult),
        ),
        const SizedBox(height: 10),
        ButtonRow(
          first: MidnightButton(label: 'Save result', onPressed: _saveResult),
          second: GhostButton(
            label: 'Saved homes',
            onPressed: () => context.push(Routes.savedHomes),
          ),
        ),
        const SizedBox(height: 10),
        ButtonRow(
          first: GhostButton(
            label: 'Quick check',
            onPressed: () => context.push(Routes.quickCheck),
          ),
          second: GhostButton(
            label: 'Home checklist',
            onPressed: () => context.push(Routes.homeChecklist),
          ),
        ),
        InkstoneCard(
          title: 'Why',
          source: SourceBadge.calculated,
          child: Column(
            children: [
              for (final (i, r) in reasons.indexed)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : const Border(
                            top: BorderSide(color: AppColors.hairline),
                          ),
                  ),
                  child: Text(r, style: InkText.body(height: 1.4)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
