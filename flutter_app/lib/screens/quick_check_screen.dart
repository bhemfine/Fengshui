import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone_engine/inkstone_engine.dart';

import 'package:inkstone/data/household.dart';
import 'package:inkstone/data/quick_check.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

/// Quick check: property type, completion year, facing method, facing, people.
/// Runs fully offline; quick-entry birthdays stay in memory only.
class QuickCheckScreen extends StatefulWidget {
  const QuickCheckScreen({super.key});
  @override
  State<QuickCheckScreen> createState() => _QuickCheckScreenState();
}

class _QuickCheckScreenState extends State<QuickCheckScreen> {
  PropertyType? _type;
  final _year = TextEditingController();
  bool? _beforeLiChun;
  FacingMethod? _method;
  final Map<FacingMethod, double> _facings = {};
  final Set<int> _picked = {};
  final List<KuaPerson> _quick = [];

  @override
  void dispose() {
    _year.dispose();
    super.dispose();
  }

  int? get _yearValue {
    final y = int.tryParse(_year.text.trim());
    if (y == null || y < 1900 || y > DateTime.now().year + 8) return null;
    return y;
  }

  bool get _needsLiChun => _yearValue != null && periodForCompletion(_yearValue!).ambiguous;

  List<KuaPerson> get _people => [
        for (final i in _picked) savedProfiles[i],
        ..._quick,
      ];

  bool get _ready =>
      _type != null &&
      _yearValue != null &&
      (!_needsLiChun || _beforeLiChun != null) &&
      _method != null &&
      methodsToRead(_method!).every(_facings.containsKey) &&
      _people.isNotEmpty;

  void _go() {
    final input = QuickCheckInput(
      type: _type!,
      completionYear: _yearValue!,
      beforeLiChun: _needsLiChun ? _beforeLiChun : null,
      method: _method!,
      facings: {for (final m in methodsToRead(_method!)) m: _facings[m]!},
      people: _people,
    );
    context.push(Routes.quickCheckResult, extra: input);
  }

  List<(FacingMethod, String)> get _methodOptions => [
        (FacingMethod.mainDoor, facingMethodLabel[FacingMethod.mainDoor]!),
        (FacingMethod.balcony, facingMethodLabel[FacingMethod.balcony]!),
        if (_type != PropertyType.landed) (FacingMethod.block, facingMethodLabel[FacingMethod.block]!),
        (FacingMethod.unsure, facingMethodLabel[FacingMethod.unsure]!),
      ];

  @override
  Widget build(BuildContext context) {
    final y = _yearValue;
    final period = y == null
        ? null
        : (_needsLiChun && _beforeLiChun != null)
            ? periodForCompletion(y, month: _beforeLiChun! ? 1 : 3)
            : periodForCompletion(y);
    final total = _people.length;
    return InkstoneScaffold(
      title: 'Quick check',
      showBack: true,
      fallbackRoute: Routes.floorUpload,
      stickyNote: _ready ? null : 'Answer each step to see the result',
      stickyCta: MidnightButton(label: 'See the result', onPressed: _ready ? _go : null),
      children: [
        Text('Does this home suit me and my partner?', style: InkText.h1),
        const SizedBox(height: 6),
        Text('Works offline. Nothing here leaves your phone.', style: InkText.small),

        const SectionHeader(title: '1 · The home'),
        FieldBlock(
          label: 'Property type',
          child: ChoicePills<PropertyType>(
            options: [for (final t in PropertyType.values) (t, propertyLabel[t]!)],
            selected: _type,
            onSelected: (t) => setState(() {
              _type = t;
              if (t == PropertyType.landed && _method == FacingMethod.block) _method = null;
            }),
          ),
        ),
        FieldBlock(
          label: 'Completion or TOP year',
          hint: _type == PropertyType.hdb
              ? 'Resale flat? The lease commencement year is close enough.'
              : 'Sets the Flying Star period.',
          child: TextField(
            key: const Key('qc-year'),
            controller: _year,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
            style: InkText.body(size: 15),
            decoration: const InputDecoration(hintText: 'e.g. 2012'),
            onChanged: (_) => setState(() => _beforeLiChun = null),
          ),
        ),
        if (_needsLiChun)
          FieldBlock(
            label: 'Was it completed before Li Chun 立春 (about 4 February $y)?',
            hint: 'The period changes at Li Chun, not on 1 January.',
            child: ChoicePills<bool>(
              options: const [(true, 'Before 4 Feb'), (false, 'On or after 4 Feb')],
              selected: _beforeLiChun,
              onSelected: (v) => setState(() => _beforeLiChun = v),
            ),
          ),
        if (period != null && (!_needsLiChun || _beforeLiChun != null))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Period ${period.period} building', style: InkText.body(color: AppColors.gold2)),
          ),

        const SectionHeader(title: '2 · Facing method'),
        Text(
          _type == PropertyType.hdb
              ? 'For HDB flats, masters differ: many read the balcony or living-room window, others the main door. Pick one, or choose "Not sure" to see both.'
              : 'Which opening should the facing be read from?',
          style: InkText.small,
        ),
        const SizedBox(height: 8),
        ChoicePills<FacingMethod>(
          options: _methodOptions,
          selected: _method,
          onSelected: (m) => setState(() => _method = m),
        ),

        if (_method != null) ...[
          const SectionHeader(title: '3 · Which way does it face?'),
          Text('The facing is the direction the opening looks out towards, standing inside.',
              style: InkText.small),
          for (final m in methodsToRead(_method!))
            _FacingPicker(
              key: ValueKey('picker-${m.name}'),
              title: facingMethodLabel[m]!,
              value: _facings[m],
              onChanged: (d) => setState(() => d == null ? _facings.remove(m) : _facings[m] = d),
            ),
        ],

        const SectionHeader(title: '4 · Who is it for?'),
        Text('Pick one or two people. Quick entries are not saved.', style: InkText.small),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (i, p) in savedProfiles.indexed)
            InkPill(
              label: '${p.name}${p.example ? ' (example)' : ''}',
              selected: _picked.contains(i),
              onTap: () => setState(() {
                if (_picked.contains(i)) {
                  _picked.remove(i);
                } else if (total < 2) {
                  _picked.add(i);
                } else {
                  showInkSnack(context, 'Up to two people per check');
                }
              }),
            ),
          for (final (i, p) in _quick.indexed)
            InkPill(
              label: '${p.name} ✕',
              selected: true,
              onTap: () => setState(() => _quick.removeAt(i)),
            ),
        ]),
        const SizedBox(height: 10),
        if (total < 2)
          GhostButton(
            label: 'Quick entry (not saved)',
            icon: Icons.person_add_alt,
            onPressed: () async {
              final p = await showModalBottomSheet<KuaPerson>(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppColors.ink2,
                builder: (_) => const _QuickEntrySheet(),
              );
              if (p != null && mounted) setState(() => _quick.add(p));
            },
          ),
        const SizedBox(height: 16),
        Text('For reflection and entertainment. Not professional advice.', style: InkText.caption),
      ],
    );
  }
}

