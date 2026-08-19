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

// ─────────────────────────────────────────────────────────────────────────────
// App colour tokens
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppColors {
  static const Color deepTeal = Color(0xFF006064);
  static const Color primaryCyan = Color(0xFF00BCD4);
  static const Color lightCyan = Color(0xFF4DD0E1);
  static const Color mintSurface = Color(0xFFF0FDFE);
  static const Color violet = Color(0xFF7C4DFF); // kept for reference
  static const Color ctaCyan = Color(0xFF00BCD4);

  static const LinearGradient authGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF00838F), Color(0xFF4DD0E1)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00ACC1), Color(0xFF4DD0E1)],
  );

  static const LinearGradient drawerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF006064), Color(0xFF00ACC1)],
  );

  static ButtonStyle get filledButtonStyle => FilledButton.styleFrom(
        backgroundColor: ctaCyan,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth gradient background with floating geometric shapes
// ─────────────────────────────────────────────────────────────────────────────

class AuthBackground extends StatelessWidget {
  final Widget child;
  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(gradient: AppColors.authGradient),
        ),
        CustomPaint(
          painter: _FloatingShapesPainter(),
          child: const SizedBox.expand(),
        ),
        child,
      ],
    );
  }
}

class _FloatingShapesPainter extends CustomPainter {
  const _FloatingShapesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final fill = Paint()..style = PaintingStyle.fill;

    // Large hollow circle — top right
    stroke.color = const Color(0x73FFFFFF);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.09), 52, stroke);

    // Medium hollow circle — far left, mid
    stroke.color = const Color(0x40FFFFFF);
    canvas.drawCircle(Offset(size.width * 0.03, size.height * 0.37), 34, stroke);

    // Small filled circle — upper left
    fill.color = const Color(0x40FFFFFF);
    canvas.drawCircle(Offset(size.width * 0.13, size.height * 0.21), 22, fill);

    // Tiny filled circle — upper centre-right
    fill.color = const Color(0x33FFFFFF);
    canvas.drawCircle(Offset(size.width * 0.63, size.height * 0.05), 10, fill);

    // Small hollow circle — right, below first
    stroke.color = const Color(0x33FFFFFF);
    canvas.drawCircle(Offset(size.width * 0.94, size.height * 0.28), 16, stroke);

    // Outline triangle — upper right area
    stroke.color = const Color(0x59FFFFFF);
    _triangle(canvas, stroke, Offset(size.width * 0.73, size.height * 0.14), 14);

    // Outline triangle — left
    stroke.color = const Color(0x40FFFFFF);
    _triangle(canvas, stroke, Offset(size.width * 0.17, size.height * 0.36), 11);

    // Diamond — upper left area
    stroke.color = const Color(0x59FFFFFF);
    _diamond(canvas, stroke, Offset(size.width * 0.29, size.height * 0.06), 9);

    // Large hollow circle — bottom-left (partial)
    stroke.color = const Color(0x26FFFFFF);
    canvas.drawCircle(Offset(-12, size.height * 0.54), 48, stroke);
  }

  void _triangle(Canvas canvas, Paint paint, Offset c, double r) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.866, c.dy + r * 0.5)
      ..lineTo(c.dx - r * 0.866, c.dy + r * 0.5)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _diamond(Canvas canvas, Paint paint, Offset c, double r) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r, c.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Gradient tappable card (replaces plain Card for stat-style cards)
// ─────────────────────────────────────────────────────────────────────────────

class GradientCard extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final Gradient gradient;
  final double borderRadius;

  const GradientCard({
    super.key,
    this.onTap,
    required this.child,
    this.gradient = AppColors.cardGradient,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2600ACC1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: child,
        ),
      ),
    );
  }
}
