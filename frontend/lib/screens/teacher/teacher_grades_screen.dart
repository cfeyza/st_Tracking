import 'package:flutter/material.dart';

import '../../models/classroom.dart';
import '../../models/grade.dart';
import '../../models/paginated.dart';
import '../../models/teacher.dart';
import '../../services/api_client.dart';
import '../../services/teacher_service.dart';

const _sortOptions = {
  'date': 'Date',
  'student': 'Student',
  'subject': 'Subject',
  'value': 'Grade',
  'classroom': 'Classroom',
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
    final studentName = _selectedStudentLabel;
    return Scaffold(
      appBar: AppBar(
        title: Text(studentName == null ? 'Grades' : 'Grades — $studentName'),
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
                  hint: const Text('Filter: all students'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All students')),
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
                  hint: const Text('Filter: all classrooms'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All classrooms')),
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
                    for (final entry in _sortOptions.entries)
                      DropdownMenuItem(value: entry.key, child: Text('Sort: ${entry.value}')),
                  ],
                  onChanged: (value) {
                    sortBy = value!;
                    _reloadFromFilterChange();
                  },
                ),
                IconButton(
                  tooltip: order == 'asc' ? 'Ascending' : 'Descending',
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
                  return const Center(child: Text('No grades found.'));
                }
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Student')),
                              DataColumn(label: Text('Subject')),
                              DataColumn(label: Text('Grade')),
                              DataColumn(label: Text('Classroom')),
                              DataColumn(label: Text('Date')),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: page > 1 ? () => onPageChange(page - 1) : null,
          ),
          Text('Page $page of $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: page < totalPages ? () => onPageChange(page + 1) : null,
          ),
        ],
      ),
    );
  }
}
