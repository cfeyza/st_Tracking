import 'package:flutter/material.dart';

import '../../models/classroom.dart';
import '../../models/paginated.dart';
import '../../models/teacher.dart';
import '../../services/api_client.dart';
import '../../services/teacher_service.dart';

const _sortOptions = {
  'classroom': 'Classroom',
  'name': 'Name',
  'surname': 'Surname',
  'school_id': 'School ID',
};


class TeacherStudentsScreen extends StatefulWidget {
  const TeacherStudentsScreen({super.key, this.initialClassroomId, this.initialClassroomName});

  final int? initialClassroomId;
  final String? initialClassroomName;

  @override
  State<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends State<TeacherStudentsScreen> {
  int? _classroomId;
  String sortBy = 'classroom';
  String order = 'asc';
  int _page = 1;
  List<ClassroomOut> _classrooms = [];
  late Future<Paginated<StudentListItem>> _future;

  @override
  void initState() {
    super.initState();
    _classroomId = widget.initialClassroomId;
    _loadClassrooms();
    _load();
  }

  Future<void> _loadClassrooms() async {
    try {
      final classrooms = await TeacherService.listAllClassrooms();
      if (!mounted) return;
      setState(() {
        _classrooms = classrooms;
        if (_classroomId != null && !_classrooms.any((c) => c.id == _classroomId)) {
          _classroomId = null;
        }
      });
    } on ApiException {
      // Filter dropdown just stays empty; the list itself still loads.
    }
  }

  void _load() {
    _future = TeacherService.listStudents(
      classroomId: _classroomId,
      sortBy: sortBy,
      order: order,
      page: _page,
    );
  }

  void _reload() => setState(_load);

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

  Future<void> _confirmDelete(StudentListItem student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove student?'),
        content: Text(
          '${student.name} ${student.surname} will be removed from all of your classrooms and your roster. '
          'Their record and grade history are kept, and other teachers or parents linked to them are unaffected.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await TeacherService.deleteStudent(student.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed ${student.name} ${student.surname}.')),
      );
      if (_page > 1) _page = 1;
      _reload();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialClassroomName == null ? 'My students' : 'My students — ${widget.initialClassroomName}'),
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
                  value: _classrooms.any((c) => c.id == _classroomId)
                      ? _classroomId
                      : null,
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
            child: FutureBuilder<Paginated<StudentListItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('${(snapshot.error as ApiException?)?.message ?? snapshot.error}'));
                }
                final result = snapshot.data!;
                final students = result.items;
                if (students.isEmpty) {
                  return const Center(child: Text('No students found.'));
                }
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            showCheckboxColumn: false,
                            columns: const [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Surname')),
                              DataColumn(label: Text('School ID')),
                              DataColumn(label: Text('Classroom(s)')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('')),
                            ],
                            rows: [
                              for (final s in students)
                                DataRow(
                                  onSelectChanged: (_) => Navigator.of(context).pushNamed(
                                    '/teacher/grades',
                                    arguments: {'studentId': s.id, 'studentName': '${s.name} ${s.surname}'},
                                  ),
                                  cells: [
                                    DataCell(Text(s.name)),
                                    DataCell(Text(s.surname)),
                                    DataCell(Text(s.schoolId.toString())),
                                    DataCell(Text(s.classrooms.join(', '))),
                                    DataCell(
                                      Chip(
                                        label: Text(s.isRegistered ? 'Registered' : 'Pending'),
                                        backgroundColor:
                                            s.isRegistered ? Colors.green.shade100 : Colors.orange.shade100,
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        tooltip: 'Remove student',
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () => _confirmDelete(s),
                                      ),
                                    ),
                                  ],
                                ),
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
