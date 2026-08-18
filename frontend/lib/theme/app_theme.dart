import 'package:flutter/material.dart';

/// Screen-width breakpoints.
abstract final class Bp {
  /// Below this width: phone layout.
  static const double sm = 600;

  /// Below this width: tablet layout.
  static const double md = 1024;

  /// Maximum content width on wide desktop screens.
  static const double maxW = 1200.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < sm;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= md;
}

/// Adaptive horizontal padding that:
/// - is 14 px on phones (< 600 px)
/// - is 24 px on tablet / desktop (600–1200 px)
/// - auto-centres content when the screen is wider than [Bp.maxW]
abstract final class AppInsets {
  static double _h(double screenWidth) {
    if (screenWidth < Bp.sm) return 14.0;
    if (screenWidth > Bp.maxW) return (screenWidth - Bp.maxW) / 2 + 24.0;
    return 24.0;
  }

  /// Full page padding used for list/card content.
  static EdgeInsets page(BuildContext context,
      {double top = 16, double bottom = 24}) {
    final h = _h(MediaQuery.sizeOf(context).width);
    return EdgeInsets.fromLTRB(h, top, h, bottom);
  }

  /// Page padding with extra bottom clearance for a floating action button.
  static EdgeInsets listWithFab(BuildContext context) =>
      page(context, top: 16, bottom: 80);

  /// Compact padding for filter / toolbar strips.
  static EdgeInsets filterBar(BuildContext context) {
    final h = _h(MediaQuery.sizeOf(context).width);
    return EdgeInsets.fromLTRB(h, 8, h, 8);
  }
}

/// Shared card decoration used by all list-card screens.
abstract final class AppCard {
  static const double radius = 12;
  static const double borderWidth = 0.5;

  static ShapeBorder shape(ColorScheme cs) => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: cs.outlineVariant, width: borderWidth),
      );
}
