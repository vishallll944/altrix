import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class PremiumHealthcareLoader extends StatelessWidget {
  const PremiumHealthcareLoader({
    super.key,
    this.size = 28,
    this.isAnimating = true,
  });

  final double size;
  final bool isAnimating;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.clamp(20.0, 36.0),
      height: size.clamp(20.0, 36.0),
      child: const CircularProgressIndicator(
        strokeWidth: 2.5,
        color: AppColors.primary,
      ),
    );
  }
}

class PremiumLoadingOverlay extends StatelessWidget {
  const PremiumLoadingOverlay({
    super.key,
    required this.opacity,
    required this.isAnimating,
  });

  final double opacity;
  final bool isAnimating;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0.01) return const SizedBox.shrink();
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
