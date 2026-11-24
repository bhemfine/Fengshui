import 'package:flutter/material.dart';
import 'package:inkstone/data/sample_data.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/screens/shop_screen.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

class PrescriptionScreen extends StatelessWidget {
  const PrescriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InkstoneScaffold(
      title: 'Master Tan',
      showBack: true,
      example: true,
      fallbackRoute: Routes.masters,
      children: [
        Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('Session 24 Nov 2026', style: InkText.small),
          const SourceBadge(label: SourceBadge.masterTan),
        ]),
        InkstoneCard(
          child: Column(children: [
            for (var i = 0; i < samplePrescription.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                    border: i > 0 ? const Border(top: BorderSide(color: AppColors.hairline)) : null),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, border: Border.all(color: AppColors.gold2)),
                    child: Text('${i + 1}', style: InkText.body(size: 13, color: AppColors.gold2, height: 1)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(samplePrescription[i].title, style: InkText.body(weight: FontWeight.w600)),
                      Text(samplePrescription[i].detail, style: InkText.small),
                    ]),
                  ),
                ]),
              ),
          ]),
        ),
        const InkstoneCard(
          title: 'Suggested items (optional)',
          child: Column(children: [
            ShopRow(glyph: '⚱', name: 'Brass wu lou', price: 'S\$32 (example)'),
            ShopRow(glyph: '❦', name: 'Small money plant', price: 'S\$12 (example)', divider: true),
          ]),
        ),
        const SizedBox(height: 10),
        const NoMedicineBanner(),
      ],
    );
  }
}
