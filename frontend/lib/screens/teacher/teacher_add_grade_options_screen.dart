import 'package:flutter/material.dart';

class TeacherAddGradeOptionsScreen extends StatelessWidget {
  const TeacherAddGradeOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add grades')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OptionTile(
            icon: Icons.edit_note,
            title: 'Enter manually',
            subtitle: 'Pick a classroom and student, then type in the grade.',
            onTap: () => Navigator.of(context).pushNamed('/teacher/add-grade'),
          ),
          const SizedBox(height: 12),
          const _OptionTile(
            icon: Icons.qr_code_scanner,
            title: 'Scan optic form',
            subtitle: 'Coming soon',
            enabled: false,
          ),
          const SizedBox(height: 12),
          const _OptionTile(
            icon: Icons.document_scanner_outlined,
            title: 'Read exam sheet',
            subtitle: 'Coming soon',
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
