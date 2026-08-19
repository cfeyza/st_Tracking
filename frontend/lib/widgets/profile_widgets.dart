import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Gradient header with floating shapes, glass avatar, and role badge
// ─────────────────────────────────────────────────────────────────────────────

class ProfileHeader extends StatelessWidget {
  final String name;
  final String role;

  const ProfileHeader({super.key, required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isMobile = Bp.isMobile(context);
    final avatarR = isMobile ? 40.0 : 52.0;

    return Stack(
      children: [
        // Gradient background
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(gradient: AppColors.drawerGradient),
          padding: EdgeInsets.only(
            top: isMobile ? 36 : 48,
            bottom: isMobile ? 32 : 44,
            left: 24,
            right: 24,
          ),
          child: Column(
            children: [
              // Avatar
              Container(
                width: avatarR * 2,
                height: avatarR * 2,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.50), width: 2.5),
                ),
                child: Icon(Icons.person_rounded, size: avatarR, color: Colors.white),
              ),
              const SizedBox(height: 16),
              // Name
              Text(
                name,
                textAlign: TextAlign.center,
                style: (isMobile ? tt.titleLarge : tt.headlineSmall)?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.40), width: 1),
                ),
                child: Text(
                  role.toUpperCase(),
                  style: tt.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Floating decorative shapes overlay
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: const _HeaderShapesPainter()),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// White card wrapping one or more ProfileInfoTile rows
// ─────────────────────────────────────────────────────────────────────────────

class ProfileInfoCard extends StatelessWidget {
  final List<Widget> children;

  const ProfileInfoCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryCyan.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single info row — drawer-style teal icon box + label/value
// ─────────────────────────────────────────────────────────────────────────────

class ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showDivider;

  const ProfileInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.primaryCyan),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        style: tt.bodyLarge?.copyWith(
                          color: AppColors.deepTeal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, indent: 70, endIndent: 16, color: cs.outlineVariant),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating shapes for the gradient header area
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderShapesPainter extends CustomPainter {
  const _HeaderShapesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final fill = Paint()..style = PaintingStyle.fill;

    // Large hollow circle — top right (partially clipped)
    stroke.color = const Color(0x40FFFFFF);
    canvas.drawCircle(Offset(size.width * 1.05, size.height * 0.08), 80, stroke);

    // Medium filled circle — lower right
    fill.color = const Color(0x26FFFFFF);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.88), 36, fill);

    // Small hollow circle — upper left
    stroke.color = const Color(0x33FFFFFF);
    canvas.drawCircle(Offset(size.width * 0.06, size.height * 0.18), 20, stroke);

    // Tiny filled circle — lower left
    fill.color = const Color(0x22FFFFFF);
    canvas.drawCircle(Offset(size.width * 0.14, size.height * 0.82), 14, fill);

    // Diamond — upper right area
    stroke.color = const Color(0x40FFFFFF);
    _diamond(canvas, stroke, Offset(size.width * 0.78, size.height * 0.14), 11);

    // Triangle — lower left area
    stroke.color = const Color(0x33FFFFFF);
    _triangle(canvas, stroke, Offset(size.width * 0.22, size.height * 0.72), 9);
  }

  void _triangle(Canvas canvas, Paint p, Offset c, double r) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.866, c.dy + r * 0.5)
      ..lineTo(c.dx - r * 0.866, c.dy + r * 0.5)
      ..close();
    canvas.drawPath(path, p);
  }

  void _diamond(Canvas canvas, Paint p, Offset c, double r) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r, c.dy)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
