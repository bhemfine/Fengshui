import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone/data/household.dart';
import 'package:inkstone/data/onboarding.dart';
import 'package:inkstone_engine/inkstone_engine.dart' show Gender;
import 'package:inkstone/router.dart';
import 'package:inkstone/theme/colors.dart';
import 'package:inkstone/theme/typography.dart';
import 'package:inkstone/widgets/widgets.dart';

class BirthScreen extends StatefulWidget {
  const BirthScreen({super.key});
  @override
  State<BirthScreen> createState() => _BirthScreenState();
}

class _BirthScreenState extends State<BirthScreen> {
  final _name = TextEditingController(text: mainUser.name);
  final _place = TextEditingController(text: 'Singapore · UTC+8');
  DateTime _birth = mainUser.birth;
  String _gender = genderLabel(mainUser.gender);
  bool _unknown = !mainUser.timeKnown;

  String get _dateLabel =>
      '${_birth.day} ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][_birth.month - 1]} ${_birth.year}';

  String get _timeLabel =>
      '${_birth.hour.toString().padLeft(2, '0')}:${_birth.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _name.dispose();
    _place.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(_birth.year, _birth.month, _birth.day),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (d == null || !mounted) return;
    setState(() {
      _birth = DateTime(d.year, d.month, d.day, _birth.hour, _birth.minute);
    });
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _birth.hour, minute: _birth.minute),
    );
    if (t == null || !mounted) return;
    setState(() {
      _birth = DateTime(
        _birth.year,
        _birth.month,
        _birth.day,
        t.hour,
        t.minute,
      );
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim().isEmpty
        ? defaultMainUser.name
        : _name.text.trim();
    final gender = _gender == 'Male' ? Gender.male : Gender.female;
    final timeKnown = !_unknown;
    final birth = DateTime(
      _birth.year,
      _birth.month,
      _birth.day,
      timeKnown ? _birth.hour : 12,
      timeKnown ? _birth.minute : 0,
    );
    final person = KuaPerson(
      name: name,
      birth: birth,
      gender: gender,
      saved: true,
      timeKnown: timeKnown,
      example:
          name == defaultMainUser.name &&
          gender == defaultMainUser.gender &&
          timeKnown == defaultMainUser.timeKnown &&
          birth.year == defaultMainUser.birth.year &&
          birth.month == defaultMainUser.birth.month &&
          birth.day == defaultMainUser.birth.day,
    );
    await setMainUser(person);
    await markOnboardingComplete();
    if (mounted) context.go(Routes.today);
  }

  Widget _field(String label, Widget input) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: InkText.body(size: 15, color: AppColors.ivory2)),
        const SizedBox(height: 5),
        input,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final style = InkText.body(size: 15);
    return InkstoneScaffold(
      title: 'Your birth details',
      showBack: true,
      example: mainUser.example,
      fallbackRoute: Routes.welcome,
      stickyCta: MidnightButton(label: 'Save and see today', onPressed: _save),
      children: [
        _field('Name', TextField(controller: _name, style: style)),
        _field(
          'Gender (for Kua number)',
          DropdownButtonFormField<String>(
            initialValue: _gender,
            dropdownColor: AppColors.ink2,
            style: style,
            items: const [
              DropdownMenuItem(value: 'Female', child: Text('Female')),
              DropdownMenuItem(value: 'Male', child: Text('Male')),
            ],
            onChanged: (v) => setState(() => _gender = v ?? _gender),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _field(
                'Date of birth',
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(),
                    child: Text(_dateLabel, style: style),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _field(
                'Time',
                InkWell(
                  onTap: _unknown ? null : _pickTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(),
                    child: Text(
                      _unknown ? 'Unknown' : _timeLabel,
                      style: style,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => setState(() => _unknown = !_unknown),
          child: Row(
            children: [
              Checkbox(
                value: _unknown,
                onChanged: (v) => setState(() => _unknown = v ?? false),
              ),
              Expanded(
                child: Text(
                  "I don't know my birth time",
                  style: InkText.body(),
                ),
              ),
            ],
          ),
        ),
        if (_unknown)
          Text(
            'Hour pillar will be left out. Add it any time in Me.',
            style: InkText.body(size: 14, color: AppColors.care),
          ),
        _field('Place of birth', TextField(controller: _place, style: style)),
        const SizedBox(height: 10),
        Text(
          'You can delete these details any time in Me.',
          style: InkText.small,
        ),
      ],
    );
  }
}
