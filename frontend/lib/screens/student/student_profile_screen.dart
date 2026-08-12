import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../../models/student.dart';
import '../../services/api_client.dart';
import '../../services/student_service.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  late Future<StudentProfile> _future;

  @override
  void initState() {
    super.initState();
    _future = StudentService.getMe();
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
      body: FutureBuilder<StudentProfile>(
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
          final student = snapshot.data!;
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
                        '${student.name} ${student.surname}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.student,
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
                          title: Text(l10n.studentCode),
                          subtitle: Text(
                            student.studentCode,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          trailing: const Icon(Icons.copy, size: 18),
                          onTap: () => _copy(context, l10n.studentCode, student.studentCode),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(l10n.name),
                          subtitle: Text(
                            student.name,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          leading: const Icon(Icons.badge_outlined),
                          title: Text(l10n.surname),
                          subtitle: Text(
                            student.surname,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          leading: const Icon(Icons.tag),
                          title: Text(l10n.schoolId),
                          subtitle: Text(
                            student.schoolId.toString(),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          leading: const Icon(Icons.email_outlined),
                          title: Text(l10n.email),
                          subtitle: Text(
                            student.email,
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
