import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../../models/classroom.dart';
import '../../models/paginated.dart';
import '../../models/teacher.dart';
import '../../services/api_client.dart';
import '../../services/teacher_service.dart';

Map<String, String> _buildStudentSortOptions(AppLocalizations l10n) => {
  'classroom': l10n.classroom,
  'name': l10n.name,
  'surname': l10n.surname,
  'school_id': l10n.schoolId,
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
      final result = await TeacherService.listAllClassrooms();
      if (!mounted) return;
      setState(() {
        _classrooms = result.items;
        if (_classroomId != null && !_classrooms.any((c) => c.id == _classroomId)) {
          _classroomId = null;
        }
      });
      if (result.total > result.items.length) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.classroomsListPartial(fetched: result.items.length, total: result.total))),
        );
      }
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
    final l10n = AppLocalizations.of(context);
    final studentName = '${student.name} ${student.surname}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dl10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(dl10n.removeStudentTitle),
          content: Text(dl10n.removeStudentConfirm(studentName)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(dl10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(dl10n.remove)),
          ],
        );
      },
    );
    if (confirmed != true) return;

    try {
      await TeacherService.deleteStudent(student.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.removedStudent(studentName))),
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
    final l10n = AppLocalizations.of(context);
    final sortOptions = _buildStudentSortOptions(l10n);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialClassroomName == null
              ? l10n.myStudents
              : l10n.myStudentsWithClassroom(widget.initialClassroomName!),
        ),
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
                  return Center(child: Text(l10n.noStudentsFound));
                }
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            showCheckboxColumn: false,
                            columns: [
                              DataColumn(label: Text(l10n.name)),
                              DataColumn(label: Text(l10n.surname)),
                              DataColumn(label: Text(l10n.schoolId)),
                              DataColumn(label: Text(l10n.classroomsColumn)),
                              DataColumn(label: Text(l10n.status)),
                              const DataColumn(label: Text('')),
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
                                        label: Text(s.isRegistered ? l10n.registered : l10n.pending),
                                        backgroundColor:
                                            s.isRegistered ? Colors.green.shade100 : Colors.orange.shade100,
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        tooltip: l10n.removeStudentTooltip,
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
