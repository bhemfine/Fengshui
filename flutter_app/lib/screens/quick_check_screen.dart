import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone_engine/inkstone_engine.dart';

import 'package:inkstone/data/current_home.dart';
import 'package:inkstone/data/house_records.dart';
import 'package:inkstone/data/household.dart';
import 'package:inkstone/data/quick_check.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/screens/listing_import_screen.dart'
    show ListingImportArgs;
import 'package:inkstone/screens/map_bearing_screen.dart' show MapBearingArgs;
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/house_save.dart';
import 'package:inkstone/widgets/widgets.dart';

/// Quick check: property type, completion year, facing method, facing, people.
/// Runs fully offline; quick-entry birthdays stay in memory only.
class QuickCheckScreen extends StatefulWidget {
  const QuickCheckScreen({super.key, this.prefill, this.draft});

  /// From a listing import. The facing is never pre-filled.
  final QuickCheckPrefill? prefill;

  /// A previously saved draft to resume.
  final HouseRecord? draft;
  @override
  State<QuickCheckScreen> createState() => _QuickCheckScreenState();
}

class _QuickCheckScreenState extends State<QuickCheckScreen> {
  PropertyType? _type;
  final _year = TextEditingController();
  bool? _beforeLiChun;
  FacingMethod? _method;
  final Map<FacingMethod, double> _facings = {};
  // Boon Eng (main user) and Jiahui (partner) are picked by default.
  final Set<int> _picked = {0, 1};
  final List<KuaPerson> _quick = [];
  final _address = TextEditingController();
  final _postal = TextEditingController();
  final _floor = TextEditingController();
  final _unit = TextEditingController();
  String? _facingHint;
  String? _source;
  double? _lat, _lng;
  bool _yearApprox = false;
  String? _draftId;
  String? _draftName;

  @override
  void initState() {
    super.initState();
    _draftId = widget.draft?.id;
    _draftName = widget.draft?.name;
    final p = widget.prefill ?? widget.draft?.draft;
    if (p != null) _apply(p);
  }

  void _apply(QuickCheckPrefill p) {
    if (p.type != null) _type = p.type;
    if (p.yearText != null && p.yearText!.trim().isNotEmpty) {
      _year.text = p.yearText!.trim();
    } else if (p.completionYear != null) {
      _year.text = '${p.completionYear}';
    }
    _yearApprox = p.completionApprox;
    _beforeLiChun = p.beforeLiChun;
    if (p.method != null) _method = p.method;
    if (p.facings.isNotEmpty) _facings.addAll(p.facings);
    if (p.picked.isNotEmpty) {
      _picked
        ..clear()
        ..addAll(p.picked);
    }
    final h = p.home;
    if (h != null) {
      _address.text = h.address ?? _address.text;
      _postal.text = h.postalCode ?? _postal.text;
      _floor.text = h.floor ?? _floor.text;
      _unit.text = h.unit ?? _unit.text;
      _lat = h.lat;
      _lng = h.lng;
      _source = h.source;
    }
    _facingHint = p.facingHint ?? _facingHint;
    if (_type == PropertyType.landed && _method == FacingMethod.block)
      _method = null;
  }

  QuickCheckPrefill get _draftPrefill => QuickCheckPrefill(
    type: _type,
    completionYear: _yearValue,
    completionApprox: _yearApprox,
    home: _home.isEmpty ? null : _home,
    facingHint: _facingHint,
    yearText: _year.text.trim().isEmpty ? null : _year.text.trim(),
    beforeLiChun: _beforeLiChun,
    method: _method,
    facings: Map.of(_facings),
    picked: _picked.toList(),
  );

  Future<void> _saveDraft() async {
    final draft = _draftPrefill;
    final name = await showHouseNameDialog(
      context,
      title: 'Save draft',
      initial: suggestedDraftName(existingName: _draftName, draft: draft),
    );
    if (name == null) return;
    final record = await saveHouseDraft(id: _draftId, name: name, draft: draft);
    _draftId = record.id;
    _draftName = record.name;
    if (mounted) showInkSnack(context, 'Draft saved as ${record.name}');
  }

  Future<void> _importListing() async {
    final p = await context.push<QuickCheckPrefill>(
      Routes.listingImport,
      extra: const ListingImportArgs(returnResult: true),
    );
    if (p != null && mounted) setState(() => _apply(p));
  }

