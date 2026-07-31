import 'package:flutter/material.dart';

import '../../models/classroom.dart';
import '../../models/paginated.dart';
import '../../services/api_client.dart';
import '../../services/teacher_service.dart';

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete classroom?'),
        content: Text(
          "This removes '${classroom.name}' and its roster links. Students themselves are not deleted.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await TeacherService.deleteClassroom(classroom.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Deleted '${classroom.name}'.")));
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
      appBar: AppBar(title: const Text('My classrooms')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).pushNamed('/teacher/add-classroom');
          if (result == true) _reload();
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<Paginated<ClassroomOut>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${(snapshot.error as ApiException?)?.message ?? snapshot.error}'));
          }
          final result = snapshot.data!;
          final classrooms = result.items;
          if (classrooms.isEmpty) {
            return const Center(child: Text('No classrooms yet. Tap + to add one.'));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: classrooms.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final classroom = classrooms[index];
                    return ListTile(
                      title: Text(classroom.name),
                      subtitle: Text('${classroom.studentCount} student(s)'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Delete classroom',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmDelete(classroom),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => Navigator.of(context).pushNamed(
                        '/teacher/students',
                        arguments: {'classroomId': classroom.id, 'classroomName': classroom.name},
                      ),
                    );
                  },
                ),
              ),
              _PaginationBar(page: result.page, totalPages: result.totalPages, onPageChange: _goToPage),
            ],
          );
        },
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
