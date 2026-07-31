import 'package:flutter/material.dart';

import '../../models/classroom.dart';
import '../../services/api_client.dart';
import '../../services/teacher_service.dart';

class TeacherClassroomsScreen extends StatefulWidget {
  const TeacherClassroomsScreen({super.key});

  @override
  State<TeacherClassroomsScreen> createState() => _TeacherClassroomsScreenState();
}

class _TeacherClassroomsScreenState extends State<TeacherClassroomsScreen> {
  late Future<List<ClassroomOut>> _future;

  @override
  void initState() {
    super.initState();
    _future = TeacherService.listClassrooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My classrooms')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/teacher/add-classroom'),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<ClassroomOut>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${(snapshot.error as ApiException?)?.message ?? snapshot.error}'));
          }
          final classrooms = snapshot.data!;
          if (classrooms.isEmpty) {
            return const Center(child: Text('No classrooms yet. Tap + to add one.'));
          }
          return ListView.separated(
            itemCount: classrooms.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final classroom = classrooms[index];
              return ListTile(
                title: Text(classroom.name),
                subtitle: Text('${classroom.studentCount} student(s)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamed(
                  '/teacher/students',
                  arguments: {'classroomId': classroom.id, 'classroomName': classroom.name},
                ),
              );
            },
          );
        },
      ),
    );
  }
}
