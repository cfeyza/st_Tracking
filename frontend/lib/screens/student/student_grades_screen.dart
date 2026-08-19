import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../../models/grade.dart';
import '../../models/paginated.dart';
import '../../models/student.dart';
import '../../services/api_client.dart';
import '../../services/student_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/grade_card.dart';
import '../../widgets/grade_filter_bar.dart';
import '../../widgets/pagination_bar.dart';

Map<String, String> _buildGradeSortOptions(AppLocalizations l10n) => {
      'date': l10n.date,
      'subject': l10n.subject,
      'value': l10n.grade,
      'teacher': l10n.teacher,
    };

class StudentGradesScreen extends StatefulWidget {
  const StudentGradesScreen({super.key});

  @override
  State<StudentGradesScreen> createState() => _StudentGradesScreenState();
}

class _StudentGradesScreenState extends State<StudentGradesScreen> {
  int _page = 1;
  int? _selectedTeacherId;
  List<TeacherFilterItem>? _teachers;
  String _sortBy = 'date';
  String _order = 'desc';
  late Future<Paginated<Grade>> _future;

  @override
  void initState() {
    super.initState();
    _future = StudentService.listGrades(page: _page, sortBy: _sortBy, order: _order);
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    final teachers = await StudentService.listGradeTeachers();
    if (mounted) setState(() => _teachers = teachers);
  }

  void _load() {
    _future = StudentService.listGrades(
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
    final sortOptions = _buildGradeSortOptions(l10n);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(l10n.myGrades),
      ),
      body: Column(
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
                          '${(snapshot.error as ApiException?)?.message ?? snapshot.error}'));
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
    );
  }
}
