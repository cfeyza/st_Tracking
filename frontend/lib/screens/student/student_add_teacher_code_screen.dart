import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

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
      final l10n = AppLocalizations.of(context);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.linkedToTeacher(result.teacherName)),
          content: Text(
            result.classrooms.isEmpty
                ? l10n.nowLinkedToTeacher
                : l10n.addedToClassrooms(result.classrooms.join(', ')),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.ok)),
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.addTeacherCode)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.enterTeacherCodeInstruction),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(labelText: l10n.teacherCodeLabel),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.add),
            ),
          ],
        ),
      ),
    );
  }
}
