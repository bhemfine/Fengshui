import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone/data/sample_data.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

class MastersScreen extends StatefulWidget {
  const MastersScreen({super.key});

  @override
  State<MastersScreen> createState() => _MastersScreenState();
}

class _MastersScreenState extends State<MastersScreen> {
  final Set<String> _sel = {};
  static const _filters = ['Feng shui', 'BaZi', 'English', 'Mandarin'];

  @override
  Widget build(BuildContext context) {
    return InkstoneScaffold(
      children: [
        const ScreenTitle(title: 'Masters'),
        const SizedBox(height: 6),
        Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('Verified practitioners, by video.', style: InkText.body(color: AppColors.ivory2)),
          const ExampleBadge(),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final f in _filters)
            InkChip(
              label: f,
              selected: _sel.contains(f),
              onTap: () => setState(() => _sel.contains(f) ? _sel.remove(f) : _sel.add(f)),
            ),
        ]),
        for (final m in sampleMasters)
          InkstoneCard(
            borderColor: m.tappable ? AppColors.gold : null,
            onTap: m.tappable ? () => context.push(Routes.masterProfile) : null,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Avatar(glyph: m.glyph),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Text(m.name, style: InkText.display(size: 21)),
                    if (m.verified) const ExampleBadge(label: 'Verified'),
                    const ExampleBadge(),
                  ]),
                  for (final s in [m.specialities, m.languages, m.rating, m.price])
                    Text(s, style: InkText.body(size: 14, color: AppColors.ivory2, height: 1.4)),
                ]),
              ),
            ]),
          ),
        LinkButton(label: "View Master Tan's profile", onPressed: () => context.push(Routes.masterProfile)),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.glyph});
  final String glyph;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1A2250),
            border: Border.all(color: AppColors.gold2),
          ),
          child: Text(glyph, style: InkText.body(size: 20)),
        ),
      );
}
