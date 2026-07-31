import 'package:flutter/material.dart';

import '../../models/parent.dart';
import '../../services/api_client.dart';
import '../../services/parent_service.dart';

class ParentStudentsScreen extends StatefulWidget {
  const ParentStudentsScreen({super.key});

  @override
  State<ParentStudentsScreen> createState() => _ParentStudentsScreenState();
}

class _ParentStudentsScreenState extends State<ParentStudentsScreen> {
  late Future<List<ParentStudentListItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = ParentService.listStudents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My students')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/parent/add-student-code'),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<ParentStudentListItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${(snapshot.error as ApiException?)?.message ?? snapshot.error}'));
          }
          final students = snapshot.data!;
          if (students.isEmpty) {
            return const Center(child: Text('No students linked yet. Tap + to add one.'));
          }
          return ListView.separated(
            itemCount: students.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final s = students[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text('${s.name} ${s.surname}'),
                subtitle: Text('School ID: ${s.schoolId}'),
              );
            },
          );
        },
      ),
    );
  }
}
