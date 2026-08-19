import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../../models/classroom.dart';
import '../../models/teacher.dart';
import '../../services/api_client.dart';
import '../../services/teacher_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/teal_input_field.dart';

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
    if (_classroomId == null ||
        _studentId == null ||
        _subjectController.text.trim().isEmpty ||
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
    final mq = MediaQuery.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addGrades)),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: const ContentShapesPainter())),
          FutureBuilder<List<ClassroomOut>>(
            future: _classroomsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('${(snapshot.error as ApiException?)?.message ?? snapshot.error}'),
                );
              }
              final classrooms = snapshot.data!;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, mq.padding.bottom + 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Gradient header card
                    GradientCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                l10n.pickClassroomAndStudentGradeHint,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Form card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryCyan.withOpacity(0.10),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Classroom
                          _FieldRow(
                            icon: Icons.class_outlined,
                            child: DropdownButtonFormField<int>(
                              initialValue: _classroomId,
                              decoration: InputDecoration(labelText: l10n.classroom),
                              items: [
                                for (final c in classrooms)
                                  DropdownMenuItem(value: c.id, child: Text(c.name)),
                              ],
                              onChanged: _onClassroomChanged,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Student
                          if (_classroomId == null)
                            _FieldRow(
                              icon: Icons.person_outline_rounded,
                              child: InputDecorator(
                                decoration: InputDecoration(labelText: l10n.student),
                                child: Text(l10n.selectClassroomFirst,
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              ),
                            )
                          else
                            FutureBuilder<List<StudentListItem>>(
                              future: _studentsFuture,
                              builder: (context, studentSnapshot) {
                                if (studentSnapshot.connectionState != ConnectionState.done) {
                                  return _FieldRow(
                                    icon: Icons.person_outline_rounded,
                                    child: InputDecorator(
                                      decoration: InputDecoration(labelText: l10n.student),
                                      child: const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                  );
                                }
                                if (studentSnapshot.hasError) {
                                  return _FieldRow(
                                    icon: Icons.person_outline_rounded,
                                    child: InputDecorator(
                                      decoration: InputDecoration(labelText: l10n.student),
                                      child: Text(
                                        '${(studentSnapshot.error as ApiException?)?.message ?? studentSnapshot.error}',
                                      ),
                                    ),
                                  );
                                }
                                final students = studentSnapshot.data!;
                                return _FieldRow(
                                  icon: Icons.person_outline_rounded,
                                  child: DropdownButtonFormField<int>(
                                    initialValue: _studentId,
                                    decoration: InputDecoration(labelText: l10n.student),
                                    isExpanded: true,
                                    items: [
                                      for (final s in students)
                                        DropdownMenuItem(
                                          value: s.id,
                                          child: Text(
                                            '${s.name} ${s.surname} (${s.schoolId})',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                    onChanged: (v) => setState(() => _studentId = v),
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 14),

                          // Subject
                          TealInputField(
                            controller: _subjectController,
                            label: l10n.subjectLabel,
                            icon: Icons.book_outlined,
                          ),
                          const SizedBox(height: 14),

                          // Grade value
                          TealInputField(
                            controller: _valueController,
                            label: l10n.gradeValueLabel,
                            icon: Icons.stars_rounded,
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(height: 24),

                          FilledButton(
                            onPressed: _submitting ? null : _submit,
                            child: _submitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(l10n.addGrade),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Drawer-style row: teal icon box on the left, form field on the right
class _FieldRow extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _FieldRow({required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryCyan.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primaryCyan),
        ),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }
}
