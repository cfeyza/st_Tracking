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

  void _copy(BuildContext context, String label, String value) {
    final l10n = AppLocalizations.of(context);
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.copiedToClipboard(label))),
    );
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
            return Center(
              child: Text(
                '${(snapshot.error as ApiException?)?.message ?? snapshot.error}',
              ),
            );
          }
          final teacher = snapshot.data!;
          final colorScheme = Theme.of(context).colorScheme;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: colorScheme.primaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: colorScheme.onPrimaryContainer.withAlpha(26),
                        child: Icon(
                          Icons.person,
                          size: 44,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${teacher.name} ${teacher.surname}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.teacher,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer.withAlpha(178),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.qr_code),
                          title: Text(l10n.teacherCode),
                          subtitle: Text(
                            teacher.teacherCode,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          trailing: const Icon(Icons.copy, size: 18),
                          onTap: () => _copy(context, l10n.teacherCode, teacher.teacherCode),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(l10n.name),
                          subtitle: Text(
                            teacher.name,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          leading: const Icon(Icons.badge_outlined),
                          title: Text(l10n.surname),
                          subtitle: Text(
                            teacher.surname,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          leading: const Icon(Icons.email_outlined),
                          title: Text(l10n.email),
                          subtitle: Text(
                            teacher.email,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
