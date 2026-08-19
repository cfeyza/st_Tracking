import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../../models/grade.dart';
import '../../models/paginated.dart';
import '../../models/student.dart';
import '../../services/api_client.dart';
import '../../services/parent_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/grade_card.dart';
import '../../widgets/grade_filter_bar.dart';
import '../../widgets/pagination_bar.dart';

Map<String, String> _buildSortOptions(AppLocalizations l10n) => {
      'date': l10n.date,
      'subject': l10n.subject,
      'value': l10n.grade,
      'teacher': l10n.teacher,
    };

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
    final cs = Theme.of(context).colorScheme;
    final sortOptions = _buildSortOptions(l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.gradesWithStudent(widget.studentName)),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: const ContentShapesPainter())),
          Column(
        children: [
          GradeFilterBar(
            teachers: _teachers,
            selectedTeacherId: _selectedTeacherId,
            onTeacherChanged: _onTeacherChanged,
            sortOptions: sortOptions,
            sortBy: _sortBy,
            onSortByChanged: _onSortByChanged,
            order: _order,
            onToggleOrder: _toggleOrder,
          ),
          Divider(height: 1, color: cs.outlineVariant),
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
                  return EmptyState(
                    icon: Icons.grade_outlined,
                    message: l10n.noGradesYet,
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: AppInsets.page(context),
                        itemCount: grades.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GradeCard(grade: grades[index]),
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
              },
            ),
          ),
        ],
          ),
        ],
      ),
    );
  }
}
