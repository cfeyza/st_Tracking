import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/grade.dart';
import '../theme/app_theme.dart';

/// Compact grade card shared by the student, parent, and teacher grade screens.
///
/// When [grade.studentName] is non-null (teacher view) it is shown instead of
/// [grade.teacherName], because a teacher does not need to see their own name.
class GradeCard extends StatelessWidget {
  final Grade grade;

  const GradeCard({super.key, required this.grade});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final dateStr = DateFormat('d MMM y', locale).format(grade.createdAt.toLocal());

    // Teacher view: show student name. Student/parent view: show teacher name.
    final firstMeta = grade.studentName ?? grade.teacherName;
    final metaParts = [
      firstMeta,
      if (grade.classroomName != null) grade.classroomName!,
    ];

    return Card(
      elevation: 0,
      shape: AppCard.shape(cs),
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Grade value box
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                grade.value,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onPrimaryContainer,
                  fontSize: grade.value.length > 3 ? 12 : null,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grade.subject,
                    style:
                        textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    metaParts.join(' · '),
                    style: textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  Text(
                    dateStr,
                    style: textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
