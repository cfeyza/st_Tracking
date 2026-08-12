import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../../models/grade.dart';
import '../../models/paginated.dart';
import '../../models/student.dart';
import '../../services/api_client.dart';
import '../../services/parent_service.dart';
import '../../widgets/pagination_bar.dart';

class ParentStudentGradesScreen extends StatefulWidget {
  final int studentId;
  final String studentName;

  const ParentStudentGradesScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<ParentStudentGradesScreen> createState() => _ParentStudentGradesScreenState();
}

Map<String, String> _buildSortOptions(AppLocalizations l10n) => {
  'date': l10n.date,
  'subject': l10n.subject,
  'value': l10n.grade,
  'teacher': l10n.teacher,
};

class _ParentStudentGradesScreenState extends State<ParentStudentGradesScreen> {
  int _page = 1;
  int? _selectedTeacherId;
  List<TeacherFilterItem>? _teachers;
  String _sortBy = 'date';
  String _order = 'desc';
  late Future<Paginated<Grade>> _future;

  @override
  void initState() {
    super.initState();
    _load();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    final teachers = await ParentService.listStudentGradeTeachers(widget.studentId);
    if (mounted) setState(() => _teachers = teachers);
  }

  void _load() {
    _future = ParentService.listStudentGrades(
      widget.studentId,
      page: _page,
      teacherId: _selectedTeacherId,
      sortBy: _sortBy,
      order: _order,
    );
  }

  void _goToPage(int page) {
    setState(() {
      _page = page;
      _load();
    });
  }

  void _onTeacherChanged(int? teacherId) {
    setState(() {
      _selectedTeacherId = teacherId;
      _page = 1;
      _load();
    });
  }

  void _onSortByChanged(String value) {
    setState(() {
      _sortBy = value;
      _page = 1;
      _load();
    });
  }

  void _toggleOrder() {
    setState(() {
      _order = _order == 'asc' ? 'desc' : 'asc';
      _page = 1;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sortOptions = _buildSortOptions(l10n);
    final showTeacherFilter = _teachers != null && _teachers!.length > 1;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.gradesWithStudent(widget.studentName))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (showTeacherFilter)
                  DropdownButton<int?>(
                    value: _selectedTeacherId,
                    hint: Text(l10n.allTeachers),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l10n.allTeachers)),
                      for (final t in _teachers!)
                        DropdownMenuItem(value: t.id, child: Text(t.name)),
                    ],
                    onChanged: _onTeacherChanged,
                  ),
                DropdownButton<String>(
                  value: _sortBy,
                  items: [
                    for (final entry in sortOptions.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(l10n.sortBy(entry.value)),
                      ),
                  ],
                  onChanged: (value) => _onSortByChanged(value!),
                ),
                IconButton(
                  tooltip: _order == 'asc' ? l10n.ascending : l10n.descending,
                  icon: Icon(_order == 'asc' ? Icons.arrow_upward : Icons.arrow_downward),
                  onPressed: _toggleOrder,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<Paginated<Grade>>(
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
