import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../models/classroom.dart';
import '../../services/api_client.dart';
import '../../services/teacher_service.dart';
import '../../widgets/roster_editor.dart';

enum _ClassroomMode { existing, newClassroom }

class TeacherAddClassroomScreen extends StatefulWidget {
  const TeacherAddClassroomScreen({super.key});

  @override
  State<TeacherAddClassroomScreen> createState() => _TeacherAddClassroomScreenState();
}

class _TeacherAddClassroomScreenState extends State<TeacherAddClassroomScreen> {
  final _nameController = TextEditingController();
  final _rosterController = RosterEditorController();
  _ClassroomMode _mode = _ClassroomMode.newClassroom;
  List<ClassroomOut> _existingClassrooms = [];
  int? _selectedClassroomId;
  bool _loadingClassrooms = true;
  bool _loading = false;
  bool _importingPdf = false;

  @override
  void initState() {
    super.initState();
    _loadExistingClassrooms();
  }

  Future<void> _loadExistingClassrooms() async {
    try {
      final classrooms = await TeacherService.listAllClassrooms();
      if (!mounted) return;
      setState(() {
        _existingClassrooms = classrooms;
        _loadingClassrooms = false;
        if (_mode == _ClassroomMode.existing && classrooms.isEmpty) {
          _mode = _ClassroomMode.newClassroom;
        }
      });
    } on ApiException {
      if (mounted) setState(() => _loadingClassrooms = false);
    }
  }

  bool _nameMatchesExisting(String name) {
    final normalized = name.trim().toLowerCase();
    return _existingClassrooms.any((c) => c.name.trim().toLowerCase() == normalized);
  }

  Future<void> _submit() async {
    final students = _rosterController.collect(context);
    if (students == null) return;

    if (_mode == _ClassroomMode.existing) {
      if (_selectedClassroomId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a classroom.')));
        return;
      }
      setState(() => _loading = true);
      try {
        await TeacherService.addToRoster(_selectedClassroomId!, students);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Roster updated.')));
        Navigator.of(context).pop(true);
      } on ApiException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Classroom name is required.')));
      return;
    }
    if (_nameMatchesExisting(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("A classroom named '$name' already exists. Pick it from the existing classrooms list instead.")),
      );
      return;
    }

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

  Future<void> _importPdf() async {
    const typeGroup = XTypeGroup(
      label: 'pdf',
      extensions: <String>['pdf'],
      mimeTypes: <String>['application/pdf'],
    );

    final file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final fileName = file.name;

    setState(() => _importingPdf = true);
    try {
      final result = await TeacherService.importClassroomsPdf(bytes, fileName);
      if (!mounted) return;
      await _showImportSummary(result);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _importingPdf = false);
    }
  }
  
  Future<void> _showImportSummary(PdfImportResult result) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import summary'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.classrooms.isEmpty)
                const Text('No classrooms could be read from this PDF.')
              else
                for (final c in result.classrooms)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${c.classroomName} (${c.createdClassroom ? 'new' : 'existing'}): '
                      '${c.studentsAdded} student${c.studentsAdded == 1 ? '' : 's'} added'
                      '${c.skipped.isEmpty ? '' : ', ${c.skipped.length} skipped (already in your roster)'}',
                    ),
                  ),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Issues:', style: Theme.of(context).textTheme.titleSmall),
                for (final e in result.errors) Text('• $e'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
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
            if (_loadingClassrooms)
              const Center(child: CircularProgressIndicator())
            else ...[
              SegmentedButton<_ClassroomMode>(
                segments: const [
                  ButtonSegment(value: _ClassroomMode.newClassroom, label: Text('New classroom')),
                  ButtonSegment(value: _ClassroomMode.existing, label: Text('Existing classroom')),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) => setState(() => _mode = selection.first),
              ),
              const SizedBox(height: 16),
              if (_mode == _ClassroomMode.existing)
                _existingClassrooms.isEmpty
                    ? const Text('You have no classrooms yet. Create a new one instead.')
                    : DropdownButtonFormField<int>(
                        initialValue: _selectedClassroomId,
                        decoration: const InputDecoration(labelText: 'Classroom'),
                        items: [
                          for (final c in _existingClassrooms) DropdownMenuItem(value: c.id, child: Text(c.name)),
                        ],
                        onChanged: (value) => setState(() => _selectedClassroomId = value),
                      )
              else
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Classroom name (e.g. 5A)'),
                ),
            ],
            const SizedBox(height: 16),
            Text(
              'Add students to this classroom by name, surname, and school ID. '
              'You never need to place them into the right classroom afterward — this is it.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            RosterEditor(controller: _rosterController),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Or import one or more classrooms straight from an e-Okul class-list PDF — '
              'the classroom and section are read from the file, so the fields above aren\'t used for this.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _importingPdf ? null : _importPdf,
              icon: _importingPdf
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: Text(_importingPdf ? 'Importing…' : 'Import from PDF'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_mode == _ClassroomMode.existing ? 'Add to roster' : 'Create classroom'),
            ),
          ],
        ),
      ),
    );
  }
}
