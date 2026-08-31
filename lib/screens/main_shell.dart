import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onNavigateToTab: (i) => setState(() => _index = i)),
          const ScheduleScreen(),
          const MessagesScreen(),
          const CareScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _AppBottomNav(
        index: _index,
        onChanged: (value) => setState(() => _index = value),
      ),
    );
  }
}

class _AppBottomNav extends StatelessWidget {
  const _AppBottomNav({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: [
              _NavItem(
                selected: index == 0,
                icon: Icons.home_rounded,
                outlinedIcon: Icons.home_outlined,
                label: 'Home',
                onTap: () => onChanged(0),
              ),
              _NavItem(
                selected: index == 1,
                icon: Icons.calendar_month_rounded,
                outlinedIcon: Icons.calendar_month_outlined,
                label: 'Schedule',
                onTap: () => onChanged(1),
              ),
              _NavItem(
                selected: index == 2,
                icon: Icons.chat_bubble_rounded,
                outlinedIcon: Icons.chat_bubble_outline_rounded,
                label: 'Messages',
                onTap: () => onChanged(2),
              ),
              _NavItem(
                selected: index == 3,
                icon: Icons.favorite_rounded,
                outlinedIcon: Icons.favorite_outline_rounded,
                label: 'Care',
                onTap: () => onChanged(3),
              ),
              _NavItem(
                selected: index == 4,
                icon: Icons.person_rounded,
                outlinedIcon: Icons.person_outline_rounded,
                label: 'Me',
                onTap: () => onChanged(4),
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
    final color = selected ? AppColors.primary : AppColors.iconMuted;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryMuted : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? icon : outlinedIcon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
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
