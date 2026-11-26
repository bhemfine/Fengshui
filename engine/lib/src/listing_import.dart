// Listing link import: PropertyGuru, 99.co and HDB Flat Portal.
//
// Pure Dart so it runs offline and is unit-testable. Three layers:
//  1. parseListingUrl — reads only the link (works offline, never blocked).
//  2. parseListingHtml — page HTML fetched on the phone (JSON-LD,
//     __NEXT_DATA__, og: meta tags, 99.co label/value rows).
//  3. parseListingText — the visible text of a rendered page (for SPA and
//     challenge-protected pages that need a WebView to render).
//
// Privacy: only property facts are kept. Agent or seller names, phone
// numbers, descriptions and prices are never copied into ListingDetails.
// A "facing" found on a listing is a hint only and is never used as the
// home's facing without the user confirming it.

import 'dart:convert';

import 'home_checklist.dart' show PropertyType;

enum ListingSite { propertyGuru, ninetyNine, hdbPortal }

const listingSiteLabel = {
  ListingSite.propertyGuru: 'PropertyGuru',
  ListingSite.ninetyNine: '99.co',
  ListingSite.hdbPortal: 'HDB Flat Portal',
};

enum ListingKind { sale, rent }

/// Facts read from a listing. Every field is optional and editable.
class ListingDetails {
  const ListingDetails({
    required this.site,
    required this.url,
    this.listingId,
    this.kind,
    this.type,
    this.typeLabel,
    this.block,
    this.street,
    this.project,
    this.postalCode,
    this.floorLevel,
    this.storeyFrom,
    this.storeyTo,
    this.unit,
    this.completionYear,
    this.completionApprox = false,
    this.lat,
    this.lng,
    this.floorPlanUrls = const [],
    this.facingHint,
    this.fromPage = const {},
  });

  final ListingSite site;
  final String url;
  final String? listingId;
  final ListingKind? kind;
  final PropertyType? type;

  /// e.g. "HDB 4 Rooms", "5PA (5 Room Premium Apartment)".
  final String? typeLabel;
  final String? block;
  final String? street;

  /// Condo or estate name.
  final String? project;
  final String? postalCode;

  /// Words such as "High", "Mid", "Low" when no exact storey is given.
  final String? floorLevel;
  final int? storeyFrom;
  final int? storeyTo;

  /// Exact unit, e.g. "#12-34".
  final String? unit;
  final int? completionYear;

  /// True when the year was worked out (e.g. from remaining lease).
  final bool completionApprox;
  final double? lat;
  final double? lng;
  final List<String> floorPlanUrls;

  /// What the listing says the home faces. Hint only, never auto-applied.
  final String? facingHint;

  /// Field names that came from the fetched page (others came from the link).
  final Set<String> fromPage;

  /// Exact storey from the unit number, or the storey range when it is one floor.
  int? get storey {
    final u = unit;
    if (u != null) {
      final m = RegExp(r'#(\d{1,3})-').firstMatch(u);
      if (m != null) return int.parse(m.group(1)!);
    }
    if (storeyFrom != null && storeyFrom == storeyTo) return storeyFrom;
    return null;
  }

