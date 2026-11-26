import 'package:flutter/material.dart';

import 'data/share_intent.dart';
import 'router.dart';
import 'screens/listing_import_screen.dart' show ListingImportArgs;
import 'theme/app_theme.dart';
import 'theme/colors.dart';
import 'widgets/starfield.dart';

/// Root app: dark only, starfield painted behind every route.
class InkstoneApp extends StatefulWidget {
  const InkstoneApp({super.key});

  @override
  State<InkstoneApp> createState() => _InkstoneAppState();
}

class _InkstoneAppState extends State<InkstoneApp> {
  @override
  void initState() {
    super.initState();
    // A listing link shared from another app opens the import screen.
    ShareIntent.listen((text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appRouter.push(Routes.listingImport, extra: ListingImportArgs(text: text));
      });
    });
  }

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
