import 'package:flutter/widgets.dart';

class AppResponsive {
  const AppResponsive._();

  static const double tabletBreakpoint = 700;
  static const double desktopBreakpoint = 1100;

  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= desktopBreakpoint;
  }

  static double horizontalPadding(
    BuildContext context, {
    double mobile = 16,
    double tablet = 24,
    double desktop = 32,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktopBreakpoint) {
      return desktop;
    }
    if (width >= tabletBreakpoint) {
      return tablet;
    }
    return mobile;
  }

  static double formMaxWidth(
    BuildContext context, {
    double tablet = 500,
    double desktop = 560,
  }) {
    if (isDesktop(context)) {
      return desktop;
    }
    if (isTablet(context)) {
      return tablet;
    }
    return double.infinity;
  }

  static double contentMaxWidth(
    BuildContext context, {
    double tablet = 920,
    double desktop = 1200,
  }) {
    if (isDesktop(context)) {
      return desktop;
    }
    if (isTablet(context)) {
      return tablet;
    }
    return double.infinity;
  }

  static double adaptiveSize(
    BuildContext context, {
    required double mobile,
    required double tablet,
    double? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet;
    }
    if (isTablet(context)) {
      return tablet;
    }
    return mobile;
  }
}
