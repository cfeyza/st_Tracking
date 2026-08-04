import 'package:flutter/material.dart';

import '../models/classroom.dart';

/// Editable list of (name, surname, school ID) rows for manual roster entry.
/// Call [collect] to validate and read out the current rows.
class RosterEditor extends StatefulWidget {
  const RosterEditor({super.key, required this.controller});

  final RosterEditorController controller;

  @override
  State<RosterEditor> createState() => _RosterEditorState();
}

class _RosterRow {
  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  final schoolIdController = TextEditingController();
}

class RosterEditorController {
  _RosterEditorState? _state;

  /// Returns the entered rows, or null (and shows a snackbar) if any row is
  /// incomplete.
  List<RosterStudentIn>? collect(BuildContext context) {
    final rows = _state?._rows ?? [];
    final result = <RosterStudentIn>[];
    for (final row in rows) {
      final name = row.nameController.text.trim();
      final surname = row.surnameController.text.trim();
      final schoolIdText = row.schoolIdController.text.trim();
      if (name.isEmpty && surname.isEmpty && schoolIdText.isEmpty) continue;
      if (name.isEmpty || surname.isEmpty || schoolIdText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fill in name, surname, and school ID for every roster row (or remove it).')),
        );
        return null;
      }
      final schoolId = int.tryParse(schoolIdText);
      if (schoolId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('School ID must be a number.')),
        );
        return null;
      }
      result.add(RosterStudentIn(name: name, surname: surname, schoolId: schoolId));
    }
    return result;
  }
}

class _RosterEditorState extends State<RosterEditor> {
  final List<_RosterRow> _rows = [_RosterRow()];

  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
  }

  void _addRow() => setState(() => _rows.add(_RosterRow()));

  void _removeRow(int index) => setState(() => _rows.removeAt(index));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Students', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(onPressed: _addRow, icon: const Icon(Icons.add), label: const Text('Add row')),
          ],
        ),
        for (int i = 0; i < _rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rows[i].nameController,
                    decoration: const InputDecoration(labelText: 'Name', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _rows[i].surnameController,
                    decoration: const InputDecoration(labelText: 'Surname', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _rows[i].schoolIdController,
                    decoration: const InputDecoration(labelText: 'School ID', isDense: true),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  onPressed: _rows.length > 1 ? () => _removeRow(i) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
