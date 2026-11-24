import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';

/// English first, then "(中文 — meaning)" muted and smaller.
class Term extends StatelessWidget {
  const Term({
    super.key,
    required this.english,
    required this.chinese,
    this.meaning,
    this.style,
    this.textAlign,
  });

  final String english;
  final String chinese;
  final String? meaning;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final base = style ?? InkText.body();
    final size = base.fontSize ?? 16;
    final muted = InkText.body(size: (size * 0.82).clamp(12, 18).toDouble(), color: AppColors.ivory2, height: base.height);
    final tail = meaning == null ? ' ($chinese)' : ' ($chinese — $meaning)';
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: english, style: base),
        TextSpan(text: tail, style: muted),
      ]),
      textAlign: textAlign,
    );
  }
}
