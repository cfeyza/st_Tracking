import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

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
    _classroomsFuture = TeacherService.listAllClassrooms().then((r) => r.items);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _valueController.dispose();
    super.dispose();
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
    final l10n = AppLocalizations.of(context);
    if (_classroomId == null || _studentId == null || _subjectController.text.trim().isEmpty ||
        _valueController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pickClassroomAndStudentGradeError)),
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
      final ll10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ll10n.gradeAdded)));
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.addGrades)),
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
                  decoration: InputDecoration(labelText: l10n.classroom),
                  items: [
                    for (final c in classrooms) DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: _onClassroomChanged,
                ),
                const SizedBox(height: 16),
                if (_classroomId == null)
                  InputDecorator(
                    decoration: InputDecoration(labelText: l10n.student),
                    child: Text(l10n.selectClassroomFirst),
                  )
                else
                  FutureBuilder<List<StudentListItem>>(
                    future: _studentsFuture,
                    builder: (context, studentSnapshot) {
                      if (studentSnapshot.connectionState != ConnectionState.done) {
                        return InputDecorator(
                          decoration: InputDecoration(labelText: l10n.student),
                          child: const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      if (studentSnapshot.hasError) {
                        return InputDecorator(
                          decoration: InputDecoration(labelText: l10n.student),
                          child: Text(
                            '${(studentSnapshot.error as ApiException?)?.message ?? studentSnapshot.error}',
                          ),
                        );
                      }
                      final students = studentSnapshot.data!;
                      return DropdownButtonFormField<int>(
                        initialValue: _studentId,
                        decoration: InputDecoration(labelText: l10n.student),
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
                  decoration: InputDecoration(labelText: l10n.subjectLabel),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _valueController,
                  decoration: InputDecoration(labelText: l10n.gradeValueLabel),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.addGrade),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