  String? get address {
    final parts = <String>[
      if (block != null && street != null) '$block $street' else if (street != null) street!,
      if (project != null && (street == null || !street!.toLowerCase().contains(project!.toLowerCase()))) project!,
      if (unit != null) unit!,
    ];
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  /// Text for the address search (geocoding).
  String? get searchQuery {
    if (block != null && street != null) return '$block $street${postalCode != null ? ' $postalCode' : ''}';
    if (postalCode != null) return 'Singapore $postalCode';
    if (street != null) return street;
    return project;
  }

  bool get hasLocation => lat != null && lng != null;

  ListingDetails copyWith({
    String? listingId,
    ListingKind? kind,
    PropertyType? type,
    String? typeLabel,
    String? block,
    String? street,
    String? project,
    String? postalCode,
    String? floorLevel,
    int? storeyFrom,
    int? storeyTo,
    String? unit,
    int? completionYear,
    bool? completionApprox,
    double? lat,
    double? lng,
    List<String>? floorPlanUrls,
    String? facingHint,
    Set<String>? fromPage,
  }) =>
      ListingDetails(
        site: site,
        url: url,
        listingId: listingId ?? this.listingId,
        kind: kind ?? this.kind,
        type: type ?? this.type,
        typeLabel: typeLabel ?? this.typeLabel,
        block: block ?? this.block,
        street: street ?? this.street,
        project: project ?? this.project,
        postalCode: postalCode ?? this.postalCode,
        floorLevel: floorLevel ?? this.floorLevel,
        storeyFrom: storeyFrom ?? this.storeyFrom,
        storeyTo: storeyTo ?? this.storeyTo,
        unit: unit ?? this.unit,
        completionYear: completionYear ?? this.completionYear,
        completionApprox: completionApprox ?? this.completionApprox,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        floorPlanUrls: floorPlanUrls ?? this.floorPlanUrls,
        facingHint: facingHint ?? this.facingHint,
        fromPage: fromPage ?? this.fromPage,
      );

  /// Page values win over link values; link values fill the gaps.
  ListingDetails _mergePage(_PageFacts p) {
    final got = <String>{...fromPage};
    T? pick<T>(String name, T? page, T? link) {
      if (page != null) {
        got.add(name);
        return page;
      }
      return link;
    }

    final plans = <String>[...floorPlanUrls];
    for (final u in p.floorPlanUrls) {
      if (!plans.contains(u)) plans.add(u);
    }
    if (p.floorPlanUrls.isNotEmpty) got.add('floorPlan');
    final year = pick('completionYear', p.completionYear, completionYear);
    return ListingDetails(
      site: site,
      url: url,
      listingId: listingId ?? p.listingId,
      kind: pick('kind', p.kind, kind),
      type: pick('type', p.type, type),
      typeLabel: pick('typeLabel', p.typeLabel, typeLabel),
      block: pick('block', p.block, block),
      street: pick('street', p.street, street),
      project: pick('project', p.project, project),
      postalCode: pick('postalCode', p.postalCode, postalCode),
      floorLevel: pick('floorLevel', p.floorLevel, floorLevel),
      storeyFrom: pick('storey', p.storeyFrom, storeyFrom),
      storeyTo: p.storeyTo ?? storeyTo,
      unit: pick('unit', p.unit, unit),
      completionYear: year,
      completionApprox: p.completionYear != null ? p.completionApprox : completionApprox,
      lat: pick('location', p.lat, lat),
      lng: p.lng ?? lng,
      floorPlanUrls: plans,
      facingHint: pick('facingHint', p.facingHint, facingHint),
      fromPage: got,
    );
  }
}

/// Facts found on a page, before merging with the link.
class _PageFacts {
  String? listingId;
  ListingKind? kind;
  PropertyType? type;
  String? typeLabel;
  String? block;
  String? street;
  String? project;
  String? postalCode;
  String? floorLevel;
  int? storeyFrom;
  int? storeyTo;
  String? unit;
  int? completionYear;
  bool completionApprox = false;
  double? lat;
  double? lng;
  final List<String> floorPlanUrls = [];
  String? facingHint;

  void setAddressLine(String s) {
    final a = parseSgAddress(s);
    if (a == null) return;
    block ??= a.block;
    street ??= a.street;
    postalCode ??= a.postalCode;
  }
}

// ---------------------------------------------------------------------------
// 1. Link only

final _urlInText = RegExp(r'https?://[^\s<>"]+', caseSensitive: false);

/// Finds the first listing link in [text] (a pasted link or shared text such
/// as "Check out this listing https://..."). Returns null for other sites.
ListingDetails? parseListingUrl(String text) {
  for (final m in _urlInText.allMatches(text.trim())) {
    final raw = m.group(0)!.replaceAll(RegExp(r'[).,;!]+$'), '');
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty) continue;
    final d = _fromUri(uri, raw);
    if (d != null) return d;
  }
  // Bare host without scheme, e.g. "propertyguru.com.sg/l/500236540".
  final bare = RegExp(r'(?:www\.)?(propertyguru\.com\.sg|99\.co|homes\.hdb\.gov\.sg)/\S+', caseSensitive: false)
      .firstMatch(text);
  if (bare != null) {
    final raw = 'https://${bare.group(0)!}';
    final uri = Uri.tryParse(raw);
    if (uri != null) return _fromUri(uri, raw);
  }
  return null;
}

ListingSite? siteForHost(String host) {
  final h = host.toLowerCase();
  if (h == 'propertyguru.com.sg' || h.endsWith('.propertyguru.com.sg')) return ListingSite.propertyGuru;
  if (h == '99.co' || h.endsWith('.99.co')) return ListingSite.ninetyNine;
  if (h == 'homes.hdb.gov.sg') return ListingSite.hdbPortal;
  return null;
}

ListingDetails? _fromUri(Uri uri, String raw) {
  final site = siteForHost(uri.host);
  if (site == null) return null;
  final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  final clean = Uri(scheme: 'https', host: uri.host, path: uri.path).toString();
  switch (site) {
    case ListingSite.propertyGuru:
      return _pgSlug(segs, clean);
    case ListingSite.ninetyNine:
      return _ninetyNineSlug(segs, clean);
    case ListingSite.hdbPortal:
      // /home/resale/42927 (also /home/resale/42927/...)
      final i = segs.indexOf('resale');
      final id = i >= 0 && i + 1 < segs.length && RegExp(r'^\d+$').hasMatch(segs[i + 1]) ? segs[i + 1] : null;
      return ListingDetails(
        site: site,
        url: clean,
        listingId: id,
        kind: ListingKind.sale,
        type: PropertyType.hdb,
      );
  }
}

