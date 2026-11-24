import 'package:flutter/material.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  static const _rows = <(String, String, String)>[
    ('Profile and basic BaZi', '✓', '✓'),
    ('Daily card', '✓', '✓'),
    ('Tarot', '1 a day', 'Unlimited'),
    ('Full month and year forecasts', '—', '✓'),
    ('Home analyser', '—', '✓'),
    ('Compatibility', '—', '✓'),
    ('Unlimited Ask the Master', '—', '✓'),
    ('Ad-free', '—', '✓'),
  ];

  @override
  Widget build(BuildContext context) {
    final th = InkText.display(size: 17, color: AppColors.gold2);
    final td = InkText.body(size: 15);
    TableRow r(String a, String b, String c, {bool head = false}) => TableRow(
          decoration: head ? null : const BoxDecoration(border: Border(top: BorderSide(color: AppColors.hairline))),
          children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4), child: Text(a, style: head ? th : td)),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                child: Text(b, textAlign: TextAlign.center, style: head ? th : td)),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                child: Text(c, textAlign: TextAlign.center, style: head ? th : td)),
          ],
        );
    return InkstoneScaffold(
      title: 'Your plan',
      showBack: true,
      example: true,
      fallbackRoute: Routes.profile,
      children: [
        Text('Free covers the basics. Premium opens everything.', style: InkText.body(color: AppColors.ivory2)),
        const SizedBox(height: 12),
        MidnightButton(
          label: 'Subscribe',
          pulse: true,
          onPressed: () => showInkSnack(context, 'Google Play Billing comes in phase 6'),
        ),
        InkstoneCard(
          child: Table(
            columnWidths: const {0: FlexColumnWidth(2.2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1.3)},
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              r('Feature', 'Free', 'Premium', head: true),
              for (final x in _rows) r(x.$1, x.$2, x.$3),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('Price is shown when you choose a plan. Example only — not billed in this prototype.',
            style: InkText.small),
        LinkButton(
            label: 'Restore purchases', onPressed: () => showInkSnack(context, 'Nothing to restore (example)')),
      ],
    );
  }
}
