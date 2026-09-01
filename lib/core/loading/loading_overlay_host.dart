import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'loading_overlay_provider.dart';
import 'premium_loading_overlay.dart';

class LoadingOverlayHost extends ConsumerStatefulWidget {
  const LoadingOverlayHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LoadingOverlayHost> createState() => _LoadingOverlayHostState();
}

class _LoadingOverlayHostState extends ConsumerState<LoadingOverlayHost>
    with SingleTickerProviderStateMixin {
  static const _fadeDuration = Duration(milliseconds: 280);

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  bool _mountedInTree = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: _fadeDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOutCubic,
    );
    _fadeController.addStatusListener(_onFadeStatus);
  }

  @override
  void dispose() {
    _fadeController
      ..removeStatusListener(_onFadeStatus)
      ..dispose();
    super.dispose();
  }

  void _handleActiveCount(int activeCount) {
    final shouldShow = activeCount > 0;

    if (shouldShow) {
      if (!_mountedInTree) {
        setState(() => _mountedInTree = true);
      }
      _fadeController.forward();
      return;
    }

    if (_mountedInTree) {
      _fadeController.reverse();
    }
  }

  void _onFadeStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed &&
        ref.read(loadingOverlayProvider) == 0 &&
        mounted) {
      setState(() => _mountedInTree = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = ref.watch(loadingOverlayProvider);

    ref.listen<int>(loadingOverlayProvider, (previous, next) {
      _handleActiveCount(next);
    });

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_mountedInTree)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, _) {
                return PremiumLoadingOverlay(
                  opacity: _fadeAnimation.value,
                  isAnimating: activeCount > 0,
                );
              },
            ),
          ),
      ],
    );
  }
}
