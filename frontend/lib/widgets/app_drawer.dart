import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../locale_notifier.dart';
import '../services/auth_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';

class DrawerAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  DrawerAction({required this.icon, required this.label, required this.onTap});
}

// Styled nav item with teal icon box
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDestructive = labelColor != null;
    final boxColor = isDestructive
        ? cs.errorContainer
        : AppColors.primaryCyan.withOpacity(0.12);
    final resolvedIcon = iconColor ?? AppColors.primaryCyan;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: boxColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: resolvedIcon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: labelColor ?? cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (!isDestructive)
              Icon(Icons.chevron_right_rounded, size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// Subtle floating shapes in the drawer header
class _DrawerShapesPainter extends CustomPainter {
  const _DrawerShapesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final fill = Paint()..style = PaintingStyle.fill;

    // Large hollow circle — top right (partially clipped)
    stroke.color = const Color(0x40FFFFFF);
    canvas.drawCircle(Offset(size.width * 1.1, size.height * 0.1), 60, stroke);

    // Small filled circle — lower right
    fill.color = const Color(0x26FFFFFF);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.82), 22, fill);

    // Tiny hollow circle — upper left
    stroke.color = const Color(0x33FFFFFF);
    canvas.drawCircle(Offset(size.width * 0.08, size.height * 0.14), 14, stroke);

    // Diamond — lower left area
    stroke.color = const Color(0x40FFFFFF);
    _diamond(canvas, stroke, Offset(size.width * 0.14, size.height * 0.75), 10);

    // Triangle — upper right area
    stroke.color = const Color(0x33FFFFFF);
    _triangle(canvas, stroke, Offset(size.width * 0.78, size.height * 0.18), 9);
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

/// Shared left drawer: a tappable profile header up top, a caller-supplied
/// list of action buttons, and a logout item that always sits at the bottom.
class AppDrawer extends StatelessWidget {
  final VoidCallback onProfileTap;
  final List<DrawerAction> actions;

  const AppDrawer({super.key, required this.onProfileTap, required this.actions});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final role = Session.role;
    final roleBadgeLabel = switch (role) {
      'teacher' => l10n.teacher.toUpperCase(),
      'student' => l10n.student.toUpperCase(),
      'parent' => l10n.parent.toUpperCase(),
      _ => null,
    };

    return Drawer(
      width: 252,
      child: Column(
        children: [
          // ── Gradient header with floating shapes ──────────────────────────
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              onProfileTap();
            },
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(gradient: AppColors.drawerGradient),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.of(context).padding.top + 24,
                    20,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar + chevron row
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.22),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.50),
                                width: 2,
                              ),
                            ),
                            child: const Icon(Icons.person_rounded, size: 30, color: Colors.white),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Colors.white.withOpacity(0.65),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Role badge
                      if (roleBadgeLabel != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.40),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            roleBadgeLabel,
                            style: textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        l10n.profile,
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.viewProfile,
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white.withOpacity(0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                // Floating decorative shapes over the header
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: const _DrawerShapesPainter()),
                  ),
                ),
              ],
            ),
          ),

          // ── Nav items ─────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final action in actions)
                  _DrawerItem(
                    icon: action.icon,
                    label: action.label,
                    onTap: () {
                      Navigator.of(context).pop();
                      action.onTap();
                    },
                  ),
                const SizedBox(height: 8),
                Divider(height: 1, indent: 16, endIndent: 16, color: colorScheme.outlineVariant),
                const SizedBox(height: 8),
                ValueListenableBuilder<Locale>(
                  valueListenable: localeNotifier,
                  builder: (context, locale, _) => _DrawerItem(
                    icon: Icons.language_rounded,
                    label: locale.languageCode == 'tr' ? 'Türkçe' : 'English',
                    onTap: toggleLocale,
                  ),
                ),
                _DrawerItem(
                  icon: Icons.logout_rounded,
                  label: l10n.logOut,
                  iconColor: colorScheme.error,
                  labelColor: colorScheme.error,
                  onTap: () async {
                    await AuthService.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
