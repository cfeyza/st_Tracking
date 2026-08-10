import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

class TeacherAddGradeOptionsScreen extends StatelessWidget {
  const TeacherAddGradeOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.addGrades)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OptionTile(
            icon: Icons.edit_note,
            title: l10n.enterManually,
            subtitle: l10n.pickClassroomAndStudentGradeHint,
            onTap: () => Navigator.of(context).pushNamed('/teacher/add-grade'),
          ),
          const SizedBox(height: 12),
          _OptionTile(
            icon: Icons.qr_code_scanner,
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
    final disabledColor = Theme.of(context).disabledColor;
    return Card(
      child: ListTile(
        leading: Icon(icon, color: enabled ? null : disabledColor),
        title: Text(title, style: enabled ? null : TextStyle(color: disabledColor)),
        subtitle: Text(subtitle, style: enabled ? null : TextStyle(color: disabledColor)),
        trailing: enabled ? const Icon(Icons.chevron_right) : null,
        enabled: enabled,
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
