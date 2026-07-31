import 'package:flutter/material.dart';

import '../../models/announcement.dart';
import '../../models/classroom.dart';
import '../../models/teacher.dart';
import '../../services/api_client.dart';
import '../../services/teacher_service.dart';
import '../../widgets/app_drawer.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  late Future<(TeacherDashboard, List<Announcement>)> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = Future.wait([
      TeacherService.getDashboard(),
      TeacherService.listAnnouncements(),
    ]).then((results) => (results[0] as TeacherDashboard, results[1] as List<Announcement>));
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  Future<void> _openAddAnnouncementDialog() async {
    List<ClassroomOut> classrooms;
    try {
      classrooms = await TeacherService.listAllClassrooms();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;
    if (classrooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a classroom first before posting an announcement.')),
      );
      return;
    }

    final textController = TextEditingController();
    final selected = <int>{};
    final posted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('New announcement'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: textController,
                      decoration: const InputDecoration(labelText: 'Announcement text'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    const Text('Target classroom(s)'),
                    for (final classroom in classrooms)
                      CheckboxListTile(
                        dense: true,
                        title: Text(classroom.name),
                        value: selected.contains(classroom.id),
                        onChanged: (checked) => setDialogState(() {
                          if (checked == true) {
                            selected.add(classroom.id);
                          } else {
                            selected.remove(classroom.id);
                          }
                        }),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () async {
                    if (textController.text.trim().isEmpty || selected.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Enter text and pick at least one classroom.')),
                      );
                      return;
                    }
                    try {
                      await TeacherService.createAnnouncement(textController.text.trim(), selected.toList());
                      if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                    } on ApiException catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(e.message)));
                      }
                    }
                  },
                  child: const Text('Post'),
                ),
              ],
            );
          },
        );
      },
    );

    if (posted == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher')),
      drawer: AppDrawer(
        onProfileTap: () => Navigator.of(context).pushNamed('/teacher/profile'),
        actions: [
          DrawerAction(
            icon: Icons.add_box_outlined,
            label: 'Add classroom',
            onTap: () async {
              final result =
                  await Navigator.of(context).pushNamed('/teacher/add-classroom');
              if (result == true) {
                _refresh();
              }
            },
          ),
          DrawerAction(
            icon: Icons.grade_outlined,
            label: 'Add grades',
            onTap: () => Navigator.of(context).pushNamed('/teacher/add-grade'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<(TeacherDashboard, List<Announcement>)>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Text('${snapshot.error}'))]);
            }
            final (dashboard, announcements) = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _CountCircle(
                        label: 'Classrooms',
                        count: dashboard.classroomCount,
                        onTap: () {
                          Navigator.of(context)
                            .pushNamed('/teacher/classrooms')
                            .then((_) => _refresh());
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _CountCircle(
                        label: 'Students',
                        count: dashboard.studentCount,
                        onTap: () {
                          Navigator.of(context)
                            .pushNamed('/teacher/students')
                            .then((_) => _refresh());
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        title: const Text('Announcements', style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: _openAddAnnouncementDialog,
                        ),
                      ),
                      const Divider(height: 1),
                      if (announcements.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No announcements yet.'),
                        ),
                      for (final a in announcements)
                        ListTile(
                          title: Text(a.text),
                          subtitle: Text(
                            '${a.classrooms.join(", ")} · ${a.createdAt.toLocal()}'.split('.').first,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CountCircle extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onTap;

  const _CountCircle({required this.label, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text('$count', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}
