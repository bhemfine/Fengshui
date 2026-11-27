import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone/data/household.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

class ReadingsScreen extends StatelessWidget {
  const ReadingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('✧', 'Tarot', 'Ask a question, draw one or three cards', Routes.tarot),
      ('✋', 'Palm reading', 'Read from your photo', Routes.palm),
      ('四', 'Your BaZi', 'Four pillars, calculated', Routes.bazi),
      (
        '∞',
        'Compatibility',
        '${shortName(mainUser)} and ${shortName(partner)}',
        Routes.compatibility,
      ),
      ('◐', 'Your year', 'Zodiac, Tai Sui and lucky lists', Routes.yearly),
    ];
    return InkstoneScaffold(
      children: [
        const ScreenTitle(
          title: 'Readings',
          subtitle: 'Pick one. Each says where its answer comes from.',
        ),
        for (final r in rows)
          _NavRow(
            glyph: r.$1,
            title: r.$2,
            sub: r.$3,
            onTap: () => context.go(r.$4),
          ),
        const SizedBox(height: 12),
        Text(
          'Tarot, BaZi and Your year are calculated on this phone. Palm and masters are still examples.',
          style: InkText.small,
        ),
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.glyph,
    required this.title,
    required this.sub,
    required this.onTap,
  });
  final String glyph;
  final String title;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Semantics(
      button: true,
      label: '$title, $sub',
      child: Material(
        color: AppColors.cardFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.goldDim),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.goldDim),
                    ),
                    child: Text(
                      glyph,
                      style: InkText.display(size: 18, color: AppColors.gold2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: InkText.display(size: 20)),
                        Text(
                          sub,
                          style: InkText.body(
                            size: 15,
                            color: AppColors.ivory2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.gold),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
