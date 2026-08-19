import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../../models/classroom.dart';
import '../../models/paginated.dart';
import '../../services/api_client.dart';
import '../../services/teacher_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pagination_bar.dart';

class TeacherClassroomsScreen extends StatefulWidget {
  const TeacherClassroomsScreen({super.key});

  @override
  State<TeacherClassroomsScreen> createState() => _TeacherClassroomsScreenState();
}

class _TeacherClassroomsScreenState extends State<TeacherClassroomsScreen> {
  int _page = 1;
  late Future<Paginated<ClassroomOut>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = TeacherService.listClassrooms(page: _page);
  }

  void _reload() => setState(_load);

  void _goToPage(int page) {
    setState(() {
      _page = page;
      _load();
    });
  }

  Future<void> _confirmDelete(ClassroomOut classroom) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dl10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(dl10n.deleteClassroomTitle),
          content: Text(dl10n.deleteClassroomConfirm(classroom.name)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(dl10n.cancel)),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(dl10n.delete)),
          ],
        );
      },
    );
    if (confirmed != true) return;
    try {
      await TeacherService.deleteClassroom(classroom.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.deletedClassroom(classroom.name))));
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myClassrooms),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).pushNamed('/teacher/add-classroom');
          if (result == true) _reload();
        },
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: const ContentShapesPainter())),
          FutureBuilder<Paginated<ClassroomOut>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                    child: Text('${(snapshot.error as ApiException?)?.message ?? snapshot.error}'));
              }
              final result = snapshot.data!;
              final classrooms = result.items;
              return Column(
                children: [
                  Expanded(
                    child: classrooms.isEmpty
                        ? EmptyState(icon: Icons.class_outlined, message: l10n.noClassroomsYet)
                        : ListView.builder(
                            padding: AppInsets.listWithFab(context),
                            itemCount: classrooms.length,
                            itemBuilder: (context, index) {
                              final c = classrooms[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _ClassroomCard(
                                  classroom: c,
                                  onDelete: () => _confirmDelete(c),
                                  onTap: () => Navigator.of(context).pushNamed(
                                    '/teacher/students',
                                    arguments: {'classroomId': c.id, 'classroomName': c.name},
                                  ),
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
            },
          ),
        ],
      ),
    );
  }
}

class _ClassroomCard extends StatelessWidget {
  final ClassroomOut classroom;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _ClassroomCard({required this.classroom, required this.onDelete, required this.onTap});

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.class_outlined, color: cs.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(classroom.name,
                        style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(l10n.studentCount(classroom.studentCount),
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              PopupMenuButton<bool>(
                onSelected: (delete) { if (delete) onDelete(); },
                icon: Icon(Icons.more_vert, size: 20, color: cs.onSurfaceVariant),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: true,
                    child: Row(children: [
                      Icon(Icons.delete_outline, size: 20, color: cs.error),
                      const SizedBox(width: 12),
                      Text(l10n.deleteClassroomTooltip,
                          style: TextStyle(color: cs.error)),
                    ]),
                  ),
                ],
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
