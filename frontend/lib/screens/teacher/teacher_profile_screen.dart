import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../../models/teacher.dart';
import '../../services/api_client.dart';
import '../../services/teacher_service.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  late Future<TeacherProfile> _future;

  @override
  void initState() {
    super.initState();
    _future = TeacherService.getMe();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: FutureBuilder<TeacherProfile>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${(snapshot.error as ApiException?)?.message ?? snapshot.error}'));
          }
          final teacher = snapshot.data!;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 56,
                      child: Icon(Icons.person, size: 56),
                    ),
                    const SizedBox(height: 24),
                    _ProfileField(label: l10n.teacherCode, value: teacher.teacherCode, copyable: true),
                    _ProfileField(label: l10n.name, value: teacher.name),
                    _ProfileField(label: l10n.surname, value: teacher.surname),
                    _ProfileField(label: l10n.email, value: teacher.email),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;

  const _ProfileField({required this.label, required this.value, this.copyable = false});

  void _copy(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.copiedToClipboard(label))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final valueRow = Row(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        if (copyable) ...[
          const SizedBox(width: 6),
          Icon(Icons.copy, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          if (copyable)
            InkWell(onTap: () => _copy(context), child: valueRow)
          else
            valueRow,
        ],
      ),
    );
  }
}
