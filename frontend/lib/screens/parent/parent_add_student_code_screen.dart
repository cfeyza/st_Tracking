import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

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
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.studentLinked)));
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.addStudentCode)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.enterChildStudentCode),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(labelText: l10n.studentCodeLabel),
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
