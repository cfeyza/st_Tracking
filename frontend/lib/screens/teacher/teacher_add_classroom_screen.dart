import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/teacher_service.dart';
import '../../widgets/roster_editor.dart';

class TeacherAddClassroomScreen extends StatefulWidget {
  const TeacherAddClassroomScreen({super.key});

  @override
  State<TeacherAddClassroomScreen> createState() => _TeacherAddClassroomScreenState();
}

class _TeacherAddClassroomScreenState extends State<TeacherAddClassroomScreen> {
  final _nameController = TextEditingController();
  final _rosterController = RosterEditorController();
  bool _loading = false;

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Classroom name is required.')));
      return;
    }
    final students = _rosterController.collect(context);
    if (students == null) return;

    setState(() => _loading = true);
    try {
      await TeacherService.createClassroom(name, students);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Classroom created.')));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add classroom')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Classroom name (e.g. 5A)'),
            ),
            const SizedBox(height: 16),
            Text(
              'Add students to this classroom by name, surname, and school ID. '
              'You never need to place them into the right classroom afterward — this is it.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            RosterEditor(controller: _rosterController),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Import from PDF (coming soon)'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create classroom'),
            ),
          ],
        ),
      ),
    );
  }
}
