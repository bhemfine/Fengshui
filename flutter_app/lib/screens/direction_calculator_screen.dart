import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone_engine/inkstone_engine.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

enum _Mode { compass, map, degrees }

/// Direction calculator: compass (3 averaged readings), map bearing (stub), or typed degrees.
/// Pops with the true bearing in degrees when the user confirms.
class DirectionCalculatorScreen extends StatefulWidget {
  const DirectionCalculatorScreen({super.key});
  @override
  State<DirectionCalculatorScreen> createState() => _DirectionCalculatorScreenState();
}

class _DirectionCalculatorScreenState extends State<DirectionCalculatorScreen> {
  _Mode _mode = _Mode.compass;
  final _deg = TextEditingController();

  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<MagnetometerEvent>? _magSub;
  List<double>? _acc;
  List<double>? _mag;
  bool _started = false;
  String? _sensorError;
  final List<double> _readings = [];

  @override
  void dispose() {
    _stop();
    _deg.dispose();
    super.dispose();
  }

  void _stop() {
    _accSub?.cancel();
    _magSub?.cancel();
    _accSub = null;
    _magSub = null;
  }

  // Simple low-pass filter to steady the needle.
  List<double> _smooth(List<double>? old, double x, double y, double z) {
    if (old == null) return [x, y, z];
    const a = 0.15;
    return [old[0] + a * (x - old[0]), old[1] + a * (y - old[1]), old[2] + a * (z - old[2])];
  }