  HomeDetails get _home => HomeDetails(
    address: _address.text.trim().isEmpty ? null : _address.text.trim(),
    postalCode: _postal.text.trim().isEmpty ? null : _postal.text.trim(),
    floor: _floor.text.trim().isEmpty ? null : _floor.text.trim(),
    unit: _unit.text.trim().isEmpty ? null : _unit.text.trim(),
    lat: _lat,
    lng: _lng,
    source: _source,
  );

  @override
  void dispose() {
    _year.dispose();
    _address.dispose();
    _postal.dispose();
    _floor.dispose();
    _unit.dispose();
    super.dispose();
  }

  int? get _yearValue {
    final y = int.tryParse(_year.text.trim());
    if (y == null || y < 1900 || y > DateTime.now().year + 8) return null;
    return y;
  }

  bool get _needsLiChun =>
      _yearValue != null && periodForCompletion(_yearValue!).ambiguous;

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
      home: _home.isEmpty ? null : _home,
    );
    useAsCurrentHome(input);
    context.push(
      Routes.quickCheckResult,
      extra: QuickCheckResultArgs(input: input, recordId: _draftId),
    );
  }

  List<(FacingMethod, String)> get _methodOptions => [
    (FacingMethod.mainDoor, facingMethodLabel[FacingMethod.mainDoor]!),
    (FacingMethod.balcony, facingMethodLabel[FacingMethod.balcony]!),
    if (_type != PropertyType.landed)
      (FacingMethod.block, facingMethodLabel[FacingMethod.block]!),
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
      actions: [savedHomesAction(context)],
      stickyNote: _ready ? null : 'Answer each step to see the result',
      stickyCta: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          MidnightButton(
            label: 'See the result',
            onPressed: _ready ? _go : null,
          ),
          const SizedBox(height: 8),
          GhostButton(label: 'Save draft', onPressed: _saveDraft),
        ],
      ),
      children: [
        Text('Does this home suit me and my partner?', style: InkText.h1),
        const SizedBox(height: 6),
        Text(
          'Works offline. Nothing here leaves your phone.',
          style: InkText.small,
        ),
        const SizedBox(height: 10),
        GhostButton(
          key: const Key('qc-import'),
          label: 'Paste a listing link',
          icon: Icons.link,
          onPressed: _importListing,
        ),
        if (_source != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Filled in from $_source. Check each field.',
              style: InkText.body(size: 14, color: AppColors.gold2),
            ),
          ),

        const SectionHeader(title: '1 · The home'),
        FieldBlock(
          label: 'Property type',
          child: ChoicePills<PropertyType>(
            options: [
              for (final t in PropertyType.values) (t, propertyLabel[t]!),
            ],
            selected: _type,
            onSelected: (t) => setState(() {
              _type = t;
              if (t == PropertyType.landed && _method == FacingMethod.block)
                _method = null;
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
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            style: InkText.body(size: 15),
            decoration: const InputDecoration(hintText: 'e.g. 2012'),
            onChanged: (_) => setState(() => _beforeLiChun = null),
          ),
        ),
        if (_yearApprox)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Worked out from the remaining lease, so it may be a year out. Check the TOP year.',
              style: InkText.body(size: 14, color: AppColors.care),
            ),
          ),
        if (_needsLiChun)
          FieldBlock(
            label: 'Was it completed before Li Chun 立春 (about 4 February $y)?',
            hint: 'The period changes at Li Chun, not on 1 January.',
            child: ChoicePills<bool>(
              options: const [
                (true, 'Before 4 Feb'),
                (false, 'On or after 4 Feb'),
              ],
              selected: _beforeLiChun,
              onSelected: (v) => setState(() => _beforeLiChun = v),
            ),
          ),
        if (period != null && (!_needsLiChun || _beforeLiChun != null))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Period ${period.period} building',
              style: InkText.body(color: AppColors.gold2),
            ),
          ),

        FieldBlock(
          label: 'Address (optional)',
          child: TextField(
            key: const Key('qc-address'),
            controller: _address,
            style: InkText.body(size: 15),
            decoration: const InputDecoration(
              hintText: 'Block and street, or project',
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FieldBlock(
                label: 'Postal code',
                child: TextField(
                  key: const Key('qc-postal'),
                  controller: _postal,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: InkText.body(size: 15),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FieldBlock(
                label: 'Floor',
                child: TextField(
                  key: const Key('qc-floor'),
                  controller: _floor,
                  style: InkText.body(size: 15),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FieldBlock(
                label: 'Unit',
                child: TextField(
                  key: const Key('qc-unit'),
                  controller: _unit,
                  style: InkText.body(size: 15),
                  decoration: const InputDecoration(hintText: '#12-34'),
                ),
              ),
            ),
          ],
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
          Text(
            'The facing is the direction the opening looks out towards, standing inside.',
            style: InkText.small,
          ),
          for (final m in methodsToRead(_method!))
            _FacingPicker(
              key: ValueKey('picker-${m.name}'),
              title: facingMethodLabel[m]!,
              value: _facings[m],
              hint: _facingHint,
              mapCenter: _lat != null && _lng != null ? (_lat!, _lng!) : null,
              mapQuery: _postal.text.trim().isNotEmpty
                  ? _postal.text.trim()
                  : _address.text.trim(),
              onChanged: (d) => setState(
                () => d == null ? _facings.remove(m) : _facings[m] = d,
              ),
            ),
        ],

        const SectionHeader(title: '4 · Who is it for?'),
        Text(
          'Pick one or two people. Quick entries are not saved.',
          style: InkText.small,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
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
          ],
        ),
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
        Text(
          'For reflection and entertainment. Not professional advice.',
          style: InkText.caption,
        ),
      ],
    );
  }
}