ListingDetails _pgSlug(List<String> segs, String url) {
  const site = ListingSite.propertyGuru;
  // Short link: /l/500236540 (redirects to the full listing page).
  if (segs.length >= 2 && segs[0] == 'l' && RegExp(r'^\d+$').hasMatch(segs[1])) {
    return ListingDetails(site: site, url: url, listingId: segs[1]);
  }
  if (segs.isEmpty || segs[0] != 'listing') return ListingDetails(site: site, url: url);
  if (segs.length >= 2 && RegExp(r'^\d+$').hasMatch(segs[1])) {
    return ListingDetails(site: site, url: url, listingId: segs[1]);
  }
  if (segs.length < 2) return ListingDetails(site: site, url: url);
  // hdb-for-sale-210-boon-lay-place-500248942 | for-rent-the-robertson-opus-500306126
  final m = RegExp(r'^(?:(hdb|condo|landed|ec|house)-)?for-(sale|rent)-(.+?)-(\d{6,})$').firstMatch(segs[1]);
  if (m == null) return ListingDetails(site: site, url: url);
  final t = m.group(1);
  final slug = m.group(3)!;
  final type = switch (t) {
    'hdb' => PropertyType.hdb,
    'condo' || 'ec' => PropertyType.condo,
    'landed' || 'house' => PropertyType.landed,
    _ => null,
  };
  final s = _slugAddress(slug);
  return ListingDetails(
    site: site,
    url: url,
    listingId: m.group(4),
    kind: m.group(2) == 'sale' ? ListingKind.sale : ListingKind.rent,
    type: type,
    block: s.$1,
    street: s.$1 != null ? s.$2 : (type == PropertyType.hdb ? s.$2 : null),
    project: s.$1 == null && type != PropertyType.hdb ? s.$2 : null,
  );
}

ListingDetails _ninetyNineSlug(List<String> segs, String url) {
  const site = ListingSite.ninetyNine;
  // /singapore/sale/property/303b-anchorvale-link-hdb-eGDp7aWY44FaAneFoLkVsQ
  final i = segs.indexOf('property');
  if (i < 1 || i + 1 >= segs.length) return ListingDetails(site: site, url: url);
  final kindSeg = segs[i - 1];
  final kind = kindSeg == 'sale' ? ListingKind.sale : (kindSeg == 'rent' ? ListingKind.rent : null);
  final m = RegExp(r'^(.+)-(hdb|condo|landed|executive-condo|ec|cluster-house|terrace|semi-d|bungalow|apartment)-([A-Za-z0-9]{16,})$')
      .firstMatch(segs[i + 1]);
  if (m == null) return ListingDetails(site: site, url: url, kind: kind);
  final t = m.group(2)!;
  final type = switch (t) {
    'hdb' => PropertyType.hdb,
    'condo' || 'executive-condo' || 'ec' || 'apartment' => PropertyType.condo,
    _ => PropertyType.landed,
  };
  final s = _slugAddress(m.group(1)!);
  return ListingDetails(
    site: site,
    url: url,
    listingId: m.group(3),
    kind: kind,
    type: type,
    block: s.$1,
    street: s.$1 != null ? s.$2 : (type == PropertyType.hdb ? s.$2 : null),
    project: s.$1 == null && type != PropertyType.hdb ? s.$2 : null,
  );
}

/// "303b-anchorvale-link" -> ("303B", "Anchorvale Link"); "the-ebony" -> (null, "The Ebony").
(String?, String) _slugAddress(String slug) {
  final words = slug.split('-').where((w) => w.isNotEmpty).toList();
  String? block;
  if (words.isNotEmpty && RegExp(r'^\d{1,4}[a-z]?$').hasMatch(words.first)) {
    block = words.removeAt(0).toUpperCase();
  }
  return (block, words.map(_titleWord).join(' '));
}

String _titleWord(String w) {
  const upper = {'sg', 'ec', 'mrt', 'cbd'};
  const abbreviations = {'ave': 'Ave', 'st': 'St', 'rd': 'Rd', 'dr': 'Dr', 'cres': 'Cres', 'ctrl': 'Ctrl'};
  if (upper.contains(w)) return w.toUpperCase();
  if (abbreviations.containsKey(w)) return abbreviations[w]!;
  if (RegExp(r'^\d').hasMatch(w)) return w.toUpperCase();
  return w[0].toUpperCase() + w.substring(1);
}

// ---------------------------------------------------------------------------
// Address helpers

class SgAddress {
  const SgAddress({this.block, this.street, this.postalCode});
  final String? block;
  final String? street;
  final String? postalCode;
}

final _postal = RegExp(r'(?<![\d$#-])(\d{6})(?!\d)');

