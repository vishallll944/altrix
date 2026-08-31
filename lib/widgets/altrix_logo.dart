import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AltrixLogo extends StatelessWidget {
  const AltrixLogo({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9B93F8), AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CustomPaint(painter: _LogoAPainter()),
    );
  }
}

class AltrixWordmark extends StatelessWidget {
  const AltrixWordmark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 40.0 : 52.0;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AltrixLogo(size: logoSize),
        SizedBox(width: compact ? 10 : 12),
        Text(
          'Altrixs',
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 28 : 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            height: 1,
          ),
        ),
      ],
    ),
    );
  }
}

class _LogoAPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.32, size.height * 0.74)
      ..lineTo(size.width * 0.48, size.height * 0.28)
      ..lineTo(size.width * 0.62, size.height * 0.52)
      ..moveTo(size.width * 0.50, size.height * 0.52)
      ..lineTo(size.width * 0.72, size.height * 0.52);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
