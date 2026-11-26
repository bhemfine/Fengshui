import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inkstone_engine/inkstone_engine.dart';

import 'package:inkstone/data/address_search.dart';
import 'package:inkstone/data/home_plan_store.dart';
import 'package:inkstone/data/listing_fetch.dart';
import 'package:inkstone/data/quick_check.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/screens/map_bearing_screen.dart' show MapBearingArgs;
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/listing_render_view.dart';
import 'package:inkstone/widgets/widgets.dart';

class ListingImportArgs {
  const ListingImportArgs({this.text, this.returnResult = false});

  /// Pasted or shared text containing the link.
  final String? text;

  /// Opened from the quick check: pop with the pre-fill instead of pushing.
  final bool returnResult;
}

/// Paste a PropertyGuru, 99.co or HDB Flat Portal link. The app reads what the
/// link and page show (address, postal code, floor, unit, type, TOP year,
/// location, floor plan), you check it, then pick the facing yourself.
/// Fetched on this phone only; only what you save is kept.
class ListingImportScreen extends StatefulWidget {
  const ListingImportScreen({super.key, this.args = const ListingImportArgs()});
  final ListingImportArgs args;

  /// Widget tests turn network reads off.
  static bool networkEnabled = true;

  @override
  State<ListingImportScreen> createState() => _ListingImportScreenState();
}

enum _Stage { idle, fetching, rendering, done }

class _ListingImportScreenState extends State<ListingImportScreen> {
  final _link = TextEditingController();
  final _search = AddressSearch();
  final _fetcher = ListingFetcher();

  _Stage _stage = _Stage.idle;
  ListingDetails? _d;
  String? _status;
  bool _statusWarn = false;
  String? _error;

  // Editable review fields.
  PropertyType? _type;
  final _block = TextEditingController();
  final _street = TextEditingController();
  final _project = TextEditingController();
  final _postal = TextEditingController();
  final _floor = TextEditingController();
  final _unit = TextEditingController();
  final _year = TextEditingController();

  bool _planBusy = false;
  SavedPlan? _saved;
  bool _showPlans = false;
  String? _locFrom;

