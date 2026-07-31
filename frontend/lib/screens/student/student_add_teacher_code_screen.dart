import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/student_service.dart';

class StudentAddTeacherCodeScreen extends StatefulWidget {
  const StudentAddTeacherCodeScreen({super.key});

  @override
  State<StudentAddTeacherCodeScreen> createState() => _StudentAddTeacherCodeScreenState();
}

class _StudentAddTeacherCodeScreenState extends State<StudentAddTeacherCodeScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _loading = true);
    try {
      final result = await StudentService.addTeacherCode(code);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Linked to ${result.teacherName}'),
          content: Text(
            result.classrooms.isEmpty
                ? "You're now linked to this teacher."
                : "You've been added to: ${result.classrooms.join(", ")}",
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
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
      appBar: AppBar(title: const Text('Add teacher code')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter the code your teacher gave you. You must already be on that '
              'teacher\'s classroom roster (matched by your name, surname, and school ID) '
              'for this to work.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Teacher code'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
