import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    final rows = _state?._rows ?? [];
    final result = <RosterStudentIn>[];
    for (final row in rows) {
      final name = row.nameController.text.trim();
      final surname = row.surnameController.text.trim();
      final schoolIdText = row.schoolIdController.text.trim();
      if (name.isEmpty && surname.isEmpty && schoolIdText.isEmpty) continue;
      if (name.isEmpty || surname.isEmpty || schoolIdText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.fillInAllRosterFields)),
        );
        return null;
      }
      final schoolId = int.tryParse(schoolIdText);
      if (schoolId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.schoolIdMustBeNumberRoster)),
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

  @override
  void dispose() {
    for (final row in _rows) {
      row.nameController.dispose();
      row.surnameController.dispose();
      row.schoolIdController.dispose();
    }
    super.dispose();
  }

  void _addRow() => setState(() => _rows.add(_RosterRow()));

  void _removeRow(int index) {
    final row = _rows[index];
    setState(() => _rows.removeAt(index));
    row.nameController.dispose();
    row.surnameController.dispose();
    row.schoolIdController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(l10n.studentsSection, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(onPressed: _addRow, icon: const Icon(Icons.add), label: Text(l10n.addRow)),
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
                    decoration: InputDecoration(labelText: l10n.name, isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _rows[i].surnameController,
                    decoration: InputDecoration(labelText: l10n.surname, isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _rows[i].schoolIdController,
                    decoration: InputDecoration(labelText: l10n.schoolId, isDense: true),
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
