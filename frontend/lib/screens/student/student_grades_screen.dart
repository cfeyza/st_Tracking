import 'package:flutter/material.dart';

import '../../models/grade.dart';
import '../../services/api_client.dart';
import '../../services/student_service.dart';

class StudentGradesScreen extends StatefulWidget {
  const StudentGradesScreen({super.key});

  @override
  State<StudentGradesScreen> createState() => _StudentGradesScreenState();
}

class _StudentGradesScreenState extends State<StudentGradesScreen> {
  late Future<List<Grade>> _future;

  @override
  void initState() {
    super.initState();
    _future = StudentService.listGrades();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My grades')),
      body: FutureBuilder<List<Grade>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${(snapshot.error as ApiException?)?.message ?? snapshot.error}'));
          }
          final grades = snapshot.data!;
          if (grades.isEmpty) {
            return const Center(child: Text('No grades yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: grades.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final g = grades[index];
              return ListTile(
                leading: CircleAvatar(child: Text(g.value)),
                title: Text(g.subject),
                subtitle: Text(
                  '${g.teacherName}${g.classroomName != null ? " · ${g.classroomName}" : ""}\n'
                  '${g.createdAt.toLocal().toString().split('.').first}',
                ),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