/// Parses "Blk 303B Anchorvale Link 542303, Anchorvale, ..." or
/// "Blk 404A Fernvale Lane, Singapore 791404" or "Singapore 530121 Hougang Town".
SgAddress? parseSgAddress(String s) {
  final t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  String? postal;
  final pm = RegExp(r'(?:Singapore\s+|S\()(\d{6})').firstMatch(t) ?? _postal.firstMatch(t);
  if (pm != null) postal = pm.group(1);
  final bm = RegExp(r'^(?:Blk\.?|Block)?\s*(\d{1,4}[A-Za-z]?)\s+([A-Za-z][A-Za-z0-9 .\x27/-]*?)(?=\s+\d{6}\b|\s*,|\s*\(|$)',
          caseSensitive: false)
      .firstMatch(t);
  String? block, street;
  if (bm != null) {
    block = bm.group(1)!.toUpperCase();
    street = bm.group(2)!.trim();
    if (street.toLowerCase().startsWith('singapore')) street = null;
  }
  if (block == null && street == null && postal == null) return null;
  return SgAddress(block: block, street: street, postalCode: postal);
}

PropertyType? _typeFromWords(String s) {
  final t = s.toLowerCase();
  if (RegExp(r'\bhdb\b|\d-room|\broom\b.*flat|executive (apartment|maisonette)|premium apartment').hasMatch(t)) {
    return PropertyType.hdb;
  }
  if (RegExp(r'condo|apartment|executive condominium|\bec\b').hasMatch(t)) return PropertyType.condo;
  if (RegExp(r'landed|terrace|semi-d|semi-detached|bungalow|cluster house|good class|detached').hasMatch(t)) {
    return PropertyType.landed;
  }
  return null;
}

/// Works out the lease start (close to completion) from "54 years 7 months" remaining
/// on a 99-year lease, as of [now].
int? leaseStartFromRemaining(String s, DateTime now) {
  final m = RegExp(r'(\d{1,2})\s*years?(?:\s*(\d{1,2})\s*months?)?', caseSensitive: false).firstMatch(s);
  if (m == null) return null;
  final remaining = int.parse(m.group(1)!) + (int.tryParse(m.group(2) ?? '') ?? 0) / 12;
  if (remaining > 99) return null;
  final used = 99 - remaining;
  final start = now.year + (now.month - 1) / 12 - used;
  return start.floor();
}

final _unitRe = RegExp(r'#\s?(\d{1,3})\s?-\s?(\d{1,5}[A-Z]?)\b');

String? _unitIn(String s) {
  final m = _unitRe.firstMatch(s);
  if (m == null) return null;
  return '#${m.group(1)!.padLeft(2, '0')}-${m.group(2)}';
}

const _directionWords = [
  'north-east', 'north east', 'northeast', 'north-west', 'north west', 'northwest',
  'south-east', 'south east', 'southeast', 'south-west', 'south west', 'southwest',
  'north', 'south', 'east', 'west', 'ne', 'nw', 'se', 'sw', 'n', 's', 'e', 'w',
];

String? _normaliseDirectionWord(String w) {
  final t = w.toLowerCase().replaceAll(RegExp(r'[\s-]'), '');
  const map = {
    'north': 'North', 'n': 'North', 'south': 'South', 's': 'South', 'east': 'East', 'e': 'East',
    'west': 'West', 'w': 'West', 'northeast': 'North-east', 'ne': 'North-east', 'northwest': 'North-west',
    'nw': 'North-west', 'southeast': 'South-east', 'se': 'South-east', 'southwest': 'South-west', 'sw': 'South-west',
  };
  return map[t];
}

/// "Door Facing: West", "Main Door North East", "Living Hall Facing: North".
/// Returns e.g. "Main door: West · Living hall: North". Hint only.
String? facingHintIn(String s) {
  final dir = _directionWords.map(RegExp.escape).join('|');
  final re = RegExp(
      r'\b(main door|door|living hall|living room|balcony|unit|block|window)\s*(?:facing|faces|is facing)?\s*[:\-–]?\s*(' +
          dir +
          r')\b(?!\s*(?:region|link|lane|road|ave|avenue|street|st|drive|dr|crescent|cres|coast|side|point))',
      caseSensitive: false);
  final hints = <String>[];
  for (final m in re.allMatches(s)) {
    final d = _normaliseDirectionWord(m.group(2)!);
    if (d == null) continue;
    // Single letters only count right after "facing".
    if (m.group(2)!.length <= 2 && !m.group(0)!.toLowerCase().contains('fac')) continue;
    var what = m.group(1)!.toLowerCase();
    if (what == 'door') what = 'main door';
    final label = '${what[0].toUpperCase()}${what.substring(1)}: $d';
    if (!hints.contains(label)) hints.add(label);
  }
  // 99.co "Facing" row: "Facing North".
  if (hints.isEmpty) {
    final m = RegExp(r'^\s*facing\s*[:\-]?\s*(' + dir + r')\s*$', caseSensitive: false, multiLine: true).firstMatch(s);
    if (m != null) {
      final d = _normaliseDirectionWord(m.group(1)!);
      if (d != null) hints.add(d);
    }
  }
  return hints.isEmpty ? null : hints.join(' · ');
}

