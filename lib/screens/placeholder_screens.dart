import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'sign_in_screen.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SimpleScreen(
      title: 'Schedule',
      subtitle: 'Upcoming visits with your care team',
      children: const [
        _ListTileCard(
          icon: Icons.videocam_outlined,
          title: 'Today, 2:00 PM',
          subtitle: 'Video visit  ·  Maya Patel, LCSW-C',
        ),
        _ListTileCard(
          icon: Icons.location_on_outlined,
          title: 'Thu, May 15  ·  10:00 AM',
          subtitle: 'In-person  ·  Divine Counseling',
        ),
        _ListTileCard(
          icon: Icons.videocam_outlined,
          title: 'Tue, May 20  ·  2:00 PM',
          subtitle: 'Telehealth  ·  Maya Patel, LCSW-C',
        ),
      ],
    );
  }
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimpleScreen(
      title: 'Messages',
      subtitle: 'Secure messages from your clinic',
      children: [
        _ListTileCard(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Divine Counseling',
          subtitle: 'Reminder: complete PHQ-9 before Friday',
          trailing: '1h',
        ),
        _ListTileCard(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Maya Patel, LCSW-C',
          subtitle: 'Looking forward to our session today.',
          trailing: 'Yesterday',
        ),
      ],
    );
  }
}

class CareScreen extends StatelessWidget {
  const CareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimpleScreen(
      title: 'Care',
      subtitle: 'Forms and resources from your clinic',
      children: [
        _ListTileCard(
          icon: Icons.description_outlined,
          title: 'PHQ-9',
          subtitle: 'Due Friday',
        ),
        _ListTileCard(
          icon: Icons.menu_book_outlined,
          title: 'Coping skills worksheet',
          subtitle: 'Shared by your therapist',
        ),
        _ListTileCard(
          icon: Icons.favorite_outline_rounded,
          title: 'Crisis resources',
          subtitle: '24/7 support contacts',
        ),
      ],
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          const Text(
            'Me',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    'MP',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maya Patel',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Divine Counseling  ·  Maryland',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _ListTileCard(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            subtitle: 'Reminders and care-team alerts',
          ),
          const _ListTileCard(
            icon: Icons.lock_outline_rounded,
            title: 'Privacy',
            subtitle: 'HIPAA-ready. Your data stays secure.',
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
                (_) => false,
              );
            },
            child: const Text(
              'Sign out',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleScreen extends StatelessWidget {
  const _SimpleScreen({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _ListTileCard extends StatelessWidget {
  const _ListTileCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primaryWash,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
