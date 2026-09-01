import 'package:flutter/material.dart';

import '../core/responsive/responsive.dart';
import '../theme/app_colors.dart';
import '../widgets/exit_app_scope.dart';
import 'home_screen.dart';
import 'placeholder_screens.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  static const _destinations = [
    _NavDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _NavDestination(
      label: 'Schedule',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month_rounded,
    ),
    _NavDestination(
      label: 'Messages',
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
    ),
    _NavDestination(
      label: 'Care',
      icon: Icons.favorite_outline_rounded,
      selectedIcon: Icons.favorite_rounded,
    ),
    _NavDestination(
      label: 'Me',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final pages = [
      HomeScreen(onNavigateToTab: (i) => setState(() => _index = i)),
      const ScheduleScreen(),
      const MessagesScreen(),
      const CareScreen(),
      const ProfileScreen(),
    ];

    return ExitAppScope(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: responsive.useNavigationRail
            ? Row(
                children: [
                  _AppNavigationRail(
                    index: _index,
                    extended: responsive.width >= 1024,
                    onChanged: (value) => setState(() => _index = value),
                  ),
                  const VerticalDivider(width: 1, color: AppColors.border),
                  Expanded(
                    child: IndexedStack(index: _index, children: pages),
                  ),
                ],
              )
            : IndexedStack(index: _index, children: pages),
        bottomNavigationBar: responsive.useNavigationRail
            ? null
            : _AppBottomNav(
                index: _index,
                onChanged: (value) => setState(() => _index = value),
              ),
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _AppNavigationRail extends StatelessWidget {
  const _AppNavigationRail({
    required this.index,
    required this.extended,
    required this.onChanged,
  });

  final int index;
  final bool extended;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      extended: extended,
      minExtendedWidth: 180,
      backgroundColor: AppColors.surface,
      selectedIndex: index,
      onDestinationSelected: onChanged,
      labelType: extended ? null : NavigationRailLabelType.all,
      selectedIconTheme: const IconThemeData(color: AppColors.primary),
      unselectedIconTheme: const IconThemeData(color: AppColors.iconMuted),
      selectedLabelTextStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: const TextStyle(
        color: AppColors.iconMuted,
        fontWeight: FontWeight.w500,
      ),
      destinations: [
        for (final item in _MainShellState._destinations)
          NavigationRailDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: Text(item.label),
          ),
      ],
    );
  }
}

class _AppBottomNav extends StatelessWidget {
  const _AppBottomNav({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final destinations = _MainShellState._destinations;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            responsive.rz(10),
            responsive.rz(8),
            responsive.rz(10),
            responsive.rz(8),
          ),
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                _NavItem(
                  selected: index == i,
                  icon: destinations[i].selectedIcon,
                  outlinedIcon: destinations[i].icon,
                  label: destinations[i].label,
                  onTap: () => onChanged(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.selected,
    required this.icon,
    required this.outlinedIcon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final color = selected ? AppColors.primary : AppColors.iconMuted;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(vertical: responsive.rz(8)),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryMuted : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? icon : outlinedIcon,
                color: color,
                size: responsive.bottomNavIconSize,
              ),
              SizedBox(height: responsive.rz(4)),
              Text(
                label,
                style: TextStyle(
                  fontSize: responsive.bottomNavLabelSize,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
