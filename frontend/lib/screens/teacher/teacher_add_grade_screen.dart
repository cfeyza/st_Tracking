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
  late Future<List<ClassroomOut>> _classroomsFuture;
  Future<List<StudentListItem>>? _studentsFuture;
  int? _classroomId;
  int? _studentId;
  final _subjectController = TextEditingController();
  final _valueController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _classroomsFuture = TeacherService.listAllClassrooms();
  }

  void _onClassroomChanged(int? classroomId) {
    setState(() {
      _classroomId = classroomId;
      _studentId = null;
      _studentsFuture = classroomId == null
          ? null
          : TeacherService.listStudents(classroomId: classroomId, pageSize: 100).then((p) => p.items);
    });
  }

  Future<void> _submit() async {
    if (_classroomId == null || _studentId == null || _subjectController.text.trim().isEmpty ||
        _valueController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a classroom and student, and fill in subject and grade.')),
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
      body: FutureBuilder<List<ClassroomOut>>(
        future: _classroomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${(snapshot.error as ApiException?)?.message ?? snapshot.error}'));
          }
          final classrooms = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _classroomId,
                  decoration: const InputDecoration(labelText: 'Classroom'),
                  items: [
                    for (final c in classrooms) DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: _onClassroomChanged,
                ),
                const SizedBox(height: 16),
                if (_classroomId == null)
                  const InputDecorator(
                    decoration: InputDecoration(labelText: 'Student'),
                    child: Text('Select a classroom first'),
                  )
                else
                  FutureBuilder<List<StudentListItem>>(
                    future: _studentsFuture,
                    builder: (context, studentSnapshot) {
                      if (studentSnapshot.connectionState != ConnectionState.done) {
                        return const InputDecorator(
                          decoration: InputDecoration(labelText: 'Student'),
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      if (studentSnapshot.hasError) {
                        return InputDecorator(
                          decoration: const InputDecoration(labelText: 'Student'),
                          child: Text(
                            '${(studentSnapshot.error as ApiException?)?.message ?? studentSnapshot.error}',
                          ),
                        );
                      }
                      final students = studentSnapshot.data!;
                      return DropdownButtonFormField<int>(
                        initialValue: _studentId,
                        decoration: const InputDecoration(labelText: 'Student'),
                        items: [
                          for (final s in students)
                            DropdownMenuItem(value: s.id, child: Text('${s.name} ${s.surname} (${s.schoolId})')),
                        ],
                        onChanged: (v) => setState(() => _studentId = v),
                      );
                    },
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