/// "Do you know which way it faces?" Yes: 8 directions or degrees. No: calculator.
class _FacingPicker extends StatefulWidget {
  const _FacingPicker({super.key, required this.title, required this.value, required this.onChanged});
  final String title;
  final double? value;
  final ValueChanged<double?> onChanged;

  @override
  State<_FacingPicker> createState() => _FacingPickerState();
}

class _FacingPickerState extends State<_FacingPicker> {
  bool? _know;
  final _deg = TextEditingController();

  @override
  void dispose() {
    _deg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.value;
    final reading = v == null ? null : facingFromDegrees(v);
    return InkstoneCard(
      title: widget.title,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Do you know which way this opening faces?', style: InkText.body()),
        const SizedBox(height: 8),
        ChoicePills<bool>(
          options: const [(true, 'Yes, I know it'), (false, 'No, work it out')],
          selected: _know,
          onSelected: (k) => setState(() => _know = k),
        ),
        if (_know == true) ...[
          const SizedBox(height: 12),
          ChoicePills<Direction>(
            options: [for (final d in compassDirections) (d, directionShort[d]!)],
            selected: reading != null && v == directionCentreDegrees(reading.direction)
                ? reading.direction
                : null,
            onSelected: (d) {
              _deg.clear();
              widget.onChanged(directionCentreDegrees(d));
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _deg,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: InkText.body(size: 15),
            decoration: const InputDecoration(hintText: 'or type degrees, 0–359 (0 = north)'),
            onChanged: (s) {
              final d = double.tryParse(s.trim());
              widget.onChanged(d == null || d < 0 || d >= 360 ? null : d);
            },
          ),
        ],
        if (_know == false) ...[
          const SizedBox(height: 12),
          MidnightButton(
            label: 'Open the direction calculator',
            icon: Icons.explore_outlined,
            onPressed: () async {
              final d = await context.push<double>(Routes.directionCalculator);
              if (d != null) widget.onChanged(d);
            },
          ),
        ],
        if (reading != null) ...[
          const SizedBox(height: 12),
          Text(reading.label, style: InkText.body(color: AppColors.gold2, weight: FontWeight.w600)),
          if (reading.isLineFacing)
            Text(
              reading.isDirectionLine
                  ? 'Line facing: within 3° of the line between two directions. Please re-check on site.'
                  : 'Line facing: within 3° of a 24 Mountains boundary. Please re-check on site.',
              style: InkText.body(size: 14, color: AppColors.care),
            ),
        ],
      ]),
    );
  }
}

class _QuickEntrySheet extends StatefulWidget {
  const _QuickEntrySheet();
  @override
  State<_QuickEntrySheet> createState() => _QuickEntrySheetState();
}

class _QuickEntrySheetState extends State<_QuickEntrySheet> {
  final _name = TextEditingController();
  DateTime? _date;
  Gender? _gender;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ok = _date != null && _gender != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Quick entry', style: InkText.h2),
        Text('Used for this check only. Not saved.', style: InkText.small),
        FieldBlock(
          label: 'Name or nickname (optional)',
          child: TextField(controller: _name, style: InkText.body(size: 15)),
        ),
        FieldBlock(
          label: 'Birth date',
          child: GhostButton(
            label: _date == null ? 'Pick a date' : '${_date!.day}/${_date!.month}/${_date!.year}',
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date ?? DateTime(1990, 6, 15),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => _date = d);
            },
          ),
        ),
        FieldBlock(
          label: 'Gender (for Kua number)',
          child: ChoicePills<Gender>(
            options: const [(Gender.female, 'Female'), (Gender.male, 'Male')],
            selected: _gender,
            onSelected: (g) => setState(() => _gender = g),
          ),
        ),
        const SizedBox(height: 16),
        MidnightButton(
          label: 'Add',
          onPressed: ok
              ? () => Navigator.of(context).pop(KuaPerson(
                    name: _name.text.trim().isEmpty ? 'Person' : _name.text.trim(),
                    birth: DateTime(_date!.year, _date!.month, _date!.day, 12),
                    gender: _gender!,
                    timeKnown: false,
                  ))
              : null,
        ),
      ]),
    );
  }
}
