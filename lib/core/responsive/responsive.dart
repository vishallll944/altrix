import 'package:flutter/material.dart';

enum ScreenType { phone, tablet, desktop }

/// Responsive helpers based on a 390px-wide design reference.
class Responsive {
  const Responsive(this.context);

  final BuildContext context;

  static const double designWidth = 390;

  Size get size => MediaQuery.sizeOf(context);
  double get width => size.width;
  double get height => size.height;
  Orientation get orientation => MediaQuery.orientationOf(context);
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(context);

  ScreenType get screenType {
    if (width >= 1200) return ScreenType.desktop;
    if (width >= 600) return ScreenType.tablet;
    return ScreenType.phone;
  }

  bool get isPhone => screenType == ScreenType.phone;
  bool get isTablet => screenType == ScreenType.tablet;
  bool get isDesktop => screenType == ScreenType.desktop;
  bool get useNavigationRail => width >= 840;

  double get scale => (width / designWidth).clamp(0.82, 1.35);

  double rz(num value) => (value * scale).toDouble();

  double get maxContentWidth {
    switch (screenType) {
      case ScreenType.phone:
        return width;
      case ScreenType.tablet:
        return 720;
      case ScreenType.desktop:
        return 840;
    }
  }

  double get maxFormWidth => isPhone ? width : 480;

  EdgeInsets get pagePadding {
    final horizontal = switch (screenType) {
      ScreenType.phone => rz(20).clamp(16.0, 24.0),
      ScreenType.tablet => 32.0,
      ScreenType.desktop => 48.0,
    };
    return EdgeInsets.symmetric(horizontal: horizontal);
  }

  EdgeInsets get authFormPadding {
    final horizontal = switch (screenType) {
      ScreenType.phone => rz(24).clamp(20.0, 28.0),
      ScreenType.tablet => 40.0,
      ScreenType.desktop => 48.0,
    };
    return EdgeInsets.fromLTRB(horizontal, rz(28), horizontal, rz(24));
  }

  double get buttonHeight => rz(54).clamp(48.0, 60.0);

  double get bottomNavIconSize => rz(22).clamp(20.0, 26.0);

  double get bottomNavLabelSize => rz(11).clamp(10.0, 13.0);

  double authHeaderFraction({required bool compact}) {
    if (compact) return isPhone ? 0.24 : 0.2;
    return isPhone ? 0.34 : 0.28;
  }
}

extension ResponsiveContext on BuildContext {
  Responsive get responsive => Responsive(this);
}

TextStyle responsiveTextStyle(
  BuildContext context, {
  required double fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  final scale = context.responsive.scale;
  return TextStyle(
    fontSize: fontSize * scale,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}
