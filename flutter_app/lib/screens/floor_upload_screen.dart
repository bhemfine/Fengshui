import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inkstone/data/current_home.dart';
import 'package:inkstone/data/home_plan_store.dart';
import 'package:inkstone/motion/motion.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';
import 'package:inkstone_engine/inkstone_engine.dart';

class FloorUploadScreen extends StatefulWidget {
  const FloorUploadScreen({super.key});
  @override
  State<FloorUploadScreen> createState() => _FloorUploadScreenState();
}

class _FloorUploadScreenState extends State<FloorUploadScreen> {
  late int _deg = currentHome.value.facingDegrees.round();
  late double _rot = currentHome.value.planRotationDeg;
  bool _reading = false;
  Timer? _t;
  SavedPlan? _saved;

  @override
  void initState() {
    super.initState();
    currentHome.addListener(_onHome);
    _refreshPlan();
  }

  void _onHome() {
    if (!mounted) return;
    setState(() {
      _deg = currentHome.value.facingDegrees.round();
      _rot = currentHome.value.planRotationDeg;
    });
  }

  Future<void> _refreshPlan() async {
    final p = await HomePlanStore.load();
    if (mounted) setState(() => _saved = p);
  }

  String get _dir {
    final d = nearestPalace(_deg.toDouble());
    return directionLong[d]!;
  }

  @override
  void dispose() {
    currentHome.removeListener(_onHome);
    _t?.cancel();
    super.dispose();
  }

  Future<void> _persist({int? deg, double? rot, bool? example}) async {
    final h = currentHome.value;
    await setCurrentHome(h.copyWith(
      facingDegrees: (deg ?? _deg).toDouble(),
      planRotationDeg: rot ?? _rot,
      example: example ?? h.example,
    ));
  }

  void _nudgeDeg(int delta) {
    final next = (_deg + delta) % 360;
    setState(() => _deg = next);
    unawaited(_persist(deg: next));
  }

  void _setRot(double v) {
    setState(() => _rot = v);
    unawaited(_persist(rot: v));
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final x = await ImagePicker().pickImage(source: source, maxWidth: 2400);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      final ext = x.name.contains('.') ? x.name.split('.').last : 'jpg';
      final src = source == ImageSource.camera ? 'camera' : 'upload';
      final p = await HomePlanStore.save(bytes, ext: ext, source: src, confirmed: true);
      if (!mounted) return;
      setState(() => _saved = p);
      await _persist(example: false);
    } catch (_) {
      if (mounted) {
        showInkSnack(
          context,
          source == ImageSource.camera
              ? 'Could not open the camera. You can still choose a photo from the gallery.'
              : 'Could not open the photo picker.',
        );
      }
    }
  }

  void _read() {
    unawaited(_persist());
    final d = reduceMotion(context) ? 150 : 600;
    setState(() => _reading = true);
    _t?.cancel();
    _t = Timer(Duration(milliseconds: d), () {
      if (!mounted) return;
      setState(() => _reading = false);
      context.go(Routes.floorResult);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rm = reduceMotion(context);
    final home = currentHome.value;
    return InkstoneScaffold(
      title: 'Add your floor plan',
      showBack: true,
      fallbackRoute: Routes.floorResult,
      stickyCta: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_reading) ...[
            Text('Reading your plan…', style: InkText.small),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: rm ? 1 : 0, end: 1),
                duration: const Duration(milliseconds: 600),
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 4,
                  color: AppColors.gold2,
                  backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          MidnightButton(label: 'Read my home', onPressed: _reading ? null : _read),
        ],
      ),
      children: [
        InkstoneCard(
          key: const Key('fu-quick-check'),
          title: 'Buying or checking a home?',
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Facing and Kua for one or two people, plus the HDB, condo and landed checklist. Works offline. Or paste a PropertyGuru, 99.co or HDB Flat Portal link to fill in the address.',
                style: InkText.small,
              ),
              const SizedBox(height: 10),
              GhostButton(
                key: const Key('fu-import'),
                label: 'Paste a listing link',
                icon: Icons.link,
                onPressed: () async {
                  await context.push(Routes.listingImport);
                  _refreshPlan();
                },
              ),
              const SizedBox(height: 8),
              ButtonRow(
                first: MidnightButton(label: 'Quick check', onPressed: () => context.push(Routes.quickCheck)),
                second: GhostButton(label: 'Checklist', onPressed: () => context.push(Routes.homeChecklist)),
              ),
            ],
          ),
        ),
        if (_saved != null)
          FloorPlanOverlay(
            home: home.copyWith(facingDegrees: _deg.toDouble(), planRotationDeg: _rot),
            image: File(_saved!.file.path),
            height: 280,
          )
        else
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xE60B1026),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.goldDim),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.space_dashboard_outlined, size: 44, color: AppColors.gold),
                const SizedBox(height: 10),
                Text('No plan chosen yet', style: InkText.body(color: AppColors.ivory2)),
                const SizedBox(height: 4),
                Text('Take a photo or pick one from the gallery.', style: InkText.small, textAlign: TextAlign.center),
              ],
            ),
          ),
        const SizedBox(height: 12),
        ButtonRow(
          first: GhostButton(
            label: 'Choose from gallery',
            onPressed: _reading ? null : () => _pick(ImageSource.gallery),
          ),
          second: GhostButton(
            label: 'Photograph a plan',
            onPressed: _reading ? null : () => _pick(ImageSource.camera),
          ),
        ),
        const SizedBox(height: 8),
        GhostButton(
          label: 'Use the example home (Tampines, 142°)',
          onPressed: _reading
              ? null
              : () async {
                  await clearCurrentHome();
                  if (!mounted) return;
                  setState(() {});
                  showInkSnack(context, 'Example home loaded. Your saved plan, if any, is unchanged.');
                },
        ),
        InkstoneCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Front door faces', style: InkText.body(size: 15, color: AppColors.ivory2)),
              const SizedBox(height: 6),
              Row(
                children: [
                  InkIconButton(
                    icon: Icons.remove,
                    semanticLabel: 'Decrease bearing',
                    onTap: () => _nudgeDeg(-1),
                  ),
                  Expanded(
                    child: Text('$_deg° $_dir', textAlign: TextAlign.center, style: InkText.body(size: 17)),
                  ),
                  InkIconButton(
                    icon: Icons.add,
                    semanticLabel: 'Increase bearing',
                    onTap: () => _nudgeDeg(1),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('Rotate the plan so the front door is at the bottom', style: InkText.body(size: 15, color: AppColors.ivory2)),
              Slider(
                value: _rot,
                min: 0,
                max: 359,
                divisions: 359,
                label: '${_rot.round()}°',
                onChanged: _setRot,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final (i, s) in const [
          'Lay the plan flat, in good light.',
          'Show all rooms, including the door.',
          'Stand at the door facing out to take the bearing.',
          'Rotate the photo so the front of the home sits at the bottom of the grid.',
        ].indexed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              border: i == 0 ? null : const Border(top: BorderSide(color: AppColors.hairline)),
            ),
            child: Text(s, style: InkText.small),
          ),
      ],
    );
  }
}
