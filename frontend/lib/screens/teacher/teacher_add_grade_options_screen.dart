import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../../theme/app_theme.dart';

class TeacherAddGradeOptionsScreen extends StatelessWidget {
  const TeacherAddGradeOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.addGrades)),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: const ContentShapesPainter())),
          ListView(
            padding: AppInsets.page(context),
            children: [
              // Gradient hint card
              GradientCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.grade_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          l10n.addGrades,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _OptionTile(
                icon: Icons.edit_note_rounded,
                title: l10n.enterManually,
                subtitle: l10n.pickClassroomAndStudentGradeHint,
                onTap: () => Navigator.of(context).pushNamed('/teacher/add-grade'),
              ),
              const SizedBox(height: 12),
              _OptionTile(
                icon: Icons.qr_code_scanner_rounded,
                title: l10n.scanOpticForm,
                subtitle: l10n.comingSoon,
                enabled: false,
              ),
              const SizedBox(height: 12),
              _OptionTile(
                icon: Icons.document_scanner_outlined,
                title: l10n.readExamSheet,
                subtitle: l10n.comingSoon,
                enabled: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      shape: AppCard.shape(cs),
      color: cs.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColors.primaryCyan.withOpacity(0.12)
                      : cs.onSurface.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: enabled
                      ? AppColors.primaryCyan
                      : cs.onSurface.withOpacity(0.30),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: enabled ? null : cs.onSurface.withOpacity(0.38),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: tt.bodySmall?.copyWith(
                        color: enabled
                            ? cs.onSurfaceVariant
                            : cs.onSurface.withOpacity(0.28),
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
