import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:inkstone_engine/inkstone_engine.dart';

import 'package:inkstone/data/current_home.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';

/// A 3×3 Lo Shu grid laid over the saved plan, with the facing palace at
/// the bottom. The photo can be rotated so the front door sits at the bottom.
class FloorPlanOverlay extends StatelessWidget {
  const FloorPlanOverlay({
    super.key,
    required this.home,
    this.image,
    this.selected,
    this.onZoneTap,
    this.height = 320,
  });

  final CurrentHome home;
  final File? image;
  final int? selected;
  final ValueChanged<int>? onZoneTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final facing = nearestPalace(home.facingDegrees);
    final order = palacesInGridOrder(facing);
    final chart = home.chart;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: const Color(0xE60B1026), child: _photo(facing)),
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                  itemCount: 9,
                  itemBuilder: (context, i) {
                    final d = order[i];
                    final stars = chart.palaces[d]!;
                    final sel = selected == i;
                    return GestureDetector(
                      onTap: onZoneTap == null ? null : () => onZoneTap!(i),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: sel ? AppColors.gold2 : AppColors.gold.withValues(alpha: 0.45),
                            width: sel ? 2 : 0.7,
                          ),
                          color: sel ? AppColors.gold.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.15),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              d == Direction.centre ? 'Centre' : directionShort[d]!,
                              style: InkText.small.copyWith(
                                color: AppColors.gold2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              d == facing ? 'Facing' : (d == oppositeDirection[facing] ? 'Sitting' : ''),
                              style: InkText.small.copyWith(color: AppColors.ivory2, fontSize: 10),
                            ),
                            Text(
                              '${stars.mountain} / ${stars.facing}',
                              style: InkText.body(size: 13, color: AppColors.ivory),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Facing ${directionLong[facing]} at the bottom. Mountain / water stars shown. '
          'Rotate the plan so the front door is at the bottom.',
          style: InkText.small,
        ),
      ],
    );
  }

  Widget _photo(Direction facing) {
    if (image == null || !image!.existsSync()) {
      return const SizedBox.expand();
    }
    final rad = home.planRotationDeg * math.pi / 180;
    return Transform.rotate(
      angle: rad,
      child: Image.file(image!, fit: BoxFit.contain),
    );
  }
}
