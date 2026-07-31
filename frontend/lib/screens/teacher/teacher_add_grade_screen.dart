import 'package:flutter/material.dart';

import '../../models/classroom.dart';
import '../../models/teacher.dart';
import '../../services/api_client.dart';
import '../../services/teacher_service.dart';

class TeacherAddGradeScreen extends StatefulWidget {
  const TeacherAddGradeScreen({super.key});

  @override
  State<TeacherAddGradeScreen> createState() => _TeacherAddGradeScreenState();
}

class _TeacherAddGradeScreenState extends State<TeacherAddGradeScreen> {
  late Future<(List<StudentListItem>, List<ClassroomOut>)> _future;
  int? _studentId;
  int? _classroomId;
  final _subjectController = TextEditingController();
  final _valueController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _future = Future.wait([
      TeacherService.listStudents(),
      TeacherService.listClassrooms(),
    ]).then((r) => (r[0] as List<StudentListItem>, r[1] as List<ClassroomOut>));
  }

  Future<void> _submit() async {
    if (_studentId == null || _subjectController.text.trim().isEmpty || _valueController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a student and fill in subject and grade.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await TeacherService.addGrade(
        studentId: _studentId!,
        classroomId: _classroomId,
        subject: _subjectController.text.trim(),
        value: _valueController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grade added.')));
      _subjectController.clear();
      _valueController.clear();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add grades')),
      body: FutureBuilder<(List<StudentListItem>, List<ClassroomOut>)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${(snapshot.error as ApiException?)?.message ?? snapshot.error}'));
          }
          final (students, classrooms) = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _studentId,
                  decoration: const InputDecoration(labelText: 'Student'),
                  items: [
                    for (final s in students)
                      DropdownMenuItem(value: s.id, child: Text('${s.name} ${s.surname} (${s.schoolId})')),
                  ],
                  onChanged: (v) => setState(() => _studentId = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  initialValue: _classroomId,
                  decoration: const InputDecoration(labelText: 'Classroom (optional)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    for (final c in classrooms) DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) => setState(() => _classroomId = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _subjectController,
                  decoration: const InputDecoration(labelText: 'Subject (e.g. Math)'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _valueController,
                  decoration: const InputDecoration(labelText: 'Grade (e.g. 85 or A-)'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Add grade'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
