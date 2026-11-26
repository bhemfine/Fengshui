import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone/data/address_search.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';
import 'package:inkstone_engine/inkstone_engine.dart';
import 'package:latlong2/latlong.dart';

enum _Layer { oneMap, osm, satellite }

/// Map bearing: drop a pin on the door or opening, then tap the way it faces.
/// The bearing is worked out on the phone. Tiles and address search are the
/// only network calls; nothing is stored. Pops with the bearing in degrees.
class MapBearingScreen extends StatefulWidget {
  const MapBearingScreen({super.key});

  /// Widget tests turn tiles off (no network in tests).
  static bool tilesEnabled = true;

  @override
  State<MapBearingScreen> createState() => _MapBearingScreenState();
}

class _MapBearingScreenState extends State<MapBearingScreen> {
  static const _singapore = LatLng(1.3521, 103.8198);
  static const _userAgentPackage = 'com.inkstone.app';

  final _map = MapController();
  final _query = TextEditingController();
  final _search = AddressSearch();
  _Layer _layer = _Layer.oneMap;
  LatLng? _pin;
  LatLng? _target;
  bool _searching = false;
  String? _searchError;
  List<AddressHit> _hits = const [];

  @override
  void dispose() {
    _query.dispose();
    _map.dispose();
    super.dispose();
  }

  double? get _bearing {
    final p = _pin, t = _target;
    if (p == null || t == null) return null;
    if (distanceMeters(p.latitude, p.longitude, t.latitude, t.longitude) < minBearingDistanceMeters) {
      return null;
    }
    return initialBearingDegrees(p.latitude, p.longitude, t.latitude, t.longitude);
  }

