import 'package:flutter/material.dart';

enum MetaBadgeVariant { classroom, teacher, student }

/// Compact inline label used for classrooms, teachers, and students across
/// announcement cards, grade cards, and student lists.
class MetaBadge extends StatelessWidget {
  final String label;
  final MetaBadgeVariant variant;

  const MetaBadge(this.label,
      {super.key, this.variant = MetaBadgeVariant.classroom});

  const MetaBadge.classroom(this.label, {super.key})
      : variant = MetaBadgeVariant.classroom;

  const MetaBadge.teacher(this.label, {super.key})
      : variant = MetaBadgeVariant.teacher;

  const MetaBadge.student(this.label, {super.key})
      : variant = MetaBadgeVariant.student;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = switch (variant) {
      MetaBadgeVariant.classroom => (cs.primaryContainer, cs.onPrimaryContainer),
      MetaBadgeVariant.teacher =>
        (cs.secondaryContainer, cs.onSecondaryContainer),
      MetaBadgeVariant.student =>
        (cs.tertiaryContainer, cs.onTertiaryContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
