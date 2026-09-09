import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/responsive_widgets.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/altrix_logo.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.child,
    this.compactHeader = false,
  });

  final Widget child;
  final bool compactHeader;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: responsive.isPhone ? double.infinity : 560,
            ),
            child: Column(
              children: [
                _AuthHeader(compact: compactHeader),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(responsive.rz(32)),
                      ),
                    ),
                    child: ResponsiveFormContainer(child: child),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return ColoredBox(
      color: AppColors.navy,
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.navy,
                    AppColors.navyMid,
                    Color(0xFF1C1654),
                    Color(0xFF2A1B6A),
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: CustomPaint(painter: _GlowRingsPainter()),
          ),
          SafeArea(
            bottom: false,
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  responsive.rz(24),
                  compact ? responsive.rz(8) : responsive.rz(24),
                  responsive.rz(24),
                  responsive.rz(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AltrixWordmark(compact: compact),
                    SizedBox(
                      height: compact ? responsive.rz(8) : responsive.rz(14),
                    ),
                    Text(
                      'Your care, in one place',
                      style: TextStyle(
                        color: AppColors.textOnDark,
                        fontSize: responsive.rz(compact ? 15 : 17),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(
                      height: compact ? responsive.rz(8) : responsive.rz(14),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: responsive.rz(14),
                          color: AppColors.textOnDarkMuted,
                        ),
                        SizedBox(width: responsive.rz(6)),
                        Flexible(
                          child: Text(
                            'HIPAA-ready  •  Your data is secure',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textOnDarkMuted,
                              fontSize: responsive.rz(12.5),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
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

class ClinicFooter extends StatelessWidget {
  const ClinicFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Need help? Contact your clinic',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 16, color: AppColors.primarySoft),
            SizedBox(width: 6),
            Text(
              'Altrixs',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

class _GlowRingsPainter extends CustomPainter {
  const _GlowRingsPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 1.05);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var i = 1; i <= 5; i++) {
      paint.color = const Color(0xFF6B63F0)
          .withValues(alpha: 0.08 + (i * 0.02));
      canvas.drawCircle(center, 70.0 * i, paint);
    }

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF6B63F0).withValues(alpha: 0.28),
          const Color(0xFF6B63F0).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 220));
    canvas.drawCircle(center, 220, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