void _applyFloorWords(_PageFacts f, String s) {
  final t = s.toLowerCase();
  final range = RegExp(r'(\d{1,2})\s*(?:to|-|–)\s*(\d{1,2})').firstMatch(t);
  if (range != null) {
    f.storeyFrom ??= int.parse(range.group(1)!);
    f.storeyTo ??= int.parse(range.group(2)!);
    return;
  }
  if (RegExp(r'penthouse').hasMatch(t)) {
    f.floorLevel ??= 'Penthouse';
  } else if (RegExp(r'super high|very high|top floor|high').hasMatch(t)) {
    f.floorLevel ??= t.contains('super') || t.contains('very') || t.contains('top') ? 'Very high' : 'High';
  } else if (RegExp(r'\bmid\b|middle').hasMatch(t)) {
    f.floorLevel ??= 'Mid';
  } else if (RegExp(r'\blow\b|ground').hasMatch(t)) {
    f.floorLevel ??= t.contains('ground') ? 'Ground' : 'Low';
  }
}

// ---------------------------------------------------------------------------
// 2. HTML

/// Blocked or challenge page (Cloudflare, Akamai, captcha) instead of the listing.
bool looksBlocked(int status, String body) {
  if (status == 403 || status == 429 || status == 503) return true;
  final head = body.length > 6000 ? body.substring(0, 6000) : body;
  return head.contains('<title>Just a moment') ||
      head.contains('challenges.cloudflare.com') ||
      head.contains('cf-chl') ||
      head.contains('Attention Required! | Cloudflare') ||
      head.contains('Access Denied</title>') ||
      head.contains('captcha-delivery.com');
}

/// HDB Flat Portal pages are a JavaScript app: plain HTML has no listing facts.
bool needsRendering(ListingSite site, String html) =>
    site == ListingSite.hdbPortal ||
    (!html.contains('application/ld+json') && !html.contains('__NEXT_DATA__') && !html.contains('og:title'));

String _unescapeHtml(String s) => s
    .replaceAll('&amp;', '&')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&#x27;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&nbsp;', ' ');

/// Parses listing facts out of page HTML and merges them into [base].
ListingDetails parseListingHtml(ListingDetails base, String html) {
  final f = _PageFacts();

  // JSON-LD blocks. Skip the site's own Organization / WebSite blocks.
  for (final m in RegExp(r'<script[^>]*type="application/ld\+json"[^>]*>(.*?)</script>', dotAll: true)
      .allMatches(html)) {
    Object? j;
    try {
      j = jsonDecode(m.group(1)!);
    } catch (_) {
      continue;
    }
    for (final node in _jsonNodes(j)) {
      _readLdNode(f, node);
    }
  }

  // __NEXT_DATA__ (Next.js pages router): search for well-known keys.
  final nd = RegExp(r'<script[^>]*id="__NEXT_DATA__"[^>]*>(.*?)</script>', dotAll: true).firstMatch(html);
  if (nd != null) {
    try {
      _readNextData(f, jsonDecode(nd.group(1)!));
    } catch (_) {}
  }

  // og: meta tags.
  final og = <String, String>{};
  for (final m in RegExp(r'<meta[^>]+property="og:([a-z_:]+)"[^>]+content="([^"]*)"').allMatches(html)) {
    og[m.group(1)!] = _unescapeHtml(m.group(2)!);
  }
  final title = og['title'];
  if (title != null) {
    f.type ??= _typeFromWords(title);
    final inM = RegExp(r'\bin\s+(.+?)(?:\s+-\s+[\d,]+\s*sqft|$)', caseSensitive: false).firstMatch(title);
    if (inM != null) {
      final where = inM.group(1)!;
      final a = parseSgAddress(where);
      if (a != null && a.block != null) {
        f.block ??= a.block;
        f.street ??= a.street;
      } else if (f.type != PropertyType.hdb) {
        f.project ??= where.trim();
      }
    }
    if (RegExp(r'for sale', caseSensitive: false).hasMatch(title)) f.kind ??= ListingKind.sale;
    if (RegExp(r'for rent', caseSensitive: false).hasMatch(title)) f.kind ??= ListingKind.rent;
  }

  // 99.co label/value data (escaped inside the RSC payload, and visible rows).
  final rows = <String, String>{};
  for (final m in RegExp(r'label\\":\\"([^"\\]{1,40})\\",\\"text\\":\\"([^"\\]{0,120})\\"').allMatches(html)) {
    rows.putIfAbsent(m.group(1)!, () => m.group(2)!);
  }
  for (final m in RegExp(r'text-body-16-semi-bold">([^<]{1,40})</div><div class="[^"]*text-body-16-regular">([^<]{1,120})<')
      .allMatches(html)) {
    rows.putIfAbsent(m.group(1)!.trim(), () => _unescapeHtml(m.group(2)!.trim()));
  }
  _applyRows(f, rows);

  // 99.co floor plan images: {"url":"...","category":"Floor Plan"} in the RSC payload.
  for (final m in RegExp(r'url\\":\\"(https://[^"\\]+(?:\\u0026[^"\\]*)*)\\"[^{}]{0,240}?category\\":\\"Floor Plan\\"')
      .allMatches(html)) {
    _addPlan(f, m.group(1)!.replaceAll(r'\u0026', '&'));
  }
  // Plain JSON variant.
  for (final m in RegExp(r'"url":"(https://[^"]+)"[^{}]{0,240}?"category":"Floor Plan"').allMatches(html)) {
    _addPlan(f, m.group(1)!.replaceAll(r'\u0026', '&'));
  }

  return base._mergePage(f);
}

