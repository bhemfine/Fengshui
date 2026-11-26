import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// Horizontal strip of 12 double hours; current hour outlined and scrolled into view.
class DoubleHourStrip extends StatefulWidget {
  const DoubleHourStrip({super.key, required this.hours, required this.currentIndex});

  final List<DoubleHour> hours;
  final int currentIndex;

  @override
  State<DoubleHourStrip> createState() => _DoubleHourStripState();
}

class _DoubleHourStripState extends State<DoubleHourStrip> {
  static const _w = 72.0;
  static const _gap = 8.0;
  final _ctrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_ctrl.hasClients) return;
      final pos = _ctrl.position;
      final target = widget.currentIndex * (_w + _gap) - pos.viewportDimension / 2 + _w / 2;
      _ctrl.jumpTo(target.clamp(0.0, pos.maxScrollExtent));
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        controller: _ctrl,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(2, 6, 2, 8),
        itemCount: widget.hours.length,
        separatorBuilder: (_, __) => const SizedBox(width: _gap),
        itemBuilder: (context, i) {
          final h = widget.hours[i];
          final now = i == widget.currentIndex;
          return Semantics(
            label: '${h.english} hour, ${h.range}${h.isGood ? ', good' : ''}${now ? ', now' : ''}',
            child: Container(
              width: _w,
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              decoration: BoxDecoration(
                color: const Color(0xB30E1430),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: now ? AppColors.gold2 : AppColors.goldDim),
                boxShadow: now ? [BoxShadow(color: AppColors.gold2.withValues(alpha: 0.28), spreadRadius: 2)] : null,
              ),
              child: ExcludeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(h.chinese,
                        style: InkText.display(size: 22, color: h.isGood ? AppColors.good : AppColors.ivory, height: 1.1)),
                    Text(h.english, style: InkText.body(size: 12, color: AppColors.ivory2, height: 1.3)),
                    Text(h.range, style: InkText.body(size: 11, color: AppColors.ivory2, height: 1.3)),
                    const SizedBox(height: 3),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: h.isGood ? AppColors.good : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
