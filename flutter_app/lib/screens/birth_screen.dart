import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstone/data/sample_data.dart';
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
  final _name = TextEditingController(text: meiLin.name);
  final _date = TextEditingController(text: '12 Mar 1992');
  final _time = TextEditingController(text: '08:15');
  final _place = TextEditingController(text: meiLin.place);
  String _gender = 'Female';
  bool _unknown = false;

  @override
  void dispose() {
    _name.dispose();
    _date.dispose();
    _time.dispose();
    _place.dispose();
    super.dispose();
  }

  Widget _field(String label, Widget input) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: InkText.body(size: 15, color: AppColors.ivory2)),
          const SizedBox(height: 5),
          input,
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final style = InkText.body(size: 15);
    return InkstoneScaffold(
      title: 'Your birth details',
      showBack: true,
      example: true,
      fallbackRoute: Routes.welcome,
      stickyCta: MidnightButton(label: 'Save and see today', onPressed: () => context.go(Routes.today)),
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
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _field('Date of birth', TextField(controller: _date, style: style))),
          const SizedBox(width: 10),
          Expanded(child: _field('Time', TextField(controller: _time, style: style, enabled: !_unknown))),
        ]),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => setState(() => _unknown = !_unknown),
          child: Row(children: [
            Checkbox(value: _unknown, onChanged: (v) => setState(() => _unknown = v ?? false)),
            Expanded(child: Text("I don't know my birth time", style: InkText.body())),
          ]),
        ),
        if (_unknown)
          Text('Hour pillar will be left out. Add it any time in Me.',
              style: InkText.body(size: 14, color: AppColors.care)),
        _field('Place of birth', TextField(controller: _place, style: style)),
        const SizedBox(height: 10),
        Text('You can delete these details any time in Me.', style: InkText.small),
      ],
    );
  }
}
