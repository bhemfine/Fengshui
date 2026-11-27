import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone/data/current_home.dart';
import 'package:inkstone/data/house_records.dart';
import 'package:inkstone/data/quick_check.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/house_save.dart';
import 'package:inkstone/widgets/widgets.dart';

class SavedHomesScreen extends StatelessWidget {
  const SavedHomesScreen({super.key});

  Future<void> _open(BuildContext context, HouseRecord record) async {
    if (record.isDraft) {
      context.push(Routes.quickCheck, extra: record);
      return;
    }
    if (record.home != null && !record.home!.example) {
      await setCurrentHome(record.home!);
    }
    if (!context.mounted) return;
    if (record.quickCheck != null) {
      context.push(
        Routes.quickCheckResult,
        extra: QuickCheckResultArgs(
          input: record.quickCheck!,
          recordId: record.id,
        ),
      );
    } else {
      context.go(Routes.houseCheck);
    }
  }

  Future<void> _rename(BuildContext context, HouseRecord record) async {
    final name = await showHouseNameDialog(
      context,
      title: 'Rename',
      initial: record.name,
      confirmLabel: 'Rename',
    );
    if (name == null) return;
    await renameHouseRecord(record.id, name);
  }

  Future<void> _delete(BuildContext context, HouseRecord record) async {
    if (!await confirmHouseDelete(context, record.name)) return;
    await removeHouseRecord(record.id);
    if (context.mounted) showInkSnack(context, 'Removed ${record.name}');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<HouseRecord>>(
      valueListenable: houseRecords,
      builder: (context, records, _) {
        final results = [
          for (final r in records)
            if (!r.isDraft) r,
        ];
        final drafts = [
          for (final r in records)
            if (r.isDraft) r,
        ];
        return InkstoneScaffold(
          title: 'Saved homes',
          showBack: true,
          fallbackRoute: Routes.floorUpload,
          children: [
            Text(
              'Results and drafts stay on this phone. Nothing is uploaded.',
              style: InkText.small,
            ),
            if (records.isEmpty) ...[
              const SizedBox(height: 24),
              InkstoneCard(
                child: Text(
                  'No saved homes yet. After a house check or quick check, tap Save result. Mid-way through a quick check, tap Save draft to pick it up later.',
                  style: InkText.body(),
                ),
              ),
            ] else ...[
              if (results.isNotEmpty) ...[
                const SectionHeader(title: 'Saved results'),
                for (final r in results) _tile(context, r),
              ],
              if (drafts.isNotEmpty) ...[
                const SectionHeader(title: 'Drafts'),
                for (final r in drafts) _tile(context, r),
              ],
            ],
          ],
        );
      },
    );
  }

  Widget _tile(BuildContext context, HouseRecord record) {
    return InkstoneCard(
      key: Key('saved-home-${record.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(record.name, style: InkText.display(size: 22)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.goldDim),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  record.isDraft ? 'Draft' : 'Result',
                  style: InkText.small,
                ),
              ),
            ],
          ),
          if (record.summary != null && record.summary!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(record.summary!, style: InkText.small),
          ],
          const SizedBox(height: 10),
          ButtonRow(
            first: MidnightButton(
              label: record.isDraft ? 'Continue draft' : 'Open',
              onPressed: () => _open(context, record),
            ),
            second: GhostButton(
              label: 'Rename',
              onPressed: () => _rename(context, record),
            ),
          ),
          const SizedBox(height: 8),
          GhostButton(
            label: 'Delete',
            onPressed: () => _delete(context, record),
          ),
        ],
      ),
    );
  }
}
