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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        body: Stack(
          children: [
            const _HomeBackground(),
            SafeArea(
              bottom: false,
              child: ResponsiveCenter(
                child: ListView(
                  padding: responsive.pagePadding.copyWith(
                    top: responsive.rz(12),
                    bottom: responsive.rz(32),
                  ),
                  children: [
                    _Header(
                      greeting: _greeting,
                      userName: userName,
                      initials: _initials(userName),
                    ),
                    SizedBox(height: responsive.rz(22)),
                    _NextSessionCard(
                      onJoin: () => _toast('Opening Zoom…'),
                      onDirections: () => _toast('Opening directions…'),
                    ),
                    SizedBox(height: responsive.rz(26)),
                    _SectionHeader(
                      title: 'Quick actions',
                      subtitle: 'Everything you need, one tap away',
                    ),
                    SizedBox(height: responsive.rz(14)),
                    _QuickActions(
                      onCheckIn: () => _toast('Daily check-in is below'),
                      onMessages: () => widget.onNavigateToTab?.call(2),
                      onForms: () => widget.onNavigateToTab?.call(3),
                      onResources: () => widget.onNavigateToTab?.call(3),
                    ),
                    SizedBox(height: responsive.rz(22)),
                    _CheckInCard(
                      selected: _mood,
                      onSelect: (value) => setState(() => _mood = value),
                      onSave: _mood == null ? null : () => _toast('Check-in saved'),
                    ),
                    SizedBox(height: responsive.rz(16)),
                    const _CareTeamCard(),
                    SizedBox(height: responsive.rz(16)),
                    const _UpcomingCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBackground extends StatelessWidget {
  const _HomeBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 280,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.10),
              AppColors.primaryWash.withValues(alpha: 0.35),
              AppColors.background.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: responsiveTextStyle(
            context,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: responsive.rz(3)),
          Text(
            subtitle!,
            style: responsiveTextStyle(
              context,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _TodayDateChip()),
            SizedBox(width: responsive.rz(10)),
            _NotificationButton(),
          ],
        ),
        SizedBox(height: responsive.rz(18)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greetingText,
                    style: responsiveTextStyle(
                      context,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.7,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: responsive.rz(8)),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: responsive.rz(15),
                        color: AppColors.primarySoft,
                      ),
                      SizedBox(width: responsive.rz(4)),
                      Flexible(
                        child: Text(
                          'Divine Counseling  ·  Maryland',
                          style: responsiveTextStyle(
                            context,
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: responsive.rz(12)),
            _ProfileAvatar(initials: initials),
          ],
        ),
      ],
    );
  }
}

class _TodayDateChip extends StatelessWidget {
  const _TodayDateChip();

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final now = DateTime.now();
    final weekday = _weekdays[now.weekday - 1];
    final month = _months[now.month - 1];
    final day = now.day;
    final year = now.year;
    final isEvening = now.hour >= 17 || now.hour < 6;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.rz(12),
        vertical: responsive.rz(10),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface.withValues(alpha: 0.95),
            AppColors.primaryWash.withValues(alpha: 0.65),
          ],
        ),
        borderRadius: BorderRadius.circular(responsive.rz(18)),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: responsive.rz(46),
            height: responsive.rz(46),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF9B93F8), AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(responsive.rz(14)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: responsive.rz(18),
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                Text(
                  month.substring(0, 3).toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: responsive.rz(9),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: responsive.rz(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekday,
                  style: responsiveTextStyle(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: responsive.rz(2)),
                Text(
                  '$month $day, $year',
                  style: responsiveTextStyle(
                    context,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isEvening ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
            size: responsive.rz(18),
            color: isEvening
                ? const Color(0xFF8B83F6)
                : const Color(0xFFF0A05A),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final size = responsive.rz(52);

    return Container(
      width: size + 6,
      height: size + 6,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9B93F8), AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CircleAvatar(
        backgroundColor: AppColors.primary,
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: responsive.rz(16),
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  static const _unreadCount = 2;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final size = responsive.rz(52);
    final hasUnread = _unreadCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                hasUnread
                    ? '$_unreadCount new notifications'
                    : 'No new notifications',
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(responsive.rz(18)),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface.withValues(alpha: 0.95),
                AppColors.primaryWash.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(responsive.rz(18)),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: responsive.rz(36),
                height: responsive.rz(36),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF9B93F8), AppColors.primary],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  hasUnread
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: responsive.rz(20),
                ),
              ),
              if (hasUnread) ...[
                Positioned(
                  right: responsive.rz(9),
                  top: responsive.rz(8),
                  child: Container(
                    width: responsive.rz(10),
                    height: responsive.rz(10),
                    decoration: BoxDecoration(
                      color: AppColors.badge.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: responsive.rz(10),
                  top: responsive.rz(9),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _unreadCount > 9
                          ? responsive.rz(5)
                          : responsive.rz(0),
                    ),
                    constraints: BoxConstraints(
                      minWidth: responsive.rz(18),
                      minHeight: responsive.rz(18),
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), AppColors.badge],
                      ),
                      shape: _unreadCount > 9
                          ? BoxShape.rectangle
                          : BoxShape.circle,
                      borderRadius: _unreadCount > 9
                          ? BorderRadius.circular(10)
                          : null,
                      border: Border.all(color: AppColors.surface, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.badge.withValues(alpha: 0.45),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _unreadCount > 9 ? '9+' : '$_unreadCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: responsive.rz(9),
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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
    final responsive = context.responsive;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(responsive.rz(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(responsive.rz(28)),
        child: Stack(
          children: [
            const Positioned(
              right: -30,
              top: -30,
              child: _GlowOrb(size: 120, opacity: 0.18),
            ),
            const Positioned(
              left: -20,
              bottom: -40,
              child: _GlowOrb(size: 100, opacity: 0.12),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                responsive.rz(22),
                responsive.rz(20),
                responsive.rz(18),
                responsive.rz(14),
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF12103A),
                    Color(0xFF1C1858),
                    Color(0xFF221A6A),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primarySoft.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF5EC77A),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Next session',
                                    style: responsiveTextStyle(
                                      context,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFD8D6F0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: responsive.rz(14)),
                            Text(
                              'Today, 2:00 PM',
                              style: responsiveTextStyle(
                                context,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                            ),
                            SizedBox(height: responsive.rz(6)),
                            Text(
                              'Maya Patel, LCSW-C',
                              style: responsiveTextStyle(
                                context,
                                fontSize: 15,
                                color: const Color(0xFFD8D6F0),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: responsive.rz(12)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.videocam_rounded,
                                    size: 16,
                                    color: Color(0xFFC4C0EA),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Video visit  ·  50 min',
                                    style: responsiveTextStyle(
                                      context,
                                      fontSize: 13,
                                      color: const Color(0xFFC4C0EA),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const _CalendarGraphic(),
                    ],
                  ),
                  SizedBox(height: responsive.rz(18)),
                  SizedBox(
                    width: double.infinity,
                    height: responsive.rz(50),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B83F6), AppColors.primary],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.45),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: FilledButton.icon(
                        onPressed: onJoin,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          textStyle: TextStyle(
                            fontSize: responsive.rz(16),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        icon: const Icon(Icons.videocam_rounded, size: 21),
                        label: const Text('Join Zoom'),
                      ),
                    ),
                  ),
                  Center(
                    child: TextButton.icon(
                      onPressed: onDirections,
                      icon: const Icon(
                        Icons.near_me_rounded,
                        size: 16,
                        color: Color(0xFFB7B3E8),
                      ),
                      label: const Text(
                        'Get directions',
                        style: TextStyle(
                          color: Color(0xFFB7B3E8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primarySoft.withValues(alpha: opacity),
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
    final actions = [
      (
        Icons.favorite_outline_rounded,
        'Check in',
        const [Color(0xFFFFE8EC), Color(0xFFFFC9D4)],
        AppColors.badge,
        onCheckIn,
      ),
      (
        Icons.chat_bubble_outline_rounded,
        'Messages',
        const [Color(0xFFEDE9FE), Color(0xFFD8D2FF)],
        AppColors.primary,
        onMessages,
      ),
      (
        Icons.description_outlined,
        'Forms',
        const [Color(0xFFE8F4FF), Color(0xFFCCE8FF)],
        const Color(0xFF3B82F6),
        onForms,
      ),
      (
        Icons.menu_book_outlined,
        'Resources',
        const [Color(0xFFE8FBF0), Color(0xFFC9F0D8)],
        AppColors.mood5,
        onResources,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = responsive.rz(10);
        final itemWidth =
            ((constraints.maxWidth - gap * 3) / 4).clamp(68.0, 100.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              _QuickAction(
                width: itemWidth,
                icon: actions[i].$1,
                label: actions[i].$2,
                gradient: actions[i].$3,
                iconColor: actions[i].$4,
                onTap: actions[i].$5,
              ),
            ],
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
    required this.gradient,
    required this.iconColor,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final circleSize = responsive.rz(58).clamp(50.0, 72.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: width,
          child: Column(
            children: [
              Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: responsive.rz(24)),
              ),
              SizedBox(height: responsive.rz(9)),
              Text(
                label,
                textAlign: TextAlign.center,
                style: responsiveTextStyle(
                  context,
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
    final responsive = context.responsive;

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: responsive.rz(40),
                height: responsive.rz(40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryMuted,
                      AppColors.primaryWash,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.self_improvement_rounded,
                  color: AppColors.primary,
                  size: responsive.rz(22),
                ),
              ),
              SizedBox(width: responsive.rz(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How are you today?',
                      style: responsiveTextStyle(
                        context,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Daily wellness check-in',
                      style: responsiveTextStyle(
                        context,
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.rz(18)),
          LayoutBuilder(
            builder: (context, constraints) {
              final moodSize =
                  ((constraints.maxWidth - 24) / 5).clamp(32.0, 50.0);
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
          SizedBox(height: responsive.rz(8)),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Struggling',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
              Text(
                'Great',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ),
          SizedBox(height: responsive.rz(16)),
          SoftButton(
            label: 'Save check-in',
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CustomPaint(painter: _MoodPainter(level: level)),
            ),
            const SizedBox(height: 6),
            Text(
              '$level',
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
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
    final responsive = context.responsive;

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'From your care team',
            subtitle: 'Updates and reminders',
          ),
          SizedBox(height: responsive.rz(14)),
          Material(
            color: AppColors.primaryWash.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening PHQ-9 reminder'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.all(responsive.rz(14)),
                child: Row(
                  children: [
                    Container(
                      width: responsive.rz(44),
                      height: responsive.rz(44),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9B93F8), AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: responsive.rz(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'New reminder',
                                style: responsiveTextStyle(
                                  context,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '1h ago',
                                style: responsiveTextStyle(
                                  context,
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: responsive.rz(4)),
                          Text(
                            'Complete PHQ-9 before Friday',
                            style: responsiveTextStyle(
                              context,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
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
    final responsive = context.responsive;

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Upcoming',
            subtitle: 'Your scheduled visits',
          ),
          SizedBox(height: responsive.rz(16)),
          const _UpcomingRow(
            month: 'MAY',
            day: '15',
            weekday: 'THU',
            title: 'Thu, May 15',
            subtitle: '10:00 AM  ·  In-person',
            trailingIcon: Icons.location_on_rounded,
            accentColor: Color(0xFF3B82F6),
            isLast: false,
          ),
          Padding(
            padding: EdgeInsets.only(left: responsive.rz(21)),
            child: Container(
              width: 2,
              height: responsive.rz(16),
              color: AppColors.border,
            ),
          ),
          const _UpcomingRow(
            month: 'MAY',
            day: '20',
            weekday: 'TUE',
            title: 'Tue, May 20',
            subtitle: '2:00 PM  ·  Telehealth',
            trailingIcon: Icons.videocam_rounded,
            accentColor: AppColors.primary,
            isLast: true,
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
    required this.accentColor,
    required this.isLast,
  });

  final String month;
  final String day;
  final String weekday;
  final String title;
  final String subtitle;
  final IconData trailingIcon;
  final Color accentColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: responsive.rz(6)),
          child: Row(
            children: [
              Container(
                width: responsive.rz(52),
                padding: EdgeInsets.symmetric(vertical: responsive.rz(8)),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      month,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      day,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                    Text(
                      weekday,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: responsive.rz(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: responsiveTextStyle(
                        context,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: responsive.rz(3)),
                    Text(
                      subtitle,
                      style: responsiveTextStyle(
                        context,
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: responsive.rz(38),
                height: responsive.rz(38),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(trailingIcon, size: 18, color: accentColor),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        responsive.rz(18),
        responsive.rz(18),
        responsive.rz(18),
        responsive.rz(18),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(responsive.rz(24)),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
