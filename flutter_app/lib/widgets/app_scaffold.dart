import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';
import 'example_badge.dart';
import 'sticky_cta.dart';

/// Transparent screen scaffold: optional top bar (back + title + Example),
/// scrolling body padded 20px, optional sticky CTA.
class InkstoneScaffold extends StatelessWidget {
  const InkstoneScaffold({
    super.key,
    this.title,
    this.showBack = false,
    this.example = false,
    this.actions = const [],
    required this.children,
    this.stickyCta,
    this.stickyNote,
    this.controller,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 28),
    this.fallbackRoute = '/today',
    this.overlay,
  });

  final String? title;
  final bool showBack;
  final bool example;
  final List<Widget> actions;
  final List<Widget> children;
  final Widget? stickyCta;
  final String? stickyNote;
  final ScrollController? controller;
  final EdgeInsetsGeometry padding;
  final String fallbackRoute;

  /// Painted above the body (e.g. StarBurst).
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final hasBar = title != null || showBack;
    final body = Column(
      children: [
        if (hasBar)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  if (showBack) ...[
                    InkIconButton(
                      icon: Icons.chevron_left,
                      semanticLabel: 'Back',
                      onTap: () => context.canPop() ? context.pop() : context.go(fallbackRoute),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(title ?? '',
                        style: InkText.topBar, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  ...actions,
                  if (example) const ExampleBadge(),
                ],
              ),
            ),
          ),
        Expanded(
          child: ListView(
            controller: controller,
            padding: padding,
            children: children,
          ),
        ),
        if (stickyCta != null) StickyCta(note: stickyNote, child: stickyCta!),
      ],
    );
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: stickyCta == null,
        child: overlay == null ? body : Stack(children: [body, Positioned.fill(child: overlay!)]),
      ),
    );
  }
}

/// 40px round icon button with hairline.
class InkIconButton extends StatelessWidget {
  const InkIconButton({super.key, required this.icon, required this.onTap, this.semanticLabel});

  final IconData icon;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: semanticLabel,
        child: Material(
          color: const Color(0xCC121836),
          shape: const CircleBorder(side: BorderSide(color: AppColors.goldDim)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(width: 40, height: 40, child: Icon(icon, color: AppColors.ivory, size: 22)),
          ),
        ),
      );
}

/// Snack helper: goldHi bar; clears any previous one.
void showInkSnack(BuildContext context, String text) {
  final m = ScaffoldMessenger.of(context);
  m.clearSnackBars();
  m.showSnackBar(SnackBar(content: Text(text), duration: const Duration(milliseconds: 2600)));
}
