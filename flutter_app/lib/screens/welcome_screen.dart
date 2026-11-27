import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone/data/onboarding.dart';
import 'package:inkstone/motion/motion.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InkstoneScaffold(
      children: [
        const SizedBox(height: 6),
        const Center(child: _Seal()),
        const SizedBox(height: 6),
        Text(
          'Inkstone',
          textAlign: TextAlign.center,
          style: InkText.display(size: 40, height: 1.1),
        ),
        const SizedBox(height: 6),
        Text(
          'Your almanac, your home, your chart. Plainly told.',
          textAlign: TextAlign.center,
          style: InkText.body(size: 18, color: AppColors.ivory2),
        ),
        const InkstoneCard(
          child: Column(
            children: [
              _Point(
                glyph: '✦',
                title: 'Calculated',
                text: 'Almanac, BaZi and Kua come from your birth details.',
              ),
              _Point(
                glyph: '◎',
                title: 'Read from your photo',
                text: 'Floor plans and palms, read then deleted.',
                top: true,
              ),
              _Point(
                glyph: '谭',
                title: 'Real masters',
                text: 'Book verified practitioners by video.',
                top: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        MidnightButton(
          label: 'Begin',
          pulse: true,
          onPressed: () => context.go(Routes.birth),
        ),
        LinkButton(
          label: 'I have an account — sign in',
          onPressed: () async {
            await markOnboardingComplete();
            if (context.mounted) context.go(Routes.today);
          },
        ),
        Text(
          'For guidance and entertainment. Not medical, legal or financial advice.',
          textAlign: TextAlign.center,
          style: InkText.small,
        ),
      ],
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({
    required this.glyph,
    required this.title,
    required this.text,
    this.top = false,
  });
  final String glyph;
  final String title;
  final String text;
  final bool top;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 11),
    decoration: BoxDecoration(
      border: top
          ? const Border(top: BorderSide(color: AppColors.hairline))
          : null,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Container(
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
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: InkText.body(weight: FontWeight.w600)),
              Text(text, style: InkText.small),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Seal extends StatefulWidget {
  const _Seal();
  @override
  State<_Seal> createState() => _SealState();
}

class _SealState extends State<_Seal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.ringSlow,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
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
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Seal 砚 — Inkstone',
      child: SizedBox(
        width: 150,
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            RotationTransition(
              turns: _c,
              child: Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.6),
                  ),
                ),
                alignment: Alignment.topCenter,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.goldHi,
                  ),
                ),
              ),
            ),
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4),
                ),
              ),
            ),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ink2,
                border: Border.all(color: AppColors.gold2),
              ),
              child: ExcludeSemantics(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '砚',
                      style: InkText.body(
                        size: 40,
                        color: AppColors.ivory,
                        height: 1,
                      ),
                    ),
                    Text(
                      'Inkstone',
                      style: InkText.display(
                        size: 13,
                        color: AppColors.gold2,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
