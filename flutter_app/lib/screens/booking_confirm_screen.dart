import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone/data/sample_data.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/screens/booking_pending_screen.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

class BookingConfirmScreen extends StatelessWidget {
  const BookingConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InkstoneScaffold(
      overlay: const StarBurst(origin: Alignment(0, -0.55)),
      children: [
        const ScreenTitle(title: 'Booking confirmed'),
        InkstoneCard(
          child: Row(children: [
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold2),
                boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.08), spreadRadius: 5)],
              ),
              child: Text('24', style: InkText.display(size: 38, color: AppColors.ivory)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(sampleBooking.dateLabel, style: InkText.body(weight: FontWeight.w600)),
                Text(sampleBooking.timeLabel, style: InkText.body()),
                Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text('Video call with ${sampleBooking.master}', style: InkText.small),
                  const ExampleBadge(),
                ]),
              ]),
            ),
          ]),
        ),
        const InkstoneCard(child: BookingTracker(done: 3)),
        const SizedBox(height: 12),
        ButtonRow(
          first: MidnightButton(
              label: 'Add to calendar', onPressed: () => showInkSnack(context, 'Added to calendar (example)')),
          second: GhostButton(
              label: 'View example prescription', onPressed: () => context.push(Routes.prescription)),
        ),
        const SizedBox(height: 8),
        Text('A confirmation email has been sent (example).', style: InkText.small),
        InkstoneCard(
          title: 'What to prepare',
          child: Column(children: [
            for (final (i, s) in const ['Share my charts', 'Have your floor plan nearby', 'Note two questions'].indexed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                    border: i > 0 ? const Border(top: BorderSide(color: AppColors.hairline)) : null),
                child: Text(s, style: InkText.body()),
              ),
          ]),
        ),
      ],
    );
  }
}
