import 'dart:math';

import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// Primary button: midnight gradient, champagne edge, quiet glint, optional pulse.
class MidnightButton extends StatefulWidget {
  const MidnightButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.pulse = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool pulse;
  final bool expand;

  @override
  State<MidnightButton> createState() => _MidnightButtonState();
}

class _MidnightButtonState extends State<MidnightButton> with TickerProviderStateMixin {
  late final AnimationController _glint = AnimationController(vsync: this, duration: Motion.glint);
  late final AnimationController _pulse = AnimationController(vsync: this, duration: Motion.pulse);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _glint
        ..stop()
        ..value = 0;
      _pulse
        ..stop()
        ..value = 0;
    } else {
      if (!_glint.isAnimating) _glint.repeat();
      if (widget.pulse && !_pulse.isAnimating) _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _glint.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final radius = BorderRadius.circular(14);
    final button = Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryTop, AppColors.primaryBottom],
          ),
          borderRadius: radius,
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.75)),
          boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.07), spreadRadius: 3)],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onPressed,
              splashColor: AppColors.goldHi.withValues(alpha: 0.08),
              child: CustomPaint(
                foregroundPainter: _GlintPainter(_glint),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: _ButtonLabel(
                      label: widget.label, icon: widget.icon, expand: widget.expand, color: AppColors.ivory),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) => Transform.scale(
          scale: 1 + 0.015 * (0.5 - 0.5 * cos(2 * pi * _pulse.value)),
          child: child,
        ),
        child: button,
      ),
    );
  }
}

class _GlintPainter extends CustomPainter {
  _GlintPainter(this.anim) : super(repaint: anim);
  final Animation<double> anim;

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    if (t < 0.8) return;
    final p = ((t - 0.8) / 0.16).clamp(0.0, 1.0);
    final w = size.width;
    final cx = -0.3 * w + p * 1.6 * w;
    final rect = Rect.fromLTRB(cx - 0.3 * w, 0, cx + 0.3 * w, size.height);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment(-1, -0.3),
        end: Alignment(1, 0.3),
        colors: [Color(0x00E8DEC6), Color(0x1FE8DEC6), Color(0x00E8DEC6)],
      ).createShader(rect);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _GlintPainter old) => false;
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({required this.label, this.icon, required this.expand, required this.color});
  final String label;
  final IconData? icon;
  final bool expand;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 20, color: color), const SizedBox(width: 10)],
        Flexible(
          child: Text(label,
              textAlign: TextAlign.center,
              style: InkText.button.copyWith(color: color)),
        ),
      ],
    );
  }
}

/// Secondary button: transparent fill, hairline edge, ivory label.
class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, this.onPressed, this.icon, this.expand = true});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Opacity(
      opacity: onPressed != null ? 1 : 0.5,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Container(
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: AppColors.ivory2.withValues(alpha: 0.3)),
            ),
            child: _ButtonLabel(label: label, icon: icon, expand: expand, color: AppColors.ivory),
          ),
        ),
      ),
    );
  }
}

/// Underlined text button (champagne by default).
class LinkButton extends StatelessWidget {
  const LinkButton({super.key, required this.label, this.onPressed, this.color = AppColors.gold2, this.center = true});

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final child = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Text(label,
            style: InkText.body(size: 16, weight: FontWeight.w600, color: color).copyWith(
              decoration: TextDecoration.underline,
              decorationColor: color,
            )),
      ),
    );
    return center ? Center(child: child) : child;
  }
}

/// Two buttons side by side with 10px gap.
class ButtonRow extends StatelessWidget {
  const ButtonRow({super.key, required this.first, required this.second});
  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: first), const SizedBox(width: 10), Expanded(child: second)],
      );
}
