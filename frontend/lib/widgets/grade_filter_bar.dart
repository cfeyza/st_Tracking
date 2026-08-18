import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/student.dart';
import '../theme/app_theme.dart';

/// A pill-shaped container for a single filter control.
/// Pass any [DropdownButton] or similar widget as [child].
class FilterPill extends StatelessWidget {
  final Widget child;
  const FilterPill({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: child,
      ),
    );
  }
}

/// Shared filter + sort toolbar used by all grades screens.
///
/// Pass screen-specific filter dropdowns wrapped in [FilterPill] as [filters].
/// The [teachers]/[selectedTeacherId]/[onTeacherChanged] shortcut handles the
/// student and parent views where only an optional teacher filter is needed.
class GradeFilterBar extends StatelessWidget {
  /// Extra filter pills rendered before the sort group.
  final List<Widget> filters;

  /// Convenience teacher filter (student/parent screens).
  /// Rendered only when [teachers] has more than one entry.
  final List<TeacherFilterItem>? teachers;
  final int? selectedTeacherId;
  final ValueChanged<int?>? onTeacherChanged;

  final Map<String, String> sortOptions;
  final String sortBy;
  final ValueChanged<String> onSortByChanged;
  final String order;
  final VoidCallback onToggleOrder;

  const GradeFilterBar({
    super.key,
    this.filters = const [],
    this.teachers,
    this.selectedTeacherId,
    this.onTeacherChanged,
    required this.sortOptions,
    required this.sortBy,
    required this.onSortByChanged,
    required this.order,
    required this.onToggleOrder,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final showTeacher = teachers != null && teachers!.length > 1;

    return Container(
      color: cs.surface,
      padding: AppInsets.filterBar(context),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (showTeacher)
            FilterPill(
              child: DropdownButton<int?>(
                value: selectedTeacherId,
                hint: Text(l10n.allTeachers),
                isDense: true,
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.allTeachers)),
                  for (final t in teachers!)
                    DropdownMenuItem(value: t.id, child: Text(t.name)),
                ],
                onChanged: onTeacherChanged,
              ),
            ),
          ...filters,
          _SortGroup(
            sortOptions: sortOptions,
            sortBy: sortBy,
            onSortByChanged: onSortByChanged,
            order: order,
            onToggleOrder: onToggleOrder,
          ),
        ],
      ),
    );
  }
}

/// Sort-field dropdown and direction toggle rendered as one visual unit.
class _SortGroup extends StatelessWidget {
  final Map<String, String> sortOptions;
  final String sortBy;
  final ValueChanged<String> onSortByChanged;
  final String order;
  final VoidCallback onToggleOrder;

  const _SortGroup({
    required this.sortOptions,
    required this.sortBy,
    required this.onSortByChanged,
    required this.order,
    required this.onToggleOrder,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: DropdownButton<String>(
              value: sortBy,
              isDense: true,
              underline: const SizedBox.shrink(),
              items: [
                for (final e in sortOptions.entries)
                  DropdownMenuItem(
                    value: e.key,
                    child: Text(l10n.sortBy(e.value)),
                  ),
              ],
              onChanged: (v) => onSortByChanged(v!),
            ),
          ),
          SizedBox(
            width: 1,
            height: 20,
            child: ColoredBox(color: cs.outlineVariant),
          ),
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            constraints: const BoxConstraints(),
            tooltip: order == 'asc' ? l10n.ascending : l10n.descending,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Icon(
                order == 'asc' ? Icons.arrow_upward : Icons.arrow_downward,
                key: ValueKey(order),
                size: 16,
              ),
            ),
            onPressed: onToggleOrder,
          ),
        ],
      ),
    );
  }
}
