import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../../models/classroom.dart';
import '../../models/paginated.dart';
import '../../models/teacher.dart';
import '../../services/api_client.dart';
import '../../services/teacher_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pagination_bar.dart';

Map<String, String> _buildStudentSortOptions(AppLocalizations l10n) => {
      'classroom': l10n.classroom,
      'name': l10n.name,
      'surname': l10n.surname,
      'school_id': l10n.schoolId,
    };

class TeacherStudentsScreen extends StatefulWidget {
  const TeacherStudentsScreen(
      {super.key, this.initialClassroomId, this.initialClassroomName});

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
          SnackBar(content: Text(l10n.classroomsListPartial(result.items.length, result.total))),
        );
      }
    } on ApiException {
      // Filter dropdown stays empty; list still loads.
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
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(dl10n.cancel)),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(dl10n.remove)),
          ],
        );
      },
    );
    if (confirmed != true) return;
    try {
      await TeacherService.deleteStudent(student.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.removedStudent(studentName))));
      if (_page > 1) _page = 1;
      _reload();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _navigateToGrades(StudentListItem s) {
    Navigator.of(context).pushNamed(
      '/teacher/grades',
      arguments: {'studentId': s.id, 'studentName': '${s.name} ${s.surname}'},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final sortOptions = _buildStudentSortOptions(l10n);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          widget.initialClassroomName == null
              ? l10n.myStudents
              : l10n.myStudentsWithClassroom(widget.initialClassroomName!),
        ),
        backgroundColor: cs.surface,
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            color: cs.surface,
            padding: AppInsets.filterBar(context),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<int?>(
                  value: _classrooms.any((c) => c.id == _classroomId) ? _classroomId : null,
                  hint: Text(l10n.filterAllClassrooms),
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
                DropdownButton<String>(
                  value: sortBy,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final e in sortOptions.entries)
                      DropdownMenuItem(value: e.key, child: Text(l10n.sortBy(e.value))),
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
          Divider(height: 1, color: cs.outlineVariant),

          // Content
          Expanded(
            child: FutureBuilder<Paginated<StudentListItem>>(
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
                final students = result.items;
                if (students.isEmpty) {
                  return Center(child: Text(l10n.noStudentsFound));
                }
                return LayoutBuilder(builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < Bp.sm;
                  if (isMobile) {
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: AppInsets.page(context),
                            itemCount: students.length,
                            itemBuilder: (_, i) {
                              final s = students[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _StudentCard(
                                  student: s,
                                  onDelete: () => _confirmDelete(s),
                                  onTap: () => _navigateToGrades(s),
                                ),
                              );
                            },
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
                  // Tablet / desktop: DataTable
                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: AppInsets.page(context, top: 16, bottom: 16),
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
                                      onSelectChanged: (_) => _navigateToGrades(s),
                                      cells: [
                                        DataCell(Text(s.name)),
                                        DataCell(Text(s.surname)),
                                        DataCell(Text(s.schoolId.toString())),
                                        DataCell(Text(s.classrooms.join(', '))),
                                        DataCell(
                                          Chip(
                                            label: Text(s.isRegistered
                                                ? l10n.registered
                                                : l10n.pending),
                                            backgroundColor: s.isRegistered
                                                ? Colors.green.shade100
                                                : Colors.orange.shade100,
                                          ),
                                        ),
                                        DataCell(
                                          PopupMenuButton<bool>(
                                            onSelected: (del) {
                                              if (del) _confirmDelete(s);
                                            },
                                            icon: Icon(Icons.more_vert,
                                                size: 20,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant),
                                            itemBuilder: (context) => [
                                              PopupMenuItem(
                                                value: true,
                                                child: Row(children: [
                                                  Icon(Icons.person_remove_outlined,
                                                      size: 20,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .error),
                                                  const SizedBox(width: 12),
                                                  Text(l10n.removeStudentTooltip,
                                                      style: TextStyle(
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .error)),
                                                ]),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
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

// Mobile card for a single student
class _StudentCard extends StatelessWidget {
  final StudentListItem student;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _StudentCard({
    required this.student,
    required this.onDelete,
    required this.onTap,
  });

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person_outline, color: cs.primary, size: 20),
              ),
              const SizedBox(width: 12),
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
                      student.classrooms.isNotEmpty
                          ? '${student.classrooms.join(', ')} · ${l10n.schoolId}: ${student.schoolId}'
                          : '${l10n.schoolId}: ${student.schoolId}',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: student.isRegistered
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        student.isRegistered ? l10n.registered : l10n.pending,
                        style: tt.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<bool>(
                onSelected: (del) { if (del) onDelete(); },
                icon: Icon(Icons.more_vert, size: 20, color: cs.onSurfaceVariant),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: true,
                    child: Row(children: [
                      Icon(Icons.person_remove_outlined, size: 20, color: cs.error),
                      const SizedBox(width: 12),
                      Text(l10n.removeStudentTooltip,
                          style: TextStyle(color: cs.error)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
