import 'package:flutter/material.dart';
import 'package:inkstone_engine/inkstone_engine.dart';

import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/inkstone_card.dart';
import 'package:inkstone/widgets/term.dart';

/// Popular floor-element note, clearly labelled as not classical Flying Stars.
class FloorElementCard extends StatelessWidget {
  const FloorElementCard({
    super.key,
    this.floorRaw,
    this.floorNumber,
    this.favourable = const [],
    this.unfavourable = const [],
    this.partnerFavourable = const [],
  });

  final String? floorRaw;
  final int? floorNumber;
  final List<FiveElement> favourable;
  final List<FiveElement> unfavourable;
  final List<FiveElement> partnerFavourable;

  @override
  Widget build(BuildContext context) {
    final n = floorElementNote(
      floorRaw: floorRaw,
      floorNumber: floorNumber,
      favourable: favourable,
      unfavourable: unfavourable,
      partnerFavourable: partnerFavourable,
    );
    final color = switch (n.fit) {
      FloorElementFit.favourable => AppColors.good,
      FloorElementFit.unfavourable => AppColors.care,
      FloorElementFit.mixed => AppColors.gold2,
      FloorElementFit.unknown => AppColors.ivory2,
    };
    return InkstoneCard(
      key: const Key('floor-element'),
      title: 'Floor element',
      source: 'Popular belief',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(n.body, style: InkText.body(height: 1.45, color: color)),
        const SizedBox(height: 6),
        Text(FloorElementNote.disclaimer, style: InkText.small),
      ]),
    );
  }
}

/// Tiny helper so screens that already import widgets.dart can show the disclaimer
/// next to a Term if needed.
class FloorElementTerm extends StatelessWidget {
  const FloorElementTerm({super.key});
  @override
  Widget build(BuildContext context) => const Term(
        english: 'Floor element',
        chinese: '层数五行',
        meaning: FloorElementNote.disclaimer,
      );
}
