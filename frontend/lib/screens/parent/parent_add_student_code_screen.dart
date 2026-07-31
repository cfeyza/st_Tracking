import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/parent_service.dart';

class ParentAddStudentCodeScreen extends StatefulWidget {
  const ParentAddStudentCodeScreen({super.key});

  @override
  State<ParentAddStudentCodeScreen> createState() => _ParentAddStudentCodeScreenState();
}

class _ParentAddStudentCodeScreenState extends State<ParentAddStudentCodeScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ParentService.addStudentCode(code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student linked.')));
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
      appBar: AppBar(title: const Text('Add student code')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Enter your child's student code (found on their profile page)."),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Student code'),
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
