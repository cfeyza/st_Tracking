import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../../models/classroom.dart';
import '../../models/grade.dart';
import '../../models/paginated.dart';
import '../../models/teacher.dart';
import '../../services/api_client.dart';
import '../../services/teacher_service.dart';

Map<String, String> _buildSortOptions(AppLocalizations l10n) => {
  'date': l10n.date,
  'student': l10n.student,
  'subject': l10n.subject,
  'value': l10n.grade,
  'classroom': l10n.classroom,
};

class TeacherGradesScreen extends StatefulWidget {
  const TeacherGradesScreen({super.key, this.initialStudentId, this.initialStudentName});

  final int? initialStudentId;
  final String? initialStudentName;

  @override
  State<TeacherGradesScreen> createState() => _TeacherGradesScreenState();
}

class _TeacherGradesScreenState extends State<TeacherGradesScreen> {
  int? _studentId;
  int? _classroomId;
  String sortBy = 'date';
  String order = 'desc';
  int _page = 1;
  List<StudentListItem> _students = [];
  List<ClassroomOut> _classrooms = [];
  late Future<Paginated<Grade>> _future;

  @override
  void initState() {
    super.initState();
    _studentId = widget.initialStudentId;
    _loadFilterOptions();
    _load();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final results = await Future.wait([
        TeacherService.listAllStudents(),
        TeacherService.listAllClassrooms(),
      ]);
      if (!mounted) return;
      setState(() {
        _students = results[0] as List<StudentListItem>;
        _classrooms = results[1] as List<ClassroomOut>;
        if (_studentId != null && !_students.any((s) => s.id == _studentId)) {
          _studentId = null;
        }
      });
    } on ApiException {
      // Filter dropdowns just stay empty; the list itself still loads.
    }
  }

  void _load() {
    _future = TeacherService.listGrades(
      studentId: _studentId,
      classroomId: _classroomId,
      sortBy: sortBy,
      order: order,
      page: _page,
    );
  }

  void _reloadFromFilterChange() {
    _page = 1;
    setState(_load);
  }

  void _goToPage(int page) {
    setState(() {
      _page = page;
      _load();
    });
  }

  String? get _selectedStudentLabel {
    if (_studentId == null) return null;
    for (final s in _students) {
      if (s.id == _studentId) return '${s.name} ${s.surname}';
    }
    if (_studentId == widget.initialStudentId) return widget.initialStudentName;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sortOptions = _buildSortOptions(l10n);
    final studentName = _selectedStudentLabel;
    return Scaffold(
      appBar: AppBar(
        title: Text(studentName == null ? l10n.grades : l10n.gradesWithStudent(studentName)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<int?>(
                  value: _students.any((s) => s.id == _studentId) ? _studentId : null,
                  hint: Text(l10n.filterAllStudents),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.allStudents)),
                    for (final s in _students)
                      DropdownMenuItem(value: s.id, child: Text('${s.name} ${s.surname}')),
                  ],
                  onChanged: (value) {
                    _studentId = value;
                    _reloadFromFilterChange();
                  },
                ),
                DropdownButton<int?>(
                  value: _classrooms.any((c) => c.id == _classroomId) ? _classroomId : null,
                  hint: Text(l10n.filterAllClassrooms),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.allClassrooms)),
                    for (final c in _classrooms) DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (value) {
                    _classroomId = value;
                    _reloadFromFilterChange();
                  },
                ),
                DropdownButton<String>(
                  value: sortBy,
                  items: [
                    for (final entry in sortOptions.entries)
                      DropdownMenuItem(value: entry.key, child: Text(l10n.sortBy(entry.value))),
                  ],
                  onChanged: (value) {
                    sortBy = value!;
                    _reloadFromFilterChange();
                  },
                ),
                IconButton(
                  tooltip: order == 'asc' ? l10n.ascending : l10n.descending,
                  icon: Icon(order == 'asc' ? Icons.arrow_upward : Icons.arrow_downward),
                  onPressed: () {
                    order = order == 'asc' ? 'desc' : 'asc';
                    _reloadFromFilterChange();
                  },
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
                  return Center(child: Text('${(snapshot.error as ApiException?)?.message ?? snapshot.error}'));
                }
                final result = snapshot.data!;
                final grades = result.items;
                if (grades.isEmpty) {
                  return Center(child: Text(l10n.noGradesFound));
                }
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              DataColumn(label: Text(l10n.student)),
                              DataColumn(label: Text(l10n.subject)),
                              DataColumn(label: Text(l10n.grade)),
                              DataColumn(label: Text(l10n.classroom)),
                              DataColumn(label: Text(l10n.date)),
                            ],
                            rows: [
                              for (final g in grades)
                                DataRow(cells: [
                                  DataCell(Text(g.studentName ?? '-')),
                                  DataCell(Text(g.subject)),
                                  DataCell(Text(g.value)),
                                  DataCell(Text(g.classroomName ?? '-')),
                                  DataCell(Text(g.createdAt.toLocal().toString().split(' ').first)),
                                ]),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _PaginationBar(page: result.page, totalPages: result.totalPages, onPageChange: _goToPage),
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

class _PaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChange;

  const _PaginationBar({required this.page, required this.totalPages, required this.onPageChange});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: page > 1 ? () => onPageChange(page - 1) : null,
          ),
          Text(l10n.pageXofY(page, totalPages)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: page < totalPages ? () => onPageChange(page + 1) : null,
          ),
        ],
      ),
    );
  }
}
