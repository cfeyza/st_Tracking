import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../../models/parent.dart';
import '../../services/api_client.dart';
import '../../services/parent_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';

class ParentStudentsScreen extends StatefulWidget {
  const ParentStudentsScreen({super.key});

  @override
  State<ParentStudentsScreen> createState() => _ParentStudentsScreenState();
}

class _ParentStudentsScreenState extends State<ParentStudentsScreen> {
  late Future<List<ParentStudentListItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = ParentService.listStudents();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(l10n.myStudents),
        backgroundColor: cs.surface,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/parent/add-student-code'),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<ParentStudentListItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                  '${(snapshot.error as ApiException?)?.message ?? snapshot.error}'),
            );
          }
          final students = snapshot.data!;
          if (students.isEmpty) {
            return EmptyState(icon: Icons.people_outline, message: l10n.noStudentsLinked);
          }
          return ListView.builder(
            padding: AppInsets.listWithFab(context),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final s = students[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _StudentCard(
                  student: s,
                  onTap: () => Navigator.of(context).pushNamed(
                    '/parent/student-grades',
                    arguments: {
                      'studentId': s.id,
                      'studentName': '${s.name} ${s.surname}',
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final ParentStudentListItem student;
  final VoidCallback onTap;

  const _StudentCard({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      shape: AppCard.shape(cs),
      color: cs.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person_outline, color: cs.onTertiaryContainer, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${student.name} ${student.surname}',
                      style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.schoolIdValue(student.schoolId.toString()),
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
