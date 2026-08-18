import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

/// Compact pagination strip shown below paginated lists.
class PaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChange;

  const PaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPageChange,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NavBtn(
            icon: Icons.first_page,
            enabled: page > 1,
            onPressed: () => onPageChange(1),
          ),
          _NavBtn(
            icon: Icons.chevron_left,
            enabled: page > 1,
            onPressed: () => onPageChange(page - 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              l10n.pageXofY(page, totalPages),
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _NavBtn(
            icon: Icons.chevron_right,
            enabled: page < totalPages,
            onPressed: () => onPageChange(page + 1),
          ),
          _NavBtn(
            icon: Icons.last_page,
            enabled: page < totalPages,
            onPressed: () => onPageChange(totalPages),
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _NavBtn({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      onPressed: enabled ? onPressed : null,
    );
  }
}
