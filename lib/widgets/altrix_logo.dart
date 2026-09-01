import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AltrixLogo extends StatelessWidget {
  const AltrixLogo({
    super.key,
    this.size = 52,
    this.showShadow = true,
  });

  static const assetPath = 'assets/icon/altrixs_app_icon.jpeg';

  final double size;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
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
