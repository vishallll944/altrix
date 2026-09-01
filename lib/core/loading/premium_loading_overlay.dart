import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/altrix_logo.dart';

class PremiumHealthcareLoader extends StatefulWidget {
  const PremiumHealthcareLoader({
    super.key,
    this.size = 128,
    this.isAnimating = true,
  });

  final double size;
  final bool isAnimating;

  @override
  State<PremiumHealthcareLoader> createState() =>
      _PremiumHealthcareLoaderState();
}

class _PremiumHealthcareLoaderState extends State<PremiumHealthcareLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant PremiumHealthcareLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAnimating != widget.isAnimating) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.isAnimating) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value * math.pi * 2;
          final floatY = math.sin(t) * 12;
          final rotation = math.sin(t) * 0.035;
          final scale = 1 + (math.sin(t) * 0.045);
          final glowScale = 1 + (math.sin(t) * 0.12);
          final glowOpacity = 0.35 + ((math.sin(t) + 1) * 0.175);

          return Transform.translate(
            offset: Offset(0, floatY),
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(
                scale: scale,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: widget.size * 1.55 * glowScale,
                      height: widget.size * 1.55 * glowScale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF9B93F8)
                                .withValues(alpha: glowOpacity * 0.55),
                            blurRadius: widget.size * 0.55,
                            spreadRadius: widget.size * 0.08,
                          ),
                          BoxShadow(
                            color: AppColors.primary
                                .withValues(alpha: glowOpacity * 0.75),
                            blurRadius: widget.size * 0.35,
                            spreadRadius: widget.size * 0.02,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: widget.size * 1.18,
                      height: widget.size * 1.18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF9B93F8)
                                .withValues(alpha: glowOpacity * 0.35),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    child!,
                  ],
                ),
              ),
            ),
          );
        },
        child: AltrixLogo(
          size: widget.size,
          showShadow: true,
        ),
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
    final loaderSize = MediaQuery.sizeOf(context).shortestSide * 0.28;

    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: ColoredBox(
          color: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.navy.withValues(alpha: 0.94),
                      const Color(0xE60A0820),
                      AppColors.navyMid.withValues(alpha: 0.96),
                    ],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.85,
                    colors: [
                      AppColors.glow.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Center(
                child: Semantics(
                  label: 'Loading',
                  child: PremiumHealthcareLoader(
                    size: loaderSize.clamp(104.0, 148.0),
                    isAnimating: isAnimating && opacity > 0.01,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
