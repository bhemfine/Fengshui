import 'package:flutter/material.dart';
import 'package:inkstone/data/sample_data.dart';
import 'package:inkstone/motion/motion.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final Set<String> _sel = {};

  @override
  Widget build(BuildContext context) {
    final items = sampleShopItems.where((i) => _sel.isEmpty || _sel.contains(i.category)).toList();
    return InkstoneScaffold(
      title: 'Remedies',
      showBack: true,
      example: true,
      fallbackRoute: Routes.floorResult,
      children: [
        const NoMedicineBanner(),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in shopCategories)
            InkChip(
              label: c,
              selected: _sel.contains(c),
              onTap: () => setState(() => _sel.contains(c) ? _sel.remove(c) : _sel.add(c)),
            ),
        ]),
        InkstoneCard(
          title: 'From your home reading',
          example: true,
          child: Column(children: [
            if (items.isEmpty) Text('No items in this filter.', style: InkText.small),
            for (var i = 0; i < items.length; i++)
              ShopRow(
                glyph: items[i].glyph,
                name: items[i].name,
                note: items[i].note,
                price: '${items[i].price} (example)',
                divider: i > 0,
              ),
          ]),
        ),
        const SizedBox(height: 10),
        Text('Nothing is added unless you tap Buy. No checkout in this prototype.', style: InkText.small),
      ],
    );
  }
}

/// Apricot "not medicine" banner (public within the screens library usage).
class NoMedicineBanner extends StatelessWidget {
  const NoMedicineBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.care.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.care.withValues(alpha: 0.45)),
        ),
        child: Text('Remedies are optional. They are not medicine.', style: InkText.body(size: 15)),
      );
}

/// Item row with shimmering thumb and optional Buy (snack only, never auto-added).
class ShopRow extends StatelessWidget {
  const ShopRow({super.key, required this.glyph, required this.name, this.note, required this.price, this.divider = false});
  final String glyph;
  final String name;
  final String? note;
  final String price;
  final bool divider;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: divider ? const Border(top: BorderSide(color: AppColors.hairline)) : null,
        ),
        child: Row(children: [
          ShimmerThumb(glyph: glyph),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: InkText.body(weight: FontWeight.w600)),
              if (note != null) Text(note!, style: InkText.body(size: 14, color: AppColors.ivory2, height: 1.35)),
              Text(price, style: InkText.body(size: 14, color: AppColors.gold2, height: 1.35)),
            ]),
          ),
          const SizedBox(width: 8),
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => showInkSnack(context, 'Added to your list — you can remove it any time (example)'),
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.primaryTop, AppColors.primaryBottom]),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.75)),
                ),
                child: Text('Buy', style: InkText.body(size: 15, weight: FontWeight.w600)),
              ),
            ),
          ),
        ]),
      );
}

class ShimmerThumb extends StatefulWidget {
  const ShimmerThumb({super.key, required this.glyph});
  final String glyph;

  @override
  State<ShimmerThumb> createState() => _ShimmerThumbState();
}

class _ShimmerThumbState extends State<ShimmerThumb> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Motion.shimmer);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c
        ..stop()
        ..value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.goldDim),
            gradient: const RadialGradient(
                center: Alignment(-0.2, -0.3), colors: [Color(0xFF2A3366), AppColors.ink2]),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(alignment: Alignment.center, children: [
              Text(widget.glyph, style: InkText.display(size: 22, color: AppColors.gold2)),
              AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final t = _c.value < 0.55 ? 0.0 : (_c.value - 0.55) / 0.45;
                  if (t == 0) return const SizedBox.expand();
                  return FractionalTranslation(
                    translation: Offset(-1.2 + 2.4 * t, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          const Color(0x00EFE6D2),
                          AppColors.goldHi.withValues(alpha: 0.35),
                          const Color(0x00EFE6D2),
                        ], stops: const [0.4, 0.5, 0.6]),
                      ),
                    ),
                  );
                },
              ),
            ]),
          ),
        ),
      );
}