  @override
  void initState() {
    super.initState();
    final t = widget.args.text;
    if (t != null && t.trim().isNotEmpty) {
      _link.text = t.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) => _read());
    }
    HomePlanStore.load().then((p) {
      if (mounted) setState(() => _saved = p);
    });
  }

  @override
  void dispose() {
    for (final c in [_link, _block, _street, _project, _postal, _floor, _unit, _year]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(ListingDetails d) {
    _d = d;
    _type = d.type ?? _type;
    void set(TextEditingController c, String? v) {
      if (v != null && v.isNotEmpty) c.text = v;
    }

    set(_block, d.block);
    set(_street, d.street);
    set(_project, d.project);
    set(_postal, d.postalCode);
    set(_unit, d.unit);
    set(
      _floor,
      d.storey != null
          ? '${d.storey}'
          : d.storeyFrom != null
          ? '${d.storeyFrom} to ${d.storeyTo ?? d.storeyFrom}'
          : d.floorLevel,
    );
    if (d.completionYear != null) _year.text = '${d.completionYear}';
  }

  Future<void> _paste() async {
    final c = await Clipboard.getData(Clipboard.kTextPlain);
    if (c?.text != null) setState(() => _link.text = c!.text!.trim());
  }

  Future<void> _read() async {
    FocusScope.of(context).unfocus();
    final base = parseListingUrl(_link.text);
    if (base == null) {
      setState(() => _error = 'That is not a PropertyGuru, 99.co or HDB Flat Portal listing link.');
      return;
    }
    setState(() {
      _error = null;
      _fill(base);
      _status =
          'Read from the link: ${listingSiteLabel[base.site]}${base.listingId != null ? ' listing ${base.listingId}' : ''}.';
      _statusWarn = false;
      _stage = ListingImportScreen.networkEnabled ? _Stage.fetching : _Stage.done;
    });
    if (!ListingImportScreen.networkEnabled) return;
    final out = await _fetcher.fetch(base);
    if (!mounted) return;
    switch (out.status) {
      case FetchStatus.ok:
        _fill(out.details);
        await _finish('Read the listing page on this phone.');
      case FetchStatus.blocked || FetchStatus.needsRender:
        setState(() {
          _fill(out.details);
          _status = out.status == FetchStatus.blocked
              ? '${listingSiteLabel[base.site]} did not let the app read the page directly. Opening it on this phone instead…'
              : 'This page needs to load in a browser. Opening it on this phone…';
          _stage = _Stage.rendering;
        });
      case FetchStatus.failed:
        await _finish(
          'Could not reach the listing (no connection or the page has gone). Using what is in the link; please fill in the rest.',
          warn: true,
        );
    }
  }

  Future<void> _onRendered(RenderResult r) async {
    if (!mounted || _d == null) return;
    var d = withFinalUrl(_d!, r.url);
    if (r.html.isNotEmpty) d = parseListingHtml(d, r.html);
    if (r.text.isNotEmpty) d = parseListingText(d, r.text);
    _fill(d);
    if (r.blocked) {
      await _finish(
        '${listingSiteLabel[d.site]} blocked the app from reading this listing (bot check). '
        'I have kept what the link shows; please fill in the rest from the listing.',
        warn: true,
      );
    } else {
      await _finish('Read the listing page on this phone (browser view).');
    }
  }

  Future<void> _finish(String msg, {bool warn = false}) async {
    setState(() {
      _status = msg;
      _statusWarn = warn;
      _stage = _Stage.fetching;
    });
    final d = _current();
    _locFrom = d.hasLocation ? 'from the listing page' : null;
    final g = await geocodeListing(d, _search);
    if (_locFrom == null && g.hasLocation) _locFrom = 'from the map search';
    if (!mounted) return;
    setState(() {
      _d = g;
      if (_postal.text.isEmpty && g.postalCode != null) _postal.text = g.postalCode!;
      _stage = _Stage.done;
    });
  }

  /// The listing with the user's edits applied.
  ListingDetails _current() {
    final d = _d!;
    String? v(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    return ListingDetails(
      site: d.site,
      url: d.url,
      listingId: d.listingId,
      kind: d.kind,
      type: _type,
      typeLabel: d.typeLabel,
      block: v(_block),
      street: v(_street),
      project: v(_project),
      postalCode: v(_postal),
      floorLevel: d.floorLevel,
      storeyFrom: d.storeyFrom,
      storeyTo: d.storeyTo,
      unit: v(_unit),
      completionYear: int.tryParse(_year.text.trim()),
      completionApprox: d.completionApprox && int.tryParse(_year.text.trim()) == d.completionYear,
      lat: d.lat,
      lng: d.lng,
      floorPlanUrls: d.floorPlanUrls,
      facingHint: d.facingHint,
      fromPage: d.fromPage,
    );
  }

  QuickCheckPrefill _prefill() {
    final d = _current();
    return QuickCheckPrefill(
      type: d.type,
      completionYear: d.completionYear,
      completionApprox: d.completionApprox,
      facingHint: d.facingHint,
      home: HomeDetails(
        address: d.address,
        postalCode: d.postalCode,
        floor: _floor.text.trim().isEmpty ? null : _floor.text.trim(),
        unit: d.unit,
        lat: d.lat,
        lng: d.lng,
        source: '${listingSiteLabel[d.site]} listing${d.listingId != null ? ' ${d.listingId}' : ''}',
      ),
    );
  }

  void _useInQuickCheck() {
    final p = _prefill();
    if (widget.args.returnResult) {
      context.pop(p);
    } else {
      context.push(Routes.quickCheck, extra: p);
    }
  }

  Future<void> _openMap() async {
    final d = _current();
    await context.push<double>(
      Routes.mapBearing,
      extra: MapBearingArgs(lat: d.lat, lng: d.lng, query: d.searchQuery, facingHint: d.facingHint),
    );
  }

  Future<void> _savePlan(String url) async {
    setState(() => _planBusy = true);
    try {
      final p = await HomePlanStore.download(url);
      if (mounted) setState(() => _saved = p);
      if (mounted) showInkSnack(context, 'Saved on this phone as your home plan. Please confirm it is the right flat.');
    } catch (_) {
      if (mounted) showInkSnack(context, 'Could not download the plan. You can upload a screenshot instead.');
    } finally {
      if (mounted) setState(() => _planBusy = false);
    }
  }

  Future<void> _uploadPlan() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2400);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      final ext = x.name.contains('.') ? x.name.split('.').last : 'jpg';
      final p = await HomePlanStore.save(bytes, ext: ext, source: 'upload', confirmed: true);
      if (mounted) setState(() => _saved = p);
    } catch (_) {
      if (mounted) showInkSnack(context, 'Could not open the photo picker.');
    }
  }

  Widget _field(
    String label,
    TextEditingController c,
    String key, {
    String? from,
    TextInputType? keyboard,
    List<TextInputFormatter>? fmt,
    String? hint,
  }) => FieldBlock(
    label: label,
    hint: hint,
    child: Row(
      children: [
        Expanded(
          child: TextField(
            key: Key(key),
            controller: c,
            keyboardType: keyboard,
            inputFormatters: fmt,
            style: InkText.body(size: 15),
          ),
        ),
        if (from != null) ...[const SizedBox(width: 6), InkTag(label: from)],
      ],
    ),
  );

  String? _from(String field) {
    final d = _d;
    if (d == null) return null;
    if (d.fromPage.contains(field)) return 'page';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    final busy = _stage == _Stage.fetching || _stage == _Stage.rendering;
    return InkstoneScaffold(
      title: 'Import a listing',
      showBack: true,
      fallbackRoute: Routes.floorUpload,
      stickyNote: d == null ? 'Paste a link to start' : (busy ? 'Reading the listing…' : 'You pick the facing next'),
      stickyCta: MidnightButton(
        key: const Key('li-use'),
        label: 'Use in quick check',
        onPressed: d == null || busy ? null : _useInQuickCheck,
      ),
      children: [
        Text('Paste a PropertyGuru, 99.co or HDB Flat Portal link', style: InkText.h2),
        const SizedBox(height: 4),
        Text(
          'Or share a listing to Inkstone from the site\'s app. The page is read on this phone; only what you save is kept.',
          style: InkText.small,
        ),
        const SizedBox(height: 10),
        TextField(
          key: const Key('li-link'),
          controller: _link,
          style: InkText.body(size: 15),
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'https://www.propertyguru.com.sg/l/…'),
          onSubmitted: (_) => _read(),
        ),
        const SizedBox(height: 8),
        ButtonRow(
          first: GhostButton(label: 'Paste', icon: Icons.content_paste, onPressed: busy ? null : _paste),
          second: MidnightButton(key: const Key('li-read'), label: 'Read link', onPressed: busy ? null : _read),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: InkText.body(size: 14, color: AppColors.care)),
          ),
        if (_status != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(_status!, style: InkText.body(size: 14, color: _statusWarn ? AppColors.care : AppColors.gold2)),
          ),
        if (busy)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2, color: AppColors.gold2),
          ),
        if (_stage == _Stage.rendering && d != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: ListingRenderView(site: d.site, url: d.url, onDone: _onRendered),
          ),
        if (d != null) ...[
          InkstoneCard(
            key: const Key('li-review'),
            title: 'Imported details',
            margin: const EdgeInsets.only(top: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Check and correct anything below. Fields marked "page" came from the listing page; the rest from the link or the map search.',
                  style: InkText.small,
                ),
                FieldBlock(
                  label: 'Property type${d.typeLabel != null ? ' · ${d.typeLabel}' : ''}',
                  child: ChoicePills<PropertyType>(
                    options: [for (final t in PropertyType.values) (t, propertyLabel[t]!)],
                    selected: _type,
                    onSelected: (t) => setState(() => _type = t),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 130, child: _field('Block', _block, 'li-block', from: _from('block'))),
                    const SizedBox(width: 8),
                    Expanded(child: _field('Street', _street, 'li-street', from: _from('street'))),
                  ],
                ),
                _field('Project or estate', _project, 'li-project', from: _from('project')),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _field(
                        'Postal code',
                        _postal,
                        'li-postal',
                        from: _from('postalCode'),
                        keyboard: TextInputType.number,
                        fmt: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _field('Unit', _unit, 'li-unit', from: _from('unit'))),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _field('Floor', _floor, 'li-floor', from: _from('storey') ?? _from('floorLevel'))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _field(
                        'TOP year',
                        _year,
                        'li-year',
                        from: _from('completionYear'),
                        keyboard: TextInputType.number,
                        fmt: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                        hint: d.completionApprox ? 'Worked out from the remaining lease' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  d.hasLocation
                      ? 'Location found${_locFrom != null ? ' $_locFrom' : ''}: ${d.lat!.toStringAsFixed(5)}, ${d.lng!.toStringAsFixed(5)}'
                      : (busy ? 'Finding it on the map…' : 'Not found on the map yet. Search for it on the map.'),
                  style: InkText.body(size: 14, color: d.hasLocation ? AppColors.good : AppColors.ivory2),
                ),
                const SizedBox(height: 8),
                GhostButton(label: 'Open on the map', icon: Icons.map_outlined, onPressed: busy ? null : _openMap),
                const SizedBox(height: 12),
                Text('Facing', style: InkText.body(size: 15, color: AppColors.ivory2)),
                const SizedBox(height: 4),
                Text(
                  d.facingHint != null
                      ? 'Listing says ${d.facingHint}. This is a hint only; you will pick the facing yourself in the quick check.'
                      : 'You will pick the facing yourself in the quick check (compass, map or degrees).',
                  style: InkText.body(size: 14),
                ),
              ],
            ),
          ),
          InkstoneCard(
            key: const Key('li-plan'),
            title: 'Floor plan',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_saved != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(_saved!.file.path), height: 180, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _saved!.confirmed
                        ? 'Saved on this phone as your home plan.'
                        : 'Saved on this phone. Is this the right flat\'s plan?',
                    style: InkText.small,
                  ),
                  const SizedBox(height: 6),
                  ButtonRow(
                    first: GhostButton(
                      label: _saved!.confirmed ? 'Confirmed' : 'Yes, confirm',
                      onPressed: _saved!.confirmed
                          ? null
                          : () async {
                              await HomePlanStore.confirm();
                              final p = await HomePlanStore.load();
                              if (mounted) setState(() => _saved = p);
                            },
                    ),
                    second: GhostButton(
                      label: 'Remove',
                      onPressed: () async {
                        await HomePlanStore.remove();
                        if (mounted) setState(() => _saved = null);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (d.floorPlanUrls.isNotEmpty) ...[
                  Text(
                    'This listing has ${d.floorPlanUrls.length} floor plan image${d.floorPlanUrls.length > 1 ? 's' : ''}.',
                    style: InkText.body(size: 15),
                  ),
                  const SizedBox(height: 8),
                  if (!_showPlans)
                    GhostButton(label: 'Show the plan', onPressed: () => setState(() => _showPlans = true))
                  else
                    for (final u in d.floorPlanUrls) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          u,
                          height: 180,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Text('Could not load the image.', style: InkText.small),
                        ),
                      ),
                      const SizedBox(height: 6),
                      MidnightButton(
                        label: _saved == null ? 'Save as my home plan' : 'Replace my saved plan with this',
                        onPressed: _planBusy ? null : () => _savePlan(u),
                      ),
                      const SizedBox(height: 10),
                    ],
                ] else
                  Text(
                    d.site == ListingSite.hdbPortal || _type == PropertyType.hdb
                        ? 'No floor plan could be read from this listing, and HDB does not publish one per flat that the app can fetch. Upload a photo or screenshot of the plan.'
                        : 'No floor plan could be read from this listing. Upload a photo or screenshot of the plan.',
                    style: InkText.small,
                  ),
                const SizedBox(height: 8),
                GhostButton(label: 'Upload my own plan', icon: Icons.upload_file, onPressed: _uploadPlan),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'Listing details belong to the listing site. Inkstone reads them only to fill in this check.',
          style: InkText.caption,
        ),
      ],
    );
  }
}
