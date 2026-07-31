import 'package:flutter/material.dart';

import '../../models/classroom.dart';
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
  String sortBy = 'surname';
  String order = 'asc';
  List<ClassroomOut> _classrooms = [];
  late Future<List<StudentListItem>> _future;

  @override
  void initState() {
    super.initState();

    print(widget.initialClassroomId);
    print(widget.initialClassroomName);
    _classroomId = widget.initialClassroomId;
    _loadClassrooms();
    _load();
  }

  Future<void> _loadClassrooms() async {
    try {
      final classrooms = await TeacherService.listClassrooms();
      if (mounted) setState(() => _classrooms = classrooms);
      setState(() {
      _classrooms = classrooms;

      if (_classroomId != null &&
          !_classrooms.any((c) => c.id == _classroomId)) {
        _classroomId = null;
      }
      });
    } on ApiException {
      // Filter dropdown just stays empty; the list itself still loads.
    }
  }

  void _load() {
    _future = TeacherService.listStudents(classroomId: _classroomId, sortBy: sortBy, order: order);
  }

  void _reload() => setState(_load);

  @override
  Widget build(BuildContext context) {

    debugPrint("Selected classroom: $_classroomId");
    for (final c in _classrooms) {
    debugPrint("id=${c.id}, name=${c.name}");
    }

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
                    _reload();
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
                    _reload();
                  },
                ),
                IconButton(
                  tooltip: order == 'asc' ? 'Ascending' : 'Descending',
                  icon: Icon(order == 'asc' ? Icons.arrow_upward : Icons.arrow_downward),
                  onPressed: () {
                    order = order == 'asc' ? 'desc' : 'asc';
                    _reload();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<StudentListItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('${(snapshot.error as ApiException?)?.message ?? snapshot.error}'));
                }
                final students = snapshot.data!;
                if (students.isEmpty) {
                  return const Center(child: Text('No students found.'));
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Surname')),
                      DataColumn(label: Text('School ID')),
                      DataColumn(label: Text('Classroom(s)')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: [
                      for (final s in students)
                        DataRow(cells: [
                          DataCell(Text(s.name)),
                          DataCell(Text(s.surname)),
                          DataCell(Text(s.schoolId)),
                          DataCell(Text(s.classrooms.join(', '))),
                          DataCell(
                            Chip(
                              label: Text(s.isRegistered ? 'Registered' : 'Pending'),
                              backgroundColor: s.isRegistered ? Colors.green.shade100 : Colors.orange.shade100,
                            ),
                          ),
                        ]),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
