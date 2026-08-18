import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../../models/classroom.dart';
import '../../models/grade.dart';
import '../../models/paginated.dart';
import '../../models/teacher.dart';
import '../../services/api_client.dart';
import '../../services/teacher_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/grade_card.dart';
import '../../widgets/grade_filter_bar.dart';
import '../../widgets/pagination_bar.dart';

Map<String, String> _buildSortOptions(AppLocalizations l10n) => {
      'date': l10n.date,
      'student': l10n.student,
      'subject': l10n.subject,
      'value': l10n.grade,
      'classroom': l10n.classroom,
    };

class TeacherGradesScreen extends StatefulWidget {
  const TeacherGradesScreen(
      {super.key, this.initialStudentId, this.initialStudentName});

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
      final (studentResult, classroomResult) = await (
        TeacherService.listAllStudents(),
        TeacherService.listAllClassrooms(),
      ).wait;
      if (!mounted) return;
      setState(() {
        _students = studentResult.items;
        _classrooms = classroomResult.items;
        if (_studentId != null && !_students.any((s) => s.id == _studentId)) {
          _studentId = null;
        }
      });
      final l10n = AppLocalizations.of(context);
      if (studentResult.total > studentResult.items.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.studentsListPartial(
                  studentResult.items.length, studentResult.total))),
        );
      } else if (classroomResult.total > classroomResult.items.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.classroomsListPartial(
                  classroomResult.items.length, classroomResult.total))),
        );
      }
    } on ApiException {
      // Filter dropdowns stay empty; list still loads.
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
    final cs = Theme.of(context).colorScheme;
    final sortOptions = _buildSortOptions(l10n);
    final studentName = _selectedStudentLabel;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(studentName == null ? l10n.grades : l10n.gradesWithStudent(studentName)),
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          GradeFilterBar(
            filters: [
              FilterPill(
                child: DropdownButton<int?>(
                  value: _students.any((s) => s.id == _studentId) ? _studentId : null,
                  hint: Text(l10n.filterAllStudents),
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.allStudents)),
                    for (final s in _students)
                      DropdownMenuItem(
                          value: s.id, child: Text('${s.name} ${s.surname}')),
                  ],
                  onChanged: (value) {
                    _studentId = value;
                    _reloadFromFilterChange();
                  },
                ),
              ),
              FilterPill(
                child: DropdownButton<int?>(
                  value: _classrooms.any((c) => c.id == _classroomId) ? _classroomId : null,
                  hint: Text(l10n.filterAllClassrooms),
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.allClassrooms)),
                    for (final c in _classrooms)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (value) {
                    _classroomId = value;
                    _reloadFromFilterChange();
                  },
                ),
              ),
            ],
            sortOptions: sortOptions,
            sortBy: sortBy,
            onSortByChanged: (value) {
              sortBy = value;
              _reloadFromFilterChange();
            },
            order: order,
            onToggleOrder: () {
              order = order == 'asc' ? 'desc' : 'asc';
              _reloadFromFilterChange();
            },
          ),
          Divider(height: 1, color: cs.outlineVariant),

          // Content — responsive
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
                        '${(snapshot.error as ApiException?)?.message ?? snapshot.error}'),
                  );
                }
                final result = snapshot.data!;
                final grades = result.items;
                if (grades.isEmpty) {
                  return Center(child: Text(l10n.noGradesFound));
                }
                return LayoutBuilder(builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < Bp.sm;
                  if (isMobile) {
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: AppInsets.page(context),
                            itemCount: grades.length,
                            itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GradeCard(grade: grades[i]),
                            ),
                          ),
                        ),
                        if (result.totalPages > 1)
                          PaginationBar(
                            page: result.page,
                            totalPages: result.totalPages,
                            onPageChange: _goToPage,
                          ),
                      ],
                    );
                  }
                  // Desktop / tablet: DataTable
                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: AppInsets.page(context, top: 16, bottom: 16),
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
                                      DataCell(Text(DateFormat('d MMM y')
                                          .format(g.createdAt.toLocal()))),
                                    ]),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (result.totalPages > 1)
                        PaginationBar(
                          page: result.page,
                          totalPages: result.totalPages,
                          onPageChange: _goToPage,
                        ),
                    ],
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