  void _start() {
    setState(() {
      _started = true;
      _sensorError = null;
    });
    void onError(Object e) {
      if (!mounted) return;
      _stop();
      setState(() => _sensorError = 'This phone did not give a compass reading. Type the degrees instead.');
    }

    try {
      _accSub = accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
        (e) => setState(() => _acc = _smooth(_acc, e.x, e.y, e.z)),
        onError: onError,
        cancelOnError: true,
      );
      _magSub = magnetometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
        (e) => setState(() => _mag = _smooth(_mag, e.x, e.y, e.z)),
        onError: onError,
        cancelOnError: true,
      );
    } catch (e) {
      onError(e);
    }
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _started && (_acc == null || _mag == null) && _sensorError == null) {
        _stop();
        setState(() => _sensorError = 'No compass sensor found on this phone. Type the degrees instead.');
      }
    });
  }

  double? get _heading {
    final a = _acc, m = _mag;
    if (a == null || m == null) return null;
    final h = compassHeading(a[0], a[1], a[2], m[0], m[1], m[2]);
    return h == null ? null : magneticToTrue(h);
  }

  double? get _tilt => _acc == null ? null : tiltDegrees(_acc![0], _acc![1], _acc![2]);
  double? get _field => _mag == null ? null : fieldStrength(_mag![0], _mag![1], _mag![2]);

  void _use(double deg) {
    if (context.canPop()) {
      context.pop(deg);
    } else {
      showInkSnack(context, 'Facing ${facingFromDegrees(deg).label}');
      context.go(Routes.quickCheck);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkstoneScaffold(
      title: 'Direction calculator',
      showBack: true,
      fallbackRoute: Routes.quickCheck,
      children: [
        Text('Find which way the opening faces, in degrees.', style: InkText.small),
        const SizedBox(height: 10),
        ChoicePills<_Mode>(
          options: const [(_Mode.compass, 'Compass'), (_Mode.map, 'Map bearing'), (_Mode.degrees, 'Type degrees')],
          selected: _mode,
          onSelected: (m) => setState(() {
            _mode = m;
            if (m != _Mode.compass) {
              _stop();
              _started = false;
            }
          }),
        ),
        if (_mode == _Mode.compass) ..._compass(),
        if (_mode == _Mode.map)
          InkstoneCard(
            title: 'Map bearing',
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Search the postal code or block, drop a pin on the door or opening, then tap the way it looks out. '
                'The bearing is worked out on your phone.',
                style: InkText.body(),
              ),
              const SizedBox(height: 6),
              Text('Uses the internet for map tiles and address search only. No location access, nothing saved.',
                  style: InkText.small),
              const SizedBox(height: 12),
              MidnightButton(
                label: 'Open the map',
                icon: Icons.map_outlined,
                onPressed: () async {
                  final d = await context.push<double>(Routes.mapBearing);
                  if (d != null && mounted) _use(d);
                },
              ),
            ]),
          ),
        if (_mode == _Mode.degrees) ..._typed(),
      ],
    );
  }

  List<Widget> _typed() {
    final d = double.tryParse(_deg.text.trim());
    final valid = d != null && d >= 0 && d < 360;
    final r = valid ? facingFromDegrees(d) : null;
    return [
      FieldBlock(
        label: 'Bearing in degrees (0 = north, 90 = east)',
        child: TextField(
          key: const Key('dc-degrees'),
          controller: _deg,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: InkText.body(size: 15),
          onChanged: (_) => setState(() {}),
        ),
      ),
      if (r != null) _ReadingSummary(reading: r),
      const SizedBox(height: 12),
      MidnightButton(label: 'Use this facing', onPressed: valid ? () => _use(d) : null),
    ];
  }

  List<Widget> _compass() {
    final h = _heading;
    final tilt = _tilt;
    final field = _field;
    final done = _readings.length >= 3;
    final mean = _readings.isEmpty ? null : circularMeanDegrees(_readings);
    final spread = _readings.length > 1 ? maxDeviationDegrees(_readings) : 0.0;
    return [
      InkstoneCard(
        title: 'How to read it',
        child: Text(
          'Stand inside at the opening, looking out. Hold the phone flat with its top edge pointing out. '
          'Keep away from window grilles, metal doors, speakers and other phones. Take three readings.',
          style: InkText.body(),
        ),
      ),
      if (_sensorError != null)
        InkstoneCard(
          borderColor: AppColors.care,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_sensorError!, style: InkText.body(color: AppColors.care)),
            const SizedBox(height: 10),
            GhostButton(label: 'Type degrees instead', onPressed: () => setState(() => _mode = _Mode.degrees)),
          ]),
        )
      else if (!_started) ...[
        const SizedBox(height: 14),
        MidnightButton(label: 'Start compass', icon: Icons.explore_outlined, onPressed: _start),
        const SizedBox(height: 8),
        LinkButton(label: 'No compass? Type degrees', onPressed: () => setState(() => _mode = _Mode.degrees)),
      ] else ...[
        InkstoneCard(
          child: Column(children: [
            Text(h == null ? '—' : '${h.toStringAsFixed(0)}°', style: InkText.hero),
            Text(h == null ? 'Waiting for the sensor…' : directionLong[directionAt(h)]!,
                style: InkText.body(color: AppColors.gold2)),
            const SizedBox(height: 8),
            if (tilt != null && tilt > maxTiltDegrees)
              Text('Tilted ${tilt.toStringAsFixed(0)}°: hold the phone flat.',
                  style: InkText.body(size: 14, color: AppColors.care)),
            if (field != null && isInterference(field))
              Text('Magnetic interference (${field.toStringAsFixed(0)} µT). Move away from metal or electronics, or wave the phone in a figure 8 to recalibrate.',
                  textAlign: TextAlign.center, style: InkText.body(size: 14, color: AppColors.care)),
          ]),
        ),
        const SizedBox(height: 12),
        if (!done)
          MidnightButton(
            label: 'Take reading ${_readings.length + 1} of 3',
            onPressed: h == null ? null : () => setState(() => _readings.add(h)),
          ),
        if (_readings.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Readings: ${_readings.map((r) => '${r.toStringAsFixed(0)}°').join(', ')}', style: InkText.small),
          if (spread > 10)
            Text('Readings differ by up to ${spread.toStringAsFixed(0)}°. Reset and try again, holding still.',
                style: InkText.body(size: 14, color: AppColors.care)),
        ],
        if (done && mean != null) ...[
          _ReadingSummary(reading: facingFromDegrees(mean), prefix: 'Average'),
          const SizedBox(height: 12),
          MidnightButton(label: 'Use this facing', onPressed: () => _use(mean)),
        ],
        if (_readings.isNotEmpty)
          LinkButton(label: 'Reset readings', onPressed: () => setState(_readings.clear)),
      ],
    ];
  }
}

class _ReadingSummary extends StatelessWidget {
  const _ReadingSummary({required this.reading, this.prefix});
  final FacingReading reading;
  final String? prefix;

  @override
  Widget build(BuildContext context) => InkstoneCard(
        title: prefix == null ? 'Facing' : '$prefix facing',
        source: SourceBadge.calculated,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(reading.label, style: InkText.body(color: AppColors.gold2, weight: FontWeight.w600)),
          Text('24 Mountains: ${reading.mountain.chinese} ${reading.mountain.pinyin} (${reading.mountain.english})',
              style: InkText.small),
          if (reading.isLineFacing)
            Text(
              'Line facing: within 3° of a boundary. Re-check, as a few degrees can change the chart.',
              style: InkText.body(size: 14, color: AppColors.care),
            ),
        ]),
      );
}
