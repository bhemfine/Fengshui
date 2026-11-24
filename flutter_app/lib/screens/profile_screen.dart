import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone/data/sample_data.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _delete(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: AppColors.scrim,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.gold)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Delete my data', style: InkText.h2),
            const SizedBox(height: 8),
            Text('This is a prototype. No real data is stored, so nothing is deleted.', style: InkText.body()),
            const SizedBox(height: 12),
            MidnightButton(label: 'OK', onPressed: () => Navigator.of(ctx).pop()),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget nav(String t, String s, VoidCallback onTap) => InkstoneCard(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          onTap: onTap,
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, style: InkText.display(size: 20)),
                Text(s, style: InkText.body(size: 15, color: AppColors.ivory2)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gold),
          ]),
        );
    Widget row(Widget a, Widget? b, bool first) => Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
              border: first ? null : const Border(top: BorderSide(color: AppColors.hairline))),
          child: Row(children: [Expanded(child: a), if (b != null) Flexible(child: b)]),
        );
    return InkstoneScaffold(
      stickyCta: MidnightButton(label: 'See plans', onPressed: () => context.push(Routes.paywall)),
      children: [
        const ScreenTitle(title: 'Me'),
        InkstoneCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(meiLin.name, style: InkText.body(weight: FontWeight.w600)),
              const ExampleBadge(),
            ]),
            Text('12 Mar 1992, 08:15 · Singapore · ${meiLin.gender}', style: InkText.small),
            LinkButton(label: 'Edit birth details', center: false, onPressed: () => context.go(Routes.birth)),
          ]),
        ),
        nav('Family', 'Wei Hao — birth time unknown',
            () => showInkSnack(context, 'Family details are example only')),
        nav('Bookings', 'Tue 24 Nov with Master Tan', () => context.go(Routes.bookingConfirm)),
        nav('Prescription', 'View example prescription', () => context.go(Routes.prescription)),
        InkstoneCard(
          child: Column(children: [
            row(Text('Current plan', style: InkText.body()),
                Text('Free', style: InkText.body(weight: FontWeight.w600)), true),
            row(
                Text('Notifications', style: InkText.body()),
                LinkButton(
                    label: 'Daily card at 7:00am',
                    center: false,
                    onPressed: () => showInkSnack(context, 'Daily card at 7:00am (example)')),
                false),
            row(
                Text('Language', style: InkText.body()),
                LinkButton(
                    label: 'English',
                    center: false,
                    onPressed: () => showInkSnack(context, 'Only English in this prototype')),
                false),
            row(
                Align(
                  alignment: Alignment.centerLeft,
                  child: LinkButton(
                      label: 'Delete my data',
                      color: AppColors.care,
                      center: false,
                      onPressed: () => _delete(context)),
                ),
                null,
                false),
          ]),
        ),
        const SizedBox(height: 10),
        Text('For guidance and entertainment. Not medical, legal or financial advice.', style: InkText.small),
      ],
    );
  }
}
