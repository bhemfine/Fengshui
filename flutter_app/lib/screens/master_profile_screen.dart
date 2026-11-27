import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone/data/sample_data.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

class MasterProfileScreen extends StatefulWidget {
  const MasterProfileScreen({super.key});

  @override
  State<MasterProfileScreen> createState() => _MasterProfileScreenState();
}

class _MasterProfileScreenState extends State<MasterProfileScreen> {
  int _slot = 0;

  @override
  Widget build(BuildContext context) {
    final m = sampleMasters.first;
    return InkstoneScaffold(
      title: 'Master profile',
      showBack: true,
      example: true,
      fallbackRoute: Routes.masters,
      stickyNote:
          'Payment is authorised, not charged, until the master accepts (example).',
      stickyCta: MidnightButton(
        label: 'Request this time',
        onPressed: () =>
            context.push(Routes.bookingPending, extra: sampleSlots[_slot]),
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A2250),
                  border: Border.all(color: AppColors.gold2),
                ),
                child: Text(m.glyph, style: InkText.body(size: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(m.name, style: InkText.display(size: 21)),
                      const ExampleBadge(label: 'Verified'),
                    ],
                  ),
                  Text(
                    m.rating,
                    style: InkText.body(
                      size: 14,
                      color: AppColors.ivory2,
                      height: 1.4,
                    ),
                  ),
                  Text(
                    '${m.languages} · from S\$88 (example)',
                    style: InkText.body(
                      size: 14,
                      color: AppColors.ivory2,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Choose a time', style: InkText.small),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < sampleSlots.length; i++)
              InkChip(
                label: sampleSlots[i],
                selected: _slot == i,
                onTap: () => setState(() => _slot = i),
              ),
          ],
        ),
        InkstoneCard(
          title: 'About',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Twenty years reading homes across Singapore. Calm, practical advice you can act on this week (example).',
                style: InkText.body(height: 1.5),
              ),
              const SizedBox(height: 6),
              Text('Specialities: ${m.specialities}', style: InkText.small),
            ],
          ),
        ),
        InkstoneCard(
          title: 'Reviews',
          example: true,
          child: Column(
            children: [
              for (var i = 0; i < 2; i++)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    border: i > 0
                        ? const Border(
                            top: BorderSide(color: AppColors.hairline),
                          )
                        : null,
                  ),
                  child: Text(
                    i == 0
                        ? '“Clear and kind. Small changes, big calm.” — J.'
                        : '“Explained my chart in plain English.” — R.',
                    style: InkText.body(height: 1.4),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
