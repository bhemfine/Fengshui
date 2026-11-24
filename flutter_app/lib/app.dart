import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/colors.dart';
import 'widgets/starfield.dart';

/// Root app: dark only, starfield painted behind every route.
class InkstoneApp extends StatelessWidget {
  const InkstoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = buildInkTheme();
    return MaterialApp.router(
      title: 'Inkstone',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
      builder: (context, child) => Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.ink),
          const Starfield(),
          if (child != null) child,
        ],
      ),
    );
  }
}
