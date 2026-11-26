import 'dart:convert';

import 'package:http/http.dart' as http;

/// One address search hit.
class AddressHit {
  const AddressHit(this.label, this.lat, this.lon, {this.approximate = false});
  final String label;
  final double lat;
  final double lon;

  /// A postcode or road centroid rather than a building.
  final bool approximate;
}

/// Keyless address search (OpenStreetMap Nominatim, Singapore only).
///
/// OneMap's search API now needs a registered token, so it is not called from
/// the phone. TODO(proxy): route OneMap (and later Google) search through the
/// stateless proxy, which can hold the token.
///
/// Nominatim policy: identify the app, search only on submit (no
/// autocomplete), at most one request a second. Nothing is stored or logged.
class AddressSearch {
  AddressSearch({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  static const userAgent = 'Inkstone/0.1 (com.inkstone.app; Android; feng shui facing check)';

  Future<List<AddressHit>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final wait = const Duration(milliseconds: 1100) - DateTime.now().difference(_last);
    if (wait > Duration.zero) await Future<void>.delayed(wait);
    _last = DateTime.now();
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': q,
      'countrycodes': 'sg',
      'format': 'jsonv2',
      'limit': '5',
    });
    final r = await _client
        .get(uri, headers: {'User-Agent': userAgent, 'Accept-Language': 'en'})
        .timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) throw Exception('Search failed (${r.statusCode})');
    return parseNominatim(r.body);
  }
}

List<AddressHit> parseNominatim(String body) {
  final list = jsonDecode(body) as List;
  return [
    for (final x in list.cast<Map<String, Object?>>())
      AddressHit(
        (x['display_name'] as String? ?? '').replaceAll(', Singapore', ''),
        double.parse(x['lat']! as String),
        double.parse(x['lon']! as String),
        approximate: const {'postcode', 'road', 'residential', 'suburb', 'quarter', 'city'}
                .contains(x['addresstype']) ||
            x['type'] == 'postcode',
      ),
  ];
}
