import 'package:flutter/material.dart';

class AppSmoothScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    // Always show a smooth scrollbar for all platforms
    return Scrollbar(
      controller: details.controller,
      thumbVisibility: true,
      child: child,
    );
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // Use BouncingScrollPhysics for iOS/macOS, Clamping for others
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return const BouncingScrollPhysics();
      default:
        return const ClampingScrollPhysics();
    }
  }
}
