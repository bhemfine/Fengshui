import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone/data/crash_log.dart';
import 'package:inkstone/data/household.dart';
import 'package:inkstone/data/notifications.dart';
import 'package:inkstone/data/user_data.dart';
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';
import 'package:share_plus/share_plus.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifyOn = false;
  int _hour = DailyNotifications.defaultHour;
  int _minute = DailyNotifications.defaultMinute;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    household.addListener(_onHousehold);
    _load();
  }

  void _onHousehold() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    household.removeListener(_onHousehold);
    super.dispose();
  }

  Future<void> _load() async {
    final p = await DailyNotifications.loadPrefs();
    if (!mounted) return;
    setState(() {
      _notifyOn = p.on;
      _hour = p.hour;
      _minute = p.minute;
      _loaded = true;
    });
  }

  String get _timeLabel {
    final h = _hour % 12 == 0 ? 12 : _hour % 12;
    final am = _hour < 12 ? 'am' : 'pm';
    return '${h.toString().padLeft(1, '0')}:${_minute.toString().padLeft(2, '0')}$am';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _hour = picked.hour;
      _minute = picked.minute;
    });
    try {
      await DailyNotifications.saveTime(hour: _hour, minute: _minute);
      if (_notifyOn) {
        await DailyNotifications.enable(hour: _hour, minute: _minute);
        if (mounted) showInkSnack(context, 'Daily card set for $_timeLabel.');
      }
    } catch (e) {
      if (mounted)
        showInkSnack(context, 'Could not set the reminder. Try again.');
    }
  }

  Future<void> _toggleNotify() async {
    if (!_notifyOn) {
      final ok = await DailyNotifications.requestPermission();
      if (!ok) {
        if (mounted)
          showInkSnack(context, 'Notifications are off in system settings.');
        return;
      }
      try {
        await DailyNotifications.enable(hour: _hour, minute: _minute);
      } catch (e) {
        if (mounted)
          showInkSnack(context, 'Could not set the reminder. Try again.');
        return;
      }
      if (mounted) {
        setState(() => _notifyOn = true);
        showInkSnack(context, 'Daily card set for $_timeLabel.');
      }
    } else {
      await DailyNotifications.cancel();
      if (mounted) setState(() => _notifyOn = false);
    }
  }

  Future<void> _shareCrashes() async {
    final records = await CrashLogStore.load();
    final text = CrashLogStore.shareText(records);
    if (records.isEmpty) {
      if (mounted)
        showInkSnack(context, 'No crash reports are stored on this phone.');
      return;
    }
    await Share.share(text, subject: 'Inkstone crash report');
  }

  void _delete() {
    showDialog<void>(
      context: context,
      barrierColor: AppColors.scrim,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.gold),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Delete my data', style: InkText.h2),
              const SizedBox(height: 8),
              Text(
                'This removes the home you saved (facing, address, floor), saved house results and drafts, checklist answers, the floor-plan photo, daily notification settings, any birth details you typed, and local crash reports from this phone. The profiles reset to Boon Eng and Jiahui. This cannot be undone.',
                style: InkText.body(),
              ),
              const SizedBox(height: 12),
              MidnightButton(
                label: 'Delete everything stored',
                onPressed: () async {
                  await deleteAllUserData();
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) {
                    setState(() => _notifyOn = false);
                    showInkSnack(
                      context,
                      'Saved data on this phone was deleted.',
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              GhostButton(
                label: 'Cancel',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget nav(String t, String s, VoidCallback onTap) => InkstoneCard(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t, style: InkText.display(size: 20)),
                Text(s, style: InkText.body(size: 15, color: AppColors.ivory2)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.gold),
        ],
      ),
    );
    Widget row(Widget a, Widget? b, bool first) => Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: first
            ? null
            : const Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          Expanded(child: a),
          if (b != null) Flexible(child: b),
        ],
      ),
    );
    return InkstoneScaffold(
      stickyCta: MidnightButton(
        label: 'See plans',
        onPressed: () => context.push(Routes.paywall),
      ),
      children: [
        const ScreenTitle(title: 'Me'),
        InkstoneCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    shortName(mainUser),
                    style: InkText.body(weight: FontWeight.w600),
                  ),
                  if (mainUser.example) const ExampleBadge(),
                ],
              ),
              Text(
                '${mainUser.name == shortName(mainUser) ? '' : '${mainUser.name} · '}'
                '${birthLabel(mainUser)} · Singapore · ${genderLabel(mainUser.gender)} · Kua ${mainUser.kua.kua}${mainUser.timeKnown ? '' : ' · birth time unknown'}',
                style: InkText.small,
              ),
              LinkButton(
                label: 'Edit birth details',
                center: false,
                onPressed: () => context.go(Routes.birth),
              ),
            ],
          ),
        ),
        nav(
          'Family',
          '${shortName(partner)} — partner, Kua ${partner.kua.kua}',
          () => showInkSnack(context, 'Family details are example only'),
        ),
        nav(
          'Bookings',
          'Tue 24 Nov with Master Tan',
          () => context.go(Routes.bookingConfirm),
        ),
        nav(
          'Prescription',
          'View example prescription',
          () => context.go(Routes.prescription),
        ),
        InkstoneCard(
          child: Column(
            children: [
              row(
                Text('Current plan', style: InkText.body()),
                Text('Free', style: InkText.body(weight: FontWeight.w600)),
                true,
              ),
              row(
                Text('Notifications', style: InkText.body()),
                LinkButton(
                  label: _loaded
                      ? (_notifyOn
                            ? 'Daily card at $_timeLabel'
                            : 'Off — tap to turn on')
                      : '…',
                  center: false,
                  onPressed: _toggleNotify,
                ),
                false,
              ),
              row(
                Text('Reminder time', style: InkText.body()),
                LinkButton(
                  label: _timeLabel,
                  center: false,
                  onPressed: _pickTime,
                ),
                false,
              ),
              row(
                Text('Language', style: InkText.body()),
                LinkButton(
                  label: 'English',
                  center: false,
                  onPressed: () => showInkSnack(
                    context,
                    'English only. Chinese language is out of scope.',
                  ),
                ),
                false,
              ),
              row(
                Align(
                  alignment: Alignment.centerLeft,
                  child: LinkButton(
                    label: 'Send crash report',
                    center: false,
                    onPressed: _shareCrashes,
                  ),
                ),
                null,
                false,
              ),
              row(
                Align(
                  alignment: Alignment.centerLeft,
                  child: LinkButton(
                    label: 'Delete my data',
                    color: AppColors.care,
                    center: false,
                    onPressed: _delete,
                  ),
                ),
                null,
                false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'For guidance and entertainment. Not medical, legal or financial advice.',
          style: InkText.small,
        ),
      ],
    );
  }
}
