import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone/data/sample_data.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

class BookingPendingScreen extends StatelessWidget {
  const BookingPendingScreen({super.key, this.slot});

  /// The time the user picked on the profile screen.
  final String? slot;

  String get _slot =>
      (slot != null && slot!.trim().isNotEmpty) ? slot! : sampleSlots.first;

  @override
  Widget build(BuildContext context) {
    return InkstoneScaffold(
      children: [
        const ScreenTitle(
          title: 'Request sent',
          subtitle:
              'Waiting for Master Tan. Most masters reply within a few hours.',
        ),
        const InkstoneCard(child: BookingTracker(done: 0, current: 0)),
        InkstoneCard(
          child: Text(
            '$_slot · ${sampleBooking.duration} · ${sampleBooking.price}.',
            style: InkText.body(height: 1.5),
          ),
        ),
        const SizedBox(height: 12),
        MidnightButton(
          label: 'Back to Today',
          onPressed: () => context.go(Routes.today),
        ),
        const SizedBox(height: 12),
        GhostButton(
          label: 'Cancel request',
          onPressed: () => showInkSnack(context, 'Request cancelled (example)'),
        ),
        LinkButton(
          label: 'Preview: master accepts (example)',
          onPressed: () => context.push(Routes.bookingConfirm, extra: _slot),
        ),
      ],
    );
  }
}

/// Requested → Accepted → Confirmed. Steps < done are mint; `current` outlined.
class BookingTracker extends StatelessWidget {
  const BookingTracker({super.key, required this.done, this.current});
  final int done;
  final int? current;

  @override
  Widget build(BuildContext context) {
    const labels = ['Requested', 'Accepted', 'Confirmed'];
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 11,
          child: FractionallySizedBox(
            widthFactor: 0.76,
            child: Container(height: 1, color: AppColors.goldDim),
          ),
        ),
        Row(
          children: [
            for (var i = 0; i < 3; i++)
              Expanded(
                child: Semantics(
                  label:
                      '${labels[i]}${i < done ? ', done' : ''}${i == current ? ', current' : ''}',
                  child: ExcludeSemantics(
                    child: Column(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < done ? AppColors.good : AppColors.ink,
                            border: Border.all(
                              color: i < done
                                  ? AppColors.good
                                  : i == current
                                  ? AppColors.gold2
                                  : AppColors.goldDim,
                            ),
                            boxShadow: i == current
                                ? [
                                    BoxShadow(
                                      color: AppColors.gold2.withValues(
                                        alpha: 0.12,
                                      ),
                                      spreadRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          labels[i],
                          style: InkText.body(
                            size: 14,
                            color: (i < done || i == current)
                                ? AppColors.ivory
                                : AppColors.ivory2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
