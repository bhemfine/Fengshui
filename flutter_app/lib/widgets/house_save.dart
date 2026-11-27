import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'app_scaffold.dart';
import 'gold_button.dart';

/// Bookmark in a screen top bar. Opens the saved-homes list.
Widget savedHomesAction(BuildContext context) => InkIconButton(
  icon: Icons.bookmarks_outlined,
  semanticLabel: 'Saved homes',
  onTap: () => context.push(Routes.savedHomes),
);

/// Ask for a name before saving a result or draft. Returns null if cancelled.
Future<String?> showHouseNameDialog(
  BuildContext context, {
  required String title,
  String initial = '',
  String confirmLabel = 'Save',
}) async {
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => _HouseNameDialog(
      title: title,
      initial: initial,
      confirmLabel: confirmLabel,
    ),
  );
  if (result == null || result.isEmpty) return null;
  return result;
}

class _HouseNameDialog extends StatefulWidget {
  const _HouseNameDialog({
    required this.title,
    required this.initial,
    required this.confirmLabel,
  });
  final String title, initial, confirmLabel;

  @override
  State<_HouseNameDialog> createState() => _HouseNameDialogState();
}

class _HouseNameDialogState extends State<_HouseNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.ink,
      title: Text(widget.title, style: InkText.display(size: 22)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: InkText.body(size: 15),
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Name this home'),
        onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
      ),
      actions: [
        LinkButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        MidnightButton(
          label: widget.confirmLabel,
          expand: false,
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
        ),
      ],
    );
  }
}

Future<bool> confirmHouseDelete(BuildContext context, String name) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.ink,
      title: Text('Delete this home?', style: InkText.display(size: 22)),
      content: Text(
        '“$name” will be removed from this phone. This cannot be undone.',
        style: InkText.body(),
      ),
      actions: [
        LinkButton(
          label: 'Keep it',
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
        MidnightButton(
          label: 'Delete',
          expand: false,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ],
    ),
  );
  return ok == true;
}
