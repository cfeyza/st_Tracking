import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../../models/grade.dart';
import '../../models/paginated.dart';
import '../../models/student.dart';
import '../../services/api_client.dart';
import '../../services/student_service.dart';
import '../../widgets/pagination_bar.dart';

class StudentGradesScreen extends StatefulWidget {
  const StudentGradesScreen({super.key});

  @override
  State<StudentGradesScreen> createState() => _StudentGradesScreenState();
}

class _StudentGradesScreenState extends State<StudentGradesScreen> {
  int _page = 1;
  int? _selectedTeacherId;
  List<TeacherFilterItem>? _teachers;
  late Future<Paginated<Grade>> _future;

  @override
  void initState() {
    super.initState();
    _future = StudentService.listGrades(page: _page);
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    final teachers = await StudentService.listGradeTeachers();
    if (mounted) setState(() => _teachers = teachers);
  }

  void _goToPage(int page) {
    setState(() {
      _page = page;
      _future = StudentService.listGrades(page: page, teacherId: _selectedTeacherId);
    });
  }

  void _onTeacherChanged(int? teacherId) {
    setState(() {
      _selectedTeacherId = teacherId;
      _page = 1;
      _future = StudentService.listGrades(page: 1, teacherId: teacherId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showFilter = _teachers != null && _teachers!.length > 1;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myGrades)),
      body: Column(
        children: [
          if (showFilter)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: DropdownButtonFormField<int?>(
                value: _selectedTeacherId,
                decoration: InputDecoration(
                  labelText: l10n.filterByTeacher,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.allTeachers)),
                  for (final t in _teachers!)
                    DropdownMenuItem(value: t.id, child: Text(t.name)),
                ],
                onChanged: _onTeacherChanged,
              ),
            ),
          Expanded(
            child: FutureBuilder<Paginated<Grade>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('${(snapshot.error as ApiException?)?.message ?? snapshot.error}'));
                }
                final result = snapshot.data!;
                final grades = result.items;
                if (result.total == 0) {
                  return Center(child: Text(l10n.noGradesYet));
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: grades.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, index) {
                          final g = grades[index];
                          return ListTile(
                            leading: CircleAvatar(child: Text(g.value)),
                            title: Text(g.subject),
                            subtitle: Text(
                              '${g.teacherName}${g.classroomName != null ? " · ${g.classroomName}" : ""}\n'
                              '${g.createdAt.toLocal().toString().split('.').first}',
                            ),
                            isThreeLine: true,
                          );
                        },
                      ),
                    ),
                    PaginationBar(
                      page: result.page,
                      totalPages: result.totalPages,
                      onPageChange: _goToPage,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