void _addPlan(_PageFacts f, String url) {
  // Drop watermark text (agent names) and sizing from the URL when we can.
  final u = Uri.tryParse(url);
  if (u == null) return;
  final q = Map<String, String>.from(u.queryParameters)..remove('text');
  final clean = u.replace(queryParameters: q.isEmpty ? null : q).toString();
  if (!f.floorPlanUrls.contains(clean)) f.floorPlanUrls.add(clean);
}

Iterable<Map<String, dynamic>> _jsonNodes(Object? j) sync* {
  if (j is Map<String, dynamic>) {
    yield j;
    final g = j['@graph'];
    if (g is List) {
      for (final x in g) {
        yield* _jsonNodes(x);
      }
    }
  } else if (j is List) {
    for (final x in j) {
      yield* _jsonNodes(x);
    }
  }
}

bool _isType(Map<String, dynamic> n, Set<String> types) {
  final t = n['@type'];
  if (t is String) return types.contains(t);
  if (t is List) return t.any(types.contains);
  return false;
}

void _readLdNode(_PageFacts f, Map<String, dynamic> n) {
  if (_isType(n, const {'Organization', 'WebSite', 'WebPage', 'BreadcrumbList', 'FAQPage', 'RealEstateAgent'})) {
    return;
  }
  if (!_isType(n, const {
    'Product', 'Apartment', 'House', 'SingleFamilyResidence', 'Residence', 'Accommodation', 'Place',
    'RealEstateListing', 'Offer'
  })) {
    return;
  }
  final addr = n['address'];
  if (addr is Map) {
    final street = addr['streetAddress'];
    final loc = addr['addressLocality'];
    final pc = addr['postalCode'];
    if (street is String) f.setAddressLine(street);
    if (loc is String && RegExp(r'\d').hasMatch(loc)) f.setAddressLine(loc);
    if (pc is String && RegExp(r'^\d{6}$').hasMatch(pc)) f.postalCode ??= pc;
  } else if (addr is String) {
    f.setAddressLine(addr);
  }
  final geo = n['geo'];
  if (geo is Map) {
    final la = _num(geo['latitude']), lo = _num(geo['longitude']);
    if (la != null && lo != null && _inSingapore(la, lo)) {
      f.lat ??= la;
      f.lng ??= lo;
    }
  }
  final props = n['additionalProperty'];
  if (props is List) {
    for (final p in props) {
      if (p is! Map) continue;
      final name = '${p['name']}'.toLowerCase();
      final v = '${p['value']}';
      if (name == 'property category' || name == 'property type') f.type ??= _typeFromWords(v);
      if (name == 'listing type') {
        if (v.toLowerCase().contains('sale')) f.kind ??= ListingKind.sale;
        if (v.toLowerCase().contains('rent')) f.kind ??= ListingKind.rent;
      }
    }
  }
  final built = _num(n['yearBuilt']);
  if (built != null) f.completionYear ??= built.round();
}

double? _num(Object? v) => v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);

bool _inSingapore(double lat, double lng) => lat > 1.1 && lat < 1.5 && lng > 103.5 && lng < 104.1;

void _applyRows(_PageFacts f, Map<String, String> rows) {
  for (final e in rows.entries) {
    final k = e.key.toLowerCase().trim();
    final v = e.value.trim();
    if (v.isEmpty) continue;
    switch (k) {
      case 'built year' || 'completion year' || 'top year' || 'year built' || 'top':
        final y = int.tryParse(RegExp(r'\d{4}').firstMatch(v)?.group(0) ?? '');
        if (y != null) f.completionYear ??= y;
      case 'floor level' || 'floor' || 'storey range' || 'level':
        _applyFloorWords(f, v);
      case 'facing':
        final d = _normaliseDirectionWord(v);
        if (d != null) f.facingHint ??= d;
      case 'property type' || 'type':
        f.typeLabel ??= v;
        f.type ??= _typeFromWords(v);
      case 'name' || 'address':
        final a = parseSgAddress(v);
        if (a != null && (a.block != null || a.postalCode != null)) {
          f.block ??= a.block;
          f.street ??= a.street;
          f.postalCode ??= a.postalCode;
        } else if (f.type != PropertyType.hdb) {
          f.project ??= v;
        }
      case 'unit' || 'unit number':
        f.unit ??= _unitIn(v.startsWith('#') ? v : '#$v');
      case 'remaining lease':
        final y = leaseStartFromRemaining(v, DateTime.now());
        if (y != null && f.completionYear == null) {
          f.completionYear = y;
          f.completionApprox = true;
        }
    }
  }
}