  Future<void> _runSearch() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _searchError = null;
      _hits = const [];
    });
    try {
      final hits = await _search.search(_query.text);
      if (!mounted) return;
      setState(() {
        _hits = hits;
        if (hits.isEmpty) _searchError = 'No match. Try the block and street, or pan the map yourself.';
      });
      if (hits.length == 1) _goTo(hits.first);
    } catch (_) {
      if (mounted) {
        setState(() => _searchError = 'Search is unavailable right now. Pan and zoom the map to the block instead.');
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _goTo(AddressHit h) {
    setState(() => _hits = const []);
    _map.move(LatLng(h.lat, h.lon), h.approximate ? 17 : 18.5);
    if (h.approximate) showInkSnack(context, 'Approximate area: find the block on the map');
  }

  void _onTap(TapPosition _, LatLng p) {
    setState(() {
      if (_pin == null) {
        _pin = p;
      } else {
        _target = p;
      }
    });
  }

  TileLayer _tiles() => switch (_layer) {
        _Layer.oneMap => TileLayer(
            urlTemplate: 'https://www.onemap.gov.sg/maps/tiles/Default/{z}/{x}/{y}.png',
            userAgentPackageName: _userAgentPackage,
            minNativeZoom: 11,
            maxNativeZoom: 19,
            maxZoom: 20,
          ),
        _Layer.osm => TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: _userAgentPackage,
            maxNativeZoom: 19,
            maxZoom: 20,
          ),
        _Layer.satellite => TileLayer(
            urlTemplate:
                'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
            userAgentPackageName: _userAgentPackage,
            maxNativeZoom: 19,
            maxZoom: 20,
          ),
      };

  List<SourceAttribution> _attribution() => switch (_layer) {
        _Layer.oneMap => const [
            TextSourceAttribution('OneMap · Map data © contributors, Singapore Land Authority'),
          ],
        _Layer.osm => const [TextSourceAttribution('OpenStreetMap contributors')],
        _Layer.satellite => const [
            TextSourceAttribution('Esri, Maxar, Earthstar Geographics, and the GIS User Community'),
          ],
      };

  @override
  Widget build(BuildContext context) {
    final b = _bearing;
    final reading = b == null ? null : facingFromDegrees(b);
    final arrow = <Polyline>[];
    if (_pin != null && _target != null && b != null) {
      final len = distanceMeters(_pin!.latitude, _pin!.longitude, _target!.latitude, _target!.longitude);
      final head = (len * 0.25).clamp(2.0, 25.0);
      LatLng back(double off) {
        final (lat, lon) =
            destinationPoint(_target!.latitude, _target!.longitude, (b + 180 + off) % 360, head);
        return LatLng(lat, lon);
      }

      arrow
        ..add(Polyline(points: [_pin!, _target!], color: AppColors.goldHi, strokeWidth: 4))
        ..add(Polyline(points: [back(-28), _target!, back(28)], color: AppColors.goldHi, strokeWidth: 4));
    }
    final step = _pin == null
        ? '1. Find the block, then tap the main door or opening to drop a pin.'
        : _target == null
            ? '2. Now tap a point straight out from the opening, the way it looks out.'
            : 'Tap again to adjust the direction, or start again.';

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(children: [
              InkIconButton(
                icon: Icons.chevron_left,
                semanticLabel: 'Back',
                onTap: () => context.pop(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const Key('mb-search'),
                  controller: _query,
                  style: InkText.body(size: 15),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _runSearch(),
                  decoration: const InputDecoration(
                    hintText: 'Postal code or block and street',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkIconButton(
                icon: Icons.search,
                semanticLabel: 'Search',
                onTap: _searching ? null : _runSearch,
              ),
            ]),
          ),
          if (_searching) const LinearProgressIndicator(minHeight: 2, color: AppColors.gold2),
          if (_searchError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(_searchError!, style: InkText.body(size: 14, color: AppColors.care)),
            ),
          for (final h in _hits)
            ListTile(
              dense: true,
              title: Text(h.label, style: InkText.body(size: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: h.approximate ? Text('Approximate area', style: InkText.caption) : null,
              onTap: () => _goTo(h),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: ChoicePills<_Layer>(
              options: const [(_Layer.oneMap, 'OneMap'), (_Layer.osm, 'Street'), (_Layer.satellite, 'Satellite')],
              selected: _layer,
              onSelected: (l) => setState(() => _layer = l),
            ),
          ),
          Expanded(
            child: Stack(children: [
              FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCenter: _singapore,
                  initialZoom: 11.5,
                  minZoom: 10,
                  maxZoom: 20,
                  backgroundColor: AppColors.ink2,
                  // North stays up: rotation is off.
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  onTap: _onTap,
                ),
                children: [
                  if (MapBearingScreen.tilesEnabled) _tiles(),
                  PolylineLayer(polylines: arrow),
                  MarkerLayer(markers: [
                    if (_pin != null)
                      Marker(
                        point: _pin!,
                        width: 22,
                        height: 22,
                        child: const _Dot(color: AppColors.ox2),
                      ),
                    if (_target != null)
                      Marker(
                        point: _target!,
                        width: 16,
                        height: 16,
                        child: const _Dot(color: AppColors.goldHi),
                      ),
                  ]),
                  if (MapBearingScreen.tilesEnabled) RichAttributionWidget(attributions: _attribution()),
                ],
              ),
              const Positioned(top: 10, right: 10, child: _NorthBadge()),
            ]),
          ),
          Container(
            width: double.infinity,
            color: AppColors.panel,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(step, style: InkText.small),
              if (reading != null) ...[
                const SizedBox(height: 6),
                Text(reading.label, style: InkText.body(color: AppColors.gold2, weight: FontWeight.w600)),
                Text('24 Mountains: ${reading.mountain.chinese} ${reading.mountain.pinyin} (${reading.mountain.english})',
                    style: InkText.caption),
                if (reading.isLineFacing)
                  Text('Line facing: within 3° of a boundary. Zoom in and re-tap, or check on site.',
                      style: InkText.body(size: 14, color: AppColors.care)),
              ],
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: GhostButton(
                    label: 'Start again',
                    onPressed: _pin == null ? null : () => setState(() => _pin = _target = null),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MidnightButton(
                    label: 'Use this bearing',
                    onPressed: b == null ? null : () => context.pop(b),
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              Text('Map facing is a hint: confirm with the compass on site.', style: InkText.caption),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.ivory, width: 2),
        ),
      );
}

class _NorthBadge extends StatelessWidget {
  const _NorthBadge();

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.cardFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.goldDim),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.navigation, size: 18, color: AppColors.gold2),
          Text('N', style: InkText.body(size: 12, color: AppColors.ivory, height: 1.1)),
        ]),
      );
}
