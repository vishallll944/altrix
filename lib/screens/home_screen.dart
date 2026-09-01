import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/responsive/responsive.dart';
import '../core/responsive/responsive_widgets.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_buttons.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.onNavigateToTab});

  final ValueChanged<int>? onNavigateToTab;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int? _mood;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final userName = ref.watch(authProvider).user?.name.trim() ?? '';
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: ResponsiveCenter(
            child: ListView(
              padding: responsive.pagePadding.copyWith(
                top: responsive.rz(8),
                bottom: responsive.rz(28),
              ),
              children: [
              _Header(
                greeting: _greeting,
                userName: userName,
                initials: _initials(userName),
              ),
              const SizedBox(height: 18),
              _NextSessionCard(
                onJoin: () => _toast('Opening Zoom…'),
                onDirections: () => _toast('Opening directions…'),
              ),
              const SizedBox(height: 22),
              _QuickActions(
                onCheckIn: () => _toast('Daily check-in is below'),
                onMessages: () => widget.onNavigateToTab?.call(2),
                onForms: () => widget.onNavigateToTab?.call(3),
                onResources: () => widget.onNavigateToTab?.call(3),
              ),
              const SizedBox(height: 18),
              _CheckInCard(
                selected: _mood,
                onSelect: (value) => setState(() => _mood = value),
                onSave: _mood == null
                    ? null
                    : () => _toast('Check-in saved'),
              ),
              const SizedBox(height: 14),
              const _CareTeamCard(),
              const SizedBox(height: 14),
              const _UpcomingCard(),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.userName,
    required this.initials,
  });

  final String greeting;
  final String userName;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final greetingText = userName.isEmpty ? greeting : '$greeting, $userName';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greetingText,
                style: responsiveTextStyle(
                  context,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                  height: 1.15,
                ),
              ),
              SizedBox(height: responsive.rz(4)),
              Text(
                'Divine Counseling  ·  Maryland',
                style: responsiveTextStyle(
                  context,
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: responsive.rz(42),
          height: responsive.rz(42),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            initials,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: responsive.rz(14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('2 new notifications'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primary,
              ),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 16,
                height: 16,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.badge,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '2',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NextSessionCard extends StatelessWidget {
  const _NextSessionCard({
    required this.onJoin,
    required this.onDirections,
  });

  final VoidCallback onJoin;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF14123A), Color(0xFF1A1650)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next session',
                      style: TextStyle(
                        color: Color(0xFFB7B3E8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Today, 2:00 PM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Maya Patel, LCSW-C',
                      style: TextStyle(
                        color: Color(0xFFD8D6F0),
                        fontSize: 14.5,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.videocam_outlined,
                          size: 16,
                          color: Color(0xFFC4C0EA),
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Video visit  ·  50 min',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFFC4C0EA),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const _CalendarGraphic(),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.videocam, size: 20),
              label: const Text('Join Zoom'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: onDirections,
              child: const Text(
                'Get directions',
                style: TextStyle(
                  color: Color(0xFFB7B3E8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarGraphic extends StatelessWidget {
  const _CalendarGraphic();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 80,
      child: CustomPaint(painter: _CalendarClockPainter()),
    );
  }
}

class _CalendarClockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = const Color(0xFF8B83F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cal = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 10, 58, 50),
      const Radius.circular(10),
    );
    canvas.drawRRect(cal, stroke);
    canvas.drawLine(const Offset(8, 26), const Offset(66, 26), stroke);
    canvas.drawLine(const Offset(22, 8), const Offset(22, 16), stroke);
    canvas.drawLine(const Offset(52, 8), const Offset(52, 16), stroke);

    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 3; col++) {
        canvas.drawCircle(
          Offset(20.0 + col * 14, 36.0 + row * 12),
          2.2,
          stroke..style = PaintingStyle.fill,
        );
      }
    }
    stroke.style = PaintingStyle.stroke;

    final clockCenter = Offset(size.width - 18, size.height - 18);
    canvas.drawCircle(clockCenter, 16, Paint()..color = const Color(0xFF161445));
    canvas.drawCircle(clockCenter, 16, stroke);
    canvas.drawLine(clockCenter, clockCenter + const Offset(0, -8), stroke);
    canvas.drawLine(clockCenter, clockCenter + const Offset(8, 4), stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onCheckIn,
    required this.onMessages,
    required this.onForms,
    required this.onResources,
  });

  final VoidCallback onCheckIn;
  final VoidCallback onMessages;
  final VoidCallback onForms;
  final VoidCallback onResources;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = ((constraints.maxWidth - responsive.rz(24)) / 4)
            .clamp(64.0, 96.0);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _QuickAction(
              width: itemWidth,
              icon: Icons.check_circle_outline_rounded,
              label: 'Check in',
              onTap: onCheckIn,
            ),
            _QuickAction(
              width: itemWidth,
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Messages',
              onTap: onMessages,
            ),
            _QuickAction(
              width: itemWidth,
              icon: Icons.description_outlined,
              label: 'Forms',
              onTap: onForms,
            ),
            _QuickAction(
              width: itemWidth,
              icon: Icons.menu_book_outlined,
              label: 'Resources',
              onTap: onResources,
            ),
          ],
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.width,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final circleSize = responsive.rz(56).clamp(48.0, 68.0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: AppColors.primary, size: responsive.rz(24)),
            ),
            SizedBox(height: responsive.rz(8)),
            Text(
              label,
              textAlign: TextAlign.center,
              style: responsiveTextStyle(
                context,
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckInCard extends StatelessWidget {
  const _CheckInCard({
    required this.selected,
    required this.onSelect,
    required this.onSave,
  });

  final int? selected;
  final ValueChanged<int> onSelect;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How are you today?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Daily check-in',
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final moodSize =
                  ((constraints.maxWidth - 20) / 5).clamp(30.0, 48.0);
              return Row(
                children: List.generate(5, (index) {
                  final level = index + 1;
                  return Expanded(
                    child: _MoodButton(
                      level: level,
                      size: moodSize,
                      selected: selected == level,
                      onTap: () => onSelect(level),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 16),
          SoftButton(
            label: 'Save',
            enabled: onSave != null,
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  const _MoodButton({
    required this.level,
    required this.size,
    required this.selected,
    required this.onTap,
  });

  final int level;
  final double size;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: SizedBox(
              width: size,
              height: size,
              child: CustomPaint(painter: _MoodPainter(level: level)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$level',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodPainter extends CustomPainter {
  _MoodPainter({required this.level});

  final int level;

  Color get _color {
    switch (level) {
      case 1:
        return AppColors.mood1;
      case 2:
        return AppColors.mood2;
      case 3:
        return AppColors.mood3;
      case 4:
        return AppColors.mood4;
      default:
        return AppColors.mood5;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawCircle(center, radius, Paint()..color = _color);

    final eye = Paint()..color = const Color(0xFF3D2A1A);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.35, size.height * 0.40),
        width: 4.2,
        height: 5.4,
      ),
      eye,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.65, size.height * 0.40),
        width: 4.2,
        height: 5.4,
      ),
      eye,
    );

    final mouth = Paint()
      ..color = const Color(0xFF3D2A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    switch (level) {
      case 1:
        path.moveTo(size.width * 0.30, size.height * 0.72);
        path.quadraticBezierTo(
          size.width * 0.50,
          size.height * 0.58,
          size.width * 0.70,
          size.height * 0.72,
        );
      case 2:
        path.moveTo(size.width * 0.30, size.height * 0.70);
        path.quadraticBezierTo(
          size.width * 0.50,
          size.height * 0.62,
          size.width * 0.70,
          size.height * 0.70,
        );
      case 3:
        path.moveTo(size.width * 0.32, size.height * 0.68);
        path.lineTo(size.width * 0.68, size.height * 0.68);
      case 4:
        path.moveTo(size.width * 0.30, size.height * 0.64);
        path.quadraticBezierTo(
          size.width * 0.50,
          size.height * 0.78,
          size.width * 0.70,
          size.height * 0.64,
        );
      default:
        path.moveTo(size.width * 0.28, size.height * 0.62);
        path.quadraticBezierTo(
          size.width * 0.50,
          size.height * 0.84,
          size.width * 0.72,
          size.height * 0.62,
        );
    }
    canvas.drawPath(path, mouth);
  }

  @override
  bool shouldRepaint(covariant _MoodPainter oldDelegate) =>
      oldDelegate.level != level;
}

class _CareTeamCard extends StatelessWidget {
  const _CareTeamCard();

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'From your care team',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening PHQ-9 reminder'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  _UnreadDot(),
                  SizedBox(width: 10),
                  _MiniIcon(icon: Icons.chat_bubble_outline_rounded),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Reminder: complete PHQ-9 before Friday',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '1h',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard();

  @override
  Widget build(BuildContext context) {
    return const _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          _UpcomingRow(
            month: 'MAY',
            day: '15',
            weekday: 'THU',
            title: 'Thu, May 15',
            subtitle: '10:00 AM  ·  In-person',
            trailingIcon: Icons.location_on_outlined,
          ),
          SizedBox(height: 8),
          _UpcomingRow(
            month: 'MAY',
            day: '20',
            weekday: 'TUE',
            title: 'Tue, May 20',
            subtitle: '2:00 PM  ·  Telehealth',
            trailingIcon: Icons.videocam_outlined,
          ),
        ],
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({
    required this.month,
    required this.day,
    required this.weekday,
    required this.title,
    required this.subtitle,
    required this.trailingIcon,
  });

  final String month;
  final String day;
  final String weekday;
  final String title;
  final String subtitle;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Text(
                  month,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
                Text(
                  weekday,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
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
                const SizedBox(height: 2),
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
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primaryWash,
              shape: BoxShape.circle,
            ),
            child: Icon(trailingIcon, size: 18, color: AppColors.primary),
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

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        responsive.rz(18),
        responsive.rz(16),
        responsive.rz(18),
        responsive.rz(16),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(responsive.rz(22)),
      ),
      child: child,
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  const _MiniIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: AppColors.primaryWash,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: AppColors.primary),
    );
  }
}