void _readNextData(_PageFacts f, Object? root) {
  void walk(Object? j, int depth) {
    if (depth > 14) return;
    if (j is Map) {
      for (final e in j.entries) {
        final k = '${e.key}'.toLowerCase();
        final v = e.value;
        if (v is String || v is num) {
          final s = '$v';
          switch (k) {
            case 'postalcode' || 'postcode' || 'zipcode' || 'postal':
              if (RegExp(r'^\d{6}$').hasMatch(s)) f.postalCode ??= s;
            case 'latitude' || 'lat':
              final d = _num(v);
              if (d != null && d > 1.1 && d < 1.5) f.lat ??= d;
            case 'longitude' || 'lng' || 'lon':
              final d = _num(v);
              if (d != null && d > 103.5 && d < 104.1) f.lng ??= d;
            case 'blocknumber' || 'block' || 'blockno':
              if (RegExp(r'^\d{1,4}[A-Za-z]?$').hasMatch(s)) f.block ??= s.toUpperCase();
            case 'streetname' || 'street':
              if (s.length > 2 && s.length < 80) f.street ??= s;
            case 'completionyear' || 'topyear' || 'tenureyear' || 'builtyear' || 'yearbuilt':
              final y = int.tryParse(s.length >= 4 ? s.substring(0, 4) : s);
              if (y != null && y > 1900 && y < 2100) f.completionYear ??= y;
            case 'unitnumber' || 'unitno':
              f.unit ??= _unitIn(s.startsWith('#') ? s : '#$s');
            case 'floorlevel' || 'floor':
              if (v is String) _applyFloorWords(f, s);
          }
        }
        if (k.contains('floorplan') && v is List) {
          for (final x in v) {
            final u = x is String ? x : (x is Map ? (x['url'] ?? x['src'] ?? x['imageUrl']) : null);
            if (u is String && u.startsWith('http')) _addPlan(f, u);
          }
        }
        walk(v, depth + 1);
      }
    } else if (j is List) {
      for (final x in j) {
        walk(x, depth + 1);
      }
    }
  }

  walk(root, 0);
  if (f.lat == null || f.lng == null || !_inSingapore(f.lat!, f.lng!)) {
    f.lat = null;
    f.lng = null;
  }
}

// ---------------------------------------------------------------------------
// 3. Rendered page text

