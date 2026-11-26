import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:inkstone_engine/inkstone_engine.dart';

import 'address_search.dart';

enum FetchStatus {
  /// Page read and parsed.
  ok,

  /// The site sent a bot check (e.g. Cloudflare) instead of the listing.
  blocked,

  /// The page is a JavaScript app; it has to be rendered on the phone.
  needsRender,

  /// No connection, timeout or other error.
  failed,
}

class FetchOutcome {
  const FetchOutcome(this.status, this.details, {this.finalUrl});
  final FetchStatus status;
  final ListingDetails details;
  final String? finalUrl;
}

/// Reads a listing page straight from the phone. No proxy, nothing stored or
/// logged: the HTML is parsed in memory and dropped.
class ListingFetcher {
  ListingFetcher({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  /// A normal mobile browser identity, so sites send the regular page.
  static const browserUserAgent =
      'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0 Mobile Safari/537.36';

  Future<FetchOutcome> fetch(ListingDetails base) async {
    if (base.site == ListingSite.hdbPortal) return FetchOutcome(FetchStatus.needsRender, base);
    try {
      final req = http.Request('GET', Uri.parse(base.url))
        ..followRedirects = true
        ..maxRedirects = 6
        ..headers.addAll({
          'User-Agent': browserUserAgent,
          'Accept': 'text/html,application/xhtml+xml',
          'Accept-Language': 'en-SG,en;q=0.9',
        });
      final res = await _client.send(req).timeout(const Duration(seconds: 15));
      final body = await res.stream
          .transform(const Utf8Decoder(allowMalformed: true))
          .join()
          .timeout(const Duration(seconds: 20));
      final finalUrl = res is http.BaseResponseWithUrl ? (res as http.BaseResponseWithUrl).url.toString() : null;
      final linked = withFinalUrl(base, finalUrl);
      if (looksBlocked(res.statusCode, body)) return FetchOutcome(FetchStatus.blocked, linked, finalUrl: finalUrl);
      if (res.statusCode != 200) return FetchOutcome(FetchStatus.failed, linked, finalUrl: finalUrl);
      final parsed = parseListingHtml(linked, body);
      if (parsed.fromPage.isEmpty && needsRendering(base.site, body)) {
        return FetchOutcome(FetchStatus.needsRender, linked, finalUrl: finalUrl);
      }
      return FetchOutcome(FetchStatus.ok, parsed, finalUrl: finalUrl);
    } catch (_) {
      return FetchOutcome(FetchStatus.failed, base);
    }
  }
}

/// A short link (e.g. PropertyGuru /l/<id>) redirects to the full listing URL,
/// whose slug carries the street and type. Fill gaps from it.
ListingDetails withFinalUrl(ListingDetails base, String? finalUrl) {
  if (finalUrl == null || finalUrl == base.url) return base;
  final f = parseListingUrl(finalUrl);
  if (f == null || f.site != base.site) return base;
  return base.copyWith(
    listingId: base.listingId ?? f.listingId,
    kind: base.kind ?? f.kind,
    type: base.type ?? f.type,
    block: base.block ?? f.block,
    street: base.street ?? f.street,
    project: base.project ?? f.project,
  );
}

/// Finds the block on the map (and the postal code if missing) with the
/// keyless Nominatim search. Returns [d] unchanged if nothing is found.
Future<ListingDetails> geocodeListing(ListingDetails d, AddressSearch search) async {
  if (d.hasLocation && d.postalCode != null) return d;
  final q = d.searchQuery;
  if (q == null) return d;
  try {
    var hits = await search.search(q);
    if (hits.isEmpty && d.postalCode != null && q != d.postalCode) hits = await search.search(d.postalCode!);
    if (hits.isEmpty) return d;
    final h = hits.first;
    return d.copyWith(lat: d.lat ?? h.lat, lng: d.lng ?? h.lon, postalCode: d.postalCode ?? h.postcode);
  } catch (_) {
    return d;
  }
}
