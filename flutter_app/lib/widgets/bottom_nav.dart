import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';

class _NavItem {
  const _NavItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

const _items = [
  _NavItem('Today', Icons.adjust),
  _NavItem('Home', Icons.home_outlined),
  _NavItem('Readings', Icons.style_outlined),
  _NavItem('Masters', Icons.person_outline),
  _NavItem('Me', Icons.account_circle_outlined),
];

/// 5-item tab bar: champagne selected, ivory2 unselected, Source Serif 600 labels.
class InkBottomNav extends StatelessWidget {
  const InkBottomNav({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.navFill,
        border: Border(top: BorderSide(color: AppColors.goldDim)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(child: _Tab(item: _items[i], selected: i == currentIndex, onTap: () => onTap(i))),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.selected, required this.onTap});
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.goldHi : AppColors.ivory2;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon,
                  size: 22,
                  color: color,
                  shadows: selected ? [Shadow(color: AppColors.gold2.withValues(alpha: 0.5), blurRadius: 4)] : null),
              const SizedBox(height: 3),
              Text(item.label, style: InkText.tab.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