/// Parses the visible text of a rendered listing page (WebView innerText).
/// Agent names, phone numbers, prices and descriptions are not kept; the
/// description is scanned only for the postal code, unit, floor words and
/// a facing hint.
ListingDetails parseListingText(ListingDetails base, String text, {DateTime? now}) {
  final f = _PageFacts();
  final lines = text.split('\n').map((l) => l.replaceAll(RegExp(r'\s+'), ' ').trim()).where((l) => l.isNotEmpty).toList();

  String? after(String label) {
    final re = RegExp('^${RegExp.escape(label)}\\s*[:|]?\\s*(.*)\$', caseSensitive: false);
    for (var i = 0; i < lines.length; i++) {
      final m = re.firstMatch(lines[i]);
      if (m == null) continue;
      final rest = m.group(1)!.trim();
      if (rest.isNotEmpty) return rest;
      if (i + 1 < lines.length) return lines[i + 1];
    }
    return null;
  }

  switch (base.site) {
    case ListingSite.hdbPortal:
      // "Blk 978D Buangkok Cres" / "Singapore 536978 Hougang Town" / "5-Room"
      for (var i = 0; i < lines.length; i++) {
        final l = lines[i];
        if (f.block == null && RegExp(r'^Blk\s+\d', caseSensitive: false).hasMatch(l)) f.setAddressLine(l);
        if (f.postalCode == null) {
          final pm = RegExp(r'^Singapore\s+(\d{6})\b').firstMatch(l);
          if (pm != null) f.postalCode = pm.group(1);
        }
        if (f.typeLabel == null && RegExp(r'^(\d-Room|Executive|Multi-Generation|2-Room Flexi)', caseSensitive: false).hasMatch(l)) {
          f.typeLabel = 'HDB $l';
        }
      }
      f.type = PropertyType.hdb;
      final storey = after('Storey range');
      if (storey != null) _applyFloorWords(f, storey);
      final lease = after('Remaining lease');
      if (lease != null) {
        final y = leaseStartFromRemaining(lease, now ?? DateTime.now());
        if (y != null) {
          f.completionYear = y;
          f.completionApprox = true;
        }
      }
      for (final m in RegExp(r'https://resource\.homes\.hdb\.gov\.sg/[^\s"]*(?:floor|FP|plan)[^\s"]*\.(?:jpe?g|png|webp)',
              caseSensitive: false)
          .allMatches(text)) {
        _addPlan(f, m.group(0)!);
      }
    case ListingSite.propertyGuru || ListingSite.ninetyNine:
      // Title line: "404A Fernvale Lane, Seletar / Yio Chu Kang HDB Flat For Sale at S$ 660,000 | PropertyGuru Singapore"
      for (final l in lines.take(12)) {
        final m = RegExp(r'^(.+?)\s+(HDB Flat|Condo|Apartment|Executive Condo|Landed House|Terrace House|Semi-Detached House|Detached House|Cluster House|Bungalow)\s+For\s+(Sale|Rent)',
                caseSensitive: false)
            .firstMatch(l);
        if (m != null) {
          final where = m.group(1)!.split(',').first;
          final a = parseSgAddress(where);
          if (a != null && a.block != null) {
            f.block ??= a.block;
            f.street ??= a.street;
          } else {
            f.project ??= where.trim();
          }
          f.type ??= _typeFromWords(m.group(2)!);
          f.kind ??= m.group(3)!.toLowerCase() == 'sale' ? ListingKind.sale : ListingKind.rent;
          break;
        }
      }
      // Property details table: "| 5PA (5 Room Premium Apartment) HDB for sale | Unfurnished |", "TOP in 2002".
      for (final l in lines) {
        final top = RegExp(r'\b(?:TOP|Completed|Built)\s+(?:in\s+)?((?:19|20)\d{2})\b').firstMatch(l);
        if (top != null) f.completionYear ??= int.parse(top.group(1)!);
        final t = RegExp(r'(?:^|\|)\s*([^|]{1,60}?)\s+(HDB|Condo|Apartment|Executive Condo|Landed|Terrace|Bungalow|Semi-D)\s+for\s+(sale|rent)\b',
                caseSensitive: false)
            .firstMatch(l);
        if (t != null) {
          f.typeLabel ??= '${t.group(1)!.trim()} ${t.group(2)}';
          f.type ??= _typeFromWords(t.group(2)!);
        }
        final id = RegExp(r'Listing ID\s*-?\s*(\d{6,})').firstMatch(l);
        if (id != null) f.listingId ??= id.group(1);
      }
      final cy = after('Completion year');
      if (cy != null) f.completionYear ??= int.tryParse(RegExp(r'\d{4}').firstMatch(cy)?.group(0) ?? '');
      final ty = after('Type');
      if (ty != null) f.type ??= _typeFromWords(ty);
      // "210 Boon Lay Place 640210(D22) Boon Lay / Jurong / Tuas"
      final pd = RegExp(r'\b(\d{6})\s*\(D\d{2}\)').firstMatch(text);
      if (pd != null) f.postalCode ??= pd.group(1);
      final fl = after('Floor Level');
      if (fl != null) _applyFloorWords(f, fl);
  }

  // Description-level facts (all sites). Only these patterns are read.
  final sgPostal = RegExp(r'Singapore\s+(\d{6})\b').firstMatch(text);
  if (sgPostal != null) f.postalCode ??= sgPostal.group(1);
  f.unit ??= _unitIn(text);
  f.facingHint ??= facingHintIn(text);
  if (f.storeyFrom == null && f.floorLevel == null) {
    final fw = RegExp(r'\b(super high|very high|high|mid|middle|low|ground|top|penthouse)[\s-]+(?:floor|level|storey)\b',
            caseSensitive: false)
        .firstMatch(text);
    if (fw != null) _applyFloorWords(f, fw.group(1)!);
  }
  return base._mergePage(f);
}

/// One-line summary of what was found, for the review card.
List<(String, String?)> listingFieldSummary(ListingDetails d) => [
      ('Address', d.address),
      ('Postal code', d.postalCode),
      ('Block', d.block),
      (
        'Floor',
        d.storey != null
            ? 'Storey ${d.storey}'
            : (d.storeyFrom != null ? 'Storey ${d.storeyFrom} to ${d.storeyTo ?? d.storeyFrom}' : d.floorLevel)
      ),
      ('Unit', d.unit),
      ('Type', d.typeLabel ?? (d.type?.name.toUpperCase())),
      ('TOP year', d.completionYear == null ? null : '${d.completionApprox ? '~' : ''}${d.completionYear}'),
      ('Location', d.hasLocation ? '${d.lat!.toStringAsFixed(5)}, ${d.lng!.toStringAsFixed(5)}' : null),
      ('Floor plan', d.floorPlanUrls.isEmpty ? null : '${d.floorPlanUrls.length} image(s)'),
      ('Facing hint', d.facingHint),
    ];
