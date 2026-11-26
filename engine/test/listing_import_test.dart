import 'dart:io';

import 'package:inkstone_engine/inkstone_engine.dart';
import 'package:test/test.dart';

String fixture(String name) => File('test/fixtures/listing/$name').readAsStringSync();

void main() {
  group('link only (offline)', () {
    test('PropertyGuru short links /l/<id>', () {
      for (final id in ['500236540', '500055035', '500307943']) {
        final d = parseListingUrl('SALE - 912 Hougang Street 91\n3 Beds / S\$ 599,000\nhttps://www.propertyguru.com.sg/l/$id')!;
        expect(d.site, ListingSite.propertyGuru);
        expect(d.listingId, id);
        expect(d.url, 'https://www.propertyguru.com.sg/l/$id');
      }
    });

    test('PropertyGuru HDB slug', () {
      final d = parseListingUrl('https://www.propertyguru.com.sg/listing/hdb-for-sale-210-boon-lay-place-500248942')!;
      expect(d.listingId, '500248942');
      expect(d.kind, ListingKind.sale);
      expect(d.type, PropertyType.hdb);
      expect(d.block, '210');
      expect(d.street, 'Boon Lay Place');
    });

    test('PropertyGuru condo / rent slug', () {
      final d = parseListingUrl('Look: https://www.propertyguru.com.sg/listing/for-rent-the-robertson-opus-500306126?utm_source=app')!;
      expect(d.listingId, '500306126');
      expect(d.kind, ListingKind.rent);
      expect(d.block, isNull);
      expect(d.project, 'The Robertson Opus');
      expect(d.url, isNot(contains('utm_source')));
    });

    test('99.co HDB and condo slugs', () {
      final h = parseListingUrl('https://www.99.co/singapore/sale/property/303b-anchorvale-link-hdb-eGDp7aWY44FaAneFoLkVsQ')!;
      expect(h.site, ListingSite.ninetyNine);
      expect(h.listingId, 'eGDp7aWY44FaAneFoLkVsQ');
      expect(h.type, PropertyType.hdb);
      expect(h.kind, ListingKind.sale);
      expect(h.block, '303B');
      expect(h.street, 'Anchorvale Link');
      final c = parseListingUrl('https://www.99.co/singapore/sale/property/the-ebony-condo-fpo6LLmra7wokZ7DhhAGTU')!;
      expect(c.type, PropertyType.condo);
      expect(c.project, 'The Ebony');
      expect(c.block, isNull);
    });

    test('HDB Flat Portal resale id', () {
      final d = parseListingUrl('https://homes.hdb.gov.sg/home/resale/42927')!;
      expect(d.site, ListingSite.hdbPortal);
      expect(d.listingId, '42927');
      expect(d.type, PropertyType.hdb);
    });

    test('bare host and other sites', () {
      expect(parseListingUrl('propertyguru.com.sg/l/500236540')!.listingId, '500236540');
      expect(parseListingUrl('https://www.google.com/maps'), isNull);
      expect(parseListingUrl('no link here'), isNull);
    });
  });

  group('page HTML', () {
    test('99.co HDB: JSON-LD, rows, floor plan; ignores the 99.co office address', () {
      final base = parseListingUrl('https://www.99.co/singapore/sale/property/303b-anchorvale-link-hdb-eGDp7aWY44FaAneFoLkVsQ')!;
      final d = parseListingHtml(base, fixture('99co_hdb.html'));
      expect(d.block, '303B');
      expect(d.street, 'Anchorvale Link');
      expect(d.postalCode, '542303');
      expect(d.postalCode, isNot('319637'));
      expect(d.lat, closeTo(1.38742, 1e-4));
      expect(d.lng, closeTo(103.88985, 1e-4));
      expect(d.type, PropertyType.hdb);
      expect(d.typeLabel, 'HDB 4 Rooms');
      expect(d.completionYear, 2001);
      expect(d.completionApprox, isFalse);
      expect(d.floorLevel, 'High');
      expect(d.facingHint, 'Listing: North');
      expect(d.floorPlanUrls, hasLength(1));
      expect(d.floorPlanUrls.first, startsWith('https://pic2.99.co/'));
      expect(d.floorPlanUrls.first, isNot(contains('text=')));
      expect(d.fromPage, containsAll(['postalCode', 'location', 'completionYear', 'floorPlan']));
    });

    test('99.co condo: project, postal, year, no floor plan', () {
      final base = parseListingUrl('https://www.99.co/singapore/sale/property/the-ebony-condo-fpo6LLmra7wokZ7DhhAGTU')!;
      final d = parseListingHtml(base, fixture('99co_condo.html'));
      expect(d.type, PropertyType.condo);
      expect(d.project, 'The Ebony');
      expect(d.block, '35');
      expect(d.street, 'Lorong Marican');
      expect(d.postalCode, '417216');
      expect(d.completionYear, 2016);
      expect(d.floorLevel, 'Low');
      expect(d.floorPlanUrls, isEmpty);
      expect(d.hasLocation, isTrue);
    });

    test('Cloudflare challenge is detected as blocked', () {
      expect(looksBlocked(403, fixture('pg_blocked.html')), isTrue);
      expect(looksBlocked(200, fixture('pg_blocked.html')), isTrue);
      expect(looksBlocked(200, fixture('99co_hdb.html')), isFalse);
    });

    test('fixtures carry no agent names or phone numbers', () {
      for (final f in Directory('test/fixtures/listing').listSync().whereType<File>()) {
        final s = f.readAsStringSync();
        expect(s, isNot(contains('John Cheong')), reason: f.path);
        expect(s, isNot(contains('Raynard')), reason: f.path);
        expect(s, isNot(contains('CEA:')), reason: f.path);
        expect(RegExp(r'\b[89]\d{3}\s?\d{4}\b').hasMatch(s), isFalse, reason: f.path);
      }
    });
  });

  group('rendered text', () {
    ListingDetails pg(String id) =>
        parseListingText(parseListingUrl('https://www.propertyguru.com.sg/l/$id')!, fixture('pg_$id.txt'));

    test('PropertyGuru 404A Fernvale Lane', () {
      final d = pg('500236540');
      expect(d.block, '404A');
      expect(d.street, 'Fernvale Lane');
      expect(d.postalCode, '791404');
      expect(d.type, PropertyType.hdb);
      expect(d.typeLabel, '5PA (5 Room Premium Apartment) HDB');
      expect(d.completionYear, 2002);
      expect(d.kind, ListingKind.sale);
      expect(d.floorLevel, 'Very high');
      expect(d.facingHint, 'Main door: West · Living hall: North');
      expect(d.unit, isNull);
      expect(d.hasLocation, isFalse);
    });

    test('PropertyGuru 912 Hougang Street 91', () {
      final d = pg('500055035');
      expect(d.block, '912');
      expect(d.street, 'Hougang Street 91');
      expect(d.typeLabel, '4A HDB');
      expect(d.completionYear, 1996);
      expect(d.postalCode, isNull); // not on the page; found by the address search
      expect(d.facingHint, isNull);
    });

    test('PropertyGuru 980D Buangkok Crescent', () {
      final d = pg('500307943');
      expect(d.block, '980D');
      expect(d.street, 'Buangkok Crescent');
      expect(d.typeLabel, '5I HDB');
      expect(d.completionYear, 2001);
      expect(d.floorLevel, 'High');
      expect(d.facingHint, 'Main door: North-east');
    });

    test('PropertyGuru project page (postal with district)', () {
      final d = parseListingText(
          parseListingUrl('https://www.propertyguru.com.sg/listing/hdb-for-sale-210-boon-lay-place-500248942')!,
          fixture('pg_project_210.txt'));
      expect(d.postalCode, '640210');
      expect(d.completionYear, 1977);
      expect(d.block, '210');
    });

    test('HDB Flat Portal rendered page', () {
      final d = parseListingText(parseListingUrl('https://homes.hdb.gov.sg/home/resale/42780')!, fixture('hdb_42780.txt'),
          now: DateTime(2026, 11, 27));
      expect(d.block, '978D');
      expect(d.street, 'Buangkok Cres');
      expect(d.postalCode, '536978');
      expect(d.typeLabel, 'HDB 5-Room');
      expect(d.storeyFrom, 1);
      expect(d.storeyTo, 5);
      expect(d.completionYear, 2003); // 99 - 75y8m = 23.3 years used
      expect(d.completionApprox, isTrue);
      expect(d.facingHint, isNull, reason: '"NS Facing" is too vague to hint');
    });
  });

  group('helpers', () {
    test('address lines', () {
      final a = parseSgAddress('303B Anchorvale Link 542303, Anchorvale, North-East Region, Singapore')!;
      expect((a.block, a.street, a.postalCode), ('303B', 'Anchorvale Link', '542303'));
      final b = parseSgAddress('Blk 121 Hougang Ave 1')!;
      expect((b.block, b.street), ('121', 'Hougang Ave 1'));
    });

    test('unit gives the exact storey', () {
      const d = ListingDetails(site: ListingSite.ninetyNine, url: 'x', unit: '#12-34');
      expect(d.storey, 12);
    });

    test('lease start from remaining lease', () {
      expect(leaseStartFromRemaining('54 years 7 months', DateTime(2026, 11, 1)), 1982);
    });
  });
}