/// "Do you know which way it faces?" Yes: 8 directions or degrees. No: calculator.
class _FacingPicker extends StatefulWidget {
  const _FacingPicker({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.hint,
    this.mapCenter,
    this.mapQuery,
  });
  final String title;
  final double? value;

  /// What a listing says. Shown only; never selected for the user.
  final String? hint;
  final (double, double)? mapCenter;
  final String? mapQuery;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.hint != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Listing says ${widget.hint}. Hint only: agents are often rough. Check it yourself.',
                style: InkText.body(size: 14, color: AppColors.ivory2),
              ),
            ),
          Text(
            'Do you know which way this opening faces?',
            style: InkText.body(),
          ),
          const SizedBox(height: 8),
          ChoicePills<bool>(
            options: const [
              (true, 'Yes, I know it'),
              (false, 'No, work it out'),
            ],
            selected: _know,
            onSelected: (k) => setState(() => _know = k),
          ),
          if (_know == true) ...[
            const SizedBox(height: 12),
            ChoicePills<Direction>(
              options: [
                for (final d in compassDirections) (d, directionShort[d]!),
              ],
              selected:
                  reading != null &&
                      v == directionCentreDegrees(reading.direction)
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: InkText.body(size: 15),
              decoration: const InputDecoration(
                hintText: 'or type degrees, 0–359 (0 = north)',
              ),
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
                final d = await context.push<double>(
                  Routes.directionCalculator,
                );
                if (d != null) widget.onChanged(d);
              },
            ),
            if (widget.mapCenter != null) ...[
              const SizedBox(height: 8),
              GhostButton(
                label: 'Pick it on the map (centred on this home)',
                icon: Icons.map_outlined,
                onPressed: () async {
                  final c = widget.mapCenter!;
                  final d = await context.push<double>(
                    Routes.mapBearing,
                    extra: MapBearingArgs(
                      lat: c.$1,
                      lng: c.$2,
                      query: widget.mapQuery,
                      facingHint: widget.hint,
                    ),
                  );
                  if (d != null) widget.onChanged(d);
                },
              ),
            ],
          ],
          if (reading != null) ...[
            const SizedBox(height: 12),
            Text(
              reading.label,
              style: InkText.body(
                color: AppColors.gold2,
                weight: FontWeight.w600,
              ),
            ),
            if (reading.isLineFacing)
              Text(
                reading.isDirectionLine
                    ? 'Line facing: within 3° of the line between two directions. Please re-check on site.'
                    : 'Line facing: within 3° of a 24 Mountains boundary. Please re-check on site.',
                style: InkText.body(size: 14, color: AppColors.care),
              ),
          ],
        ],
      ),
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
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick entry', style: InkText.h2),
          Text('Used for this check only. Not saved.', style: InkText.small),
          FieldBlock(
            label: 'Name or nickname (optional)',
            child: TextField(controller: _name, style: InkText.body(size: 15)),
          ),
          FieldBlock(
            label: 'Birth date',
            child: GhostButton(
              label: _date == null
                  ? 'Pick a date'
                  : '${_date!.day}/${_date!.month}/${_date!.year}',
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date ?? defaultMainUser.birth,
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
                ? () => Navigator.of(context).pop(
                    KuaPerson(
                      name: _name.text.trim().isEmpty
                          ? 'Person'
                          : _name.text.trim(),
                      birth: DateTime(
                        _date!.year,
                        _date!.month,
                        _date!.day,
                        12,
                      ),
                      gender: _gender!,
                      timeKnown: false,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
