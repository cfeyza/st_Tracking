import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../../models/announcement.dart';
import '../../models/announcement_readers.dart';
import '../../models/classroom.dart';
import '../../models/paginated.dart';
import '../../models/teacher.dart';
import '../../services/api_client.dart';
import '../../services/teacher_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/meta_badge.dart';
import '../../widgets/pagination_bar.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _page = 1;
  late Future<(TeacherDashboard, Paginated<Announcement>)> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = Future.wait([
      TeacherService.getDashboard(),
      TeacherService.listAnnouncements(page: _page),
    ]).then((r) => (r[0] as TeacherDashboard, r[1] as Paginated<Announcement>));
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  void _goToPage(int page) {
    setState(() {
      _page = page;
      _load();
    });
  }

  // ── Add announcement ─────────────────────────────────────────────────────────

  Future<void> _openAddAnnouncementDialog() async {
    final l10n = AppLocalizations.of(context);
    List<ClassroomOut> classrooms;
    int classroomsTotal;
    try {
      final result = await TeacherService.listAllClassrooms();
      classrooms = result.items;
      classroomsTotal = result.total;
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;
    if (classroomsTotal > classrooms.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.classroomsListPartial(classrooms.length, classroomsTotal))),
      );
    }
    if (classrooms.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.addClassroomFirst)));
      return;
    }

    final posted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _AddAnnouncementDialog(classrooms: classrooms),
    );

    if (posted == true) _goToPage(1);
  }

  // ── Delete announcement ──────────────────────────────────────────────────────

  Future<void> _confirmDeleteAnnouncement(Announcement announcement) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dl10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(dl10n.deleteAnnouncementTitle),
          content: Text(dl10n.deleteAnnouncementConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(dl10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(dl10n.delete),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    try {
      await TeacherService.deleteAnnouncement(announcement.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.deletedAnnouncement)));
      if (_page > 1) _page = 1;
      _refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────────

  void _showAnnouncementTextDialog(Announcement announcement) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final dl10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SingleChildScrollView(
            child: Text(
              announcement.text,
              style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(dl10n.ok),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showReadersDialog(Announcement announcement) async {
    AnnouncementReaders readers;
    try {
      readers = await TeacherService.getAnnouncementReaders(announcement.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final dl10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(dl10n.announcementReaders),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dl10n.studentsWhoRead(readers.readers.length),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (readers.readers.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('—')),
                  for (final s in readers.readers)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.check_circle,
                        color: Theme.of(dialogContext).colorScheme.primary,
                        size: 20,
                      ),
                      title: Text('${s.name} ${s.surname}'),
                      subtitle: s.readAt != null
                          ? Text(
                              DateFormat('d MMM y · HH:mm', dl10n.localeName).format(s.readAt!.toLocal()),
                              style: const TextStyle(fontSize: 11),
                            )
                          : null,
                    ),
                  const SizedBox(height: 12),
                  Text(
                    dl10n.studentsWhoHaventRead(readers.nonReaders.length),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (readers.nonReaders.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('—')),
                  for (final s in readers.nonReaders)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.radio_button_unchecked, size: 20),
                      title: Text('${s.name} ${s.surname}'),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(dl10n.ok),
            ),
          ],
        );
      },
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.teacher),
      ),
      drawer: AppDrawer(
        onProfileTap: () => Navigator.of(context).pushNamed('/teacher/profile'),
        actions: [
          DrawerAction(
            icon: Icons.add_box_outlined,
            label: l10n.addClassroom,
            onTap: () async {
              final result = await Navigator.of(context).pushNamed('/teacher/add-classroom');
              if (result == true) _refresh();
            },
          ),
          DrawerAction(
            icon: Icons.grade_outlined,
            label: l10n.addGrades,
            onTap: () => Navigator.of(context).pushNamed('/teacher/add-grade-options'),
          ),
          DrawerAction(
            icon: Icons.list_alt,
            label: l10n.grades,
            onTap: () => Navigator.of(context).pushNamed('/teacher/grades'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: const ContentShapesPainter())),
          RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<(TeacherDashboard, Paginated<Announcement>)>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('${snapshot.error}'),
                ),
              ]);
            }
            final (dashboard, result) = snapshot.data!;
            final announcements = result.items;
            final padding = AppInsets.page(context, bottom: 32);

            return ListView(
              padding: padding,
              children: [
                // ── Stats ─────────────────────────────────────────────
                _StatsRow(
                  dashboard: dashboard,
                  onClassroomsTap: () =>
                      Navigator.of(context).pushNamed('/teacher/classrooms').then((_) => _refresh()),
                  onStudentsTap: () =>
                      Navigator.of(context).pushNamed('/teacher/students').then((_) => _refresh()),
                ),
                const SizedBox(height: 24),

                // ── Announcements header ───────────────────────────────
                Row(
                  children: [
                    Text(
                      l10n.announcements,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: l10n.newAnnouncement,
                      onPressed: _openAddAnnouncementDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // ── Empty state ────────────────────────────────────────
                if (result.total == 0)
                  Card(
                    color: cs.surfaceContainerLow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Column(
                        children: [
                          Icon(Icons.campaign_outlined,
                              size: 40, color: cs.onSurfaceVariant.withAlpha(120)),
                          const SizedBox(height: 8),
                          Text(l10n.noAnnouncementsYet,
                              style: TextStyle(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),

                // ── Announcement cards ─────────────────────────────────
                for (final a in announcements)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AnnouncementCard(
                      announcement: a,
                      onTap: () => _showAnnouncementTextDialog(a),
                      onViewReaders: () => _showReadersDialog(a),
                      onDelete: () => _confirmDeleteAnnouncement(a),
                    ),
                  ),

                // ── Pagination ─────────────────────────────────────────
                if (result.totalPages > 1)
                  PaginationBar(
                    page: result.page,
                    totalPages: result.totalPages,
                    onPageChange: _goToPage,
                  ),
              ],
            );
          },
        ),
      ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats row — adapts from horizontal (>=360px) to vertical on very small phones
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final TeacherDashboard dashboard;
  final VoidCallback onClassroomsTap;
  final VoidCallback onStudentsTap;

  const _StatsRow({
    required this.dashboard,
    required this.onClassroomsTap,
    required this.onStudentsTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 320;
      final classCard = _StatCard(
        icon: Icons.class_outlined,
        label: l10n.classrooms,
        count: dashboard.classroomCount,
        onTap: onClassroomsTap,
      );
      final studentCard = _StatCard(
        icon: Icons.people_alt_outlined,
        label: l10n.students,
        count: dashboard.studentCount,
        onTap: onStudentsTap,
      );
      if (isNarrow) {
        return Column(children: [classCard, const SizedBox(height: 10), studentCard]);
      }
      return Row(
        children: [
          Expanded(child: classCard),
          const SizedBox(width: 12),
          Expanded(child: studentCard),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat card
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GradientCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.28),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    label,
                    style: tt.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.75),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Announcement card
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Add-announcement dialog — owns the TextEditingController so dispose() is
// called by the framework after the closing animation finishes, not before.
// ─────────────────────────────────────────────────────────────────────────────

class _AddAnnouncementDialog extends StatefulWidget {
  final List<ClassroomOut> classrooms;

  const _AddAnnouncementDialog({required this.classrooms});

  @override
  State<_AddAnnouncementDialog> createState() => _AddAnnouncementDialogState();
}

class _AddAnnouncementDialogState extends State<_AddAnnouncementDialog> {
  final _textController = TextEditingController();
  final _selected = <int>{};
  var _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.newAnnouncement),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _textController,
                decoration: InputDecoration(labelText: l10n.announcementText),
                maxLines: null,
                minLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 12),
              Text(l10n.targetClassrooms),
              for (final classroom in widget.classrooms)
                CheckboxListTile(
                  dense: true,
                  title: Text(classroom.name),
                  value: _selected.contains(classroom.id),
                  onChanged: _isSending
                      ? null
                      : (checked) => setState(() {
                            if (checked == true) {
                              _selected.add(classroom.id);
                            } else {
                              _selected.remove(classroom.id);
                            }
                          }),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSending
              ? null
              : () async {
                  if (_textController.text.trim().isEmpty || _selected.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.enterTextAndPickClassroom)),
                    );
                    return;
                  }
                  setState(() => _isSending = true);
                  try {
                    await TeacherService.createAnnouncement(
                        _textController.text.trim(), _selected.toList());
                    if (mounted) Navigator.pop(context, true);
                  } on ApiException catch (e) {
                    if (mounted) {
                      setState(() => _isSending = false);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  }
                },
          child: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.post),
        ),
      ],
    );
  }
}

enum _AnnouncementMenuAction { viewReaders, delete }

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onTap;
  final VoidCallback onViewReaders;
  final VoidCallback onDelete;

  const _AnnouncementCard({
    required this.announcement,
    required this.onTap,
    required this.onViewReaders,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final dateStr = DateFormat('d MMM · HH:mm', Localizations.localeOf(context).toString()).format(announcement.createdAt.toLocal());

    return Card(
      shape: AppCard.shape(cs),
      color: cs.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Teal icon box
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.campaign_rounded, size: 18,
                      color: AppColors.primaryCyan),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium?.copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: [
                              for (final c in announcement.classrooms)
                                MetaBadge.classroom(c),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(dateStr,
                            style: tt.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
              // Single popup menu — view readers + delete
              PopupMenuButton<_AnnouncementMenuAction>(
                onSelected: (action) {
                  switch (action) {
                    case _AnnouncementMenuAction.viewReaders:
                      onViewReaders();
                    case _AnnouncementMenuAction.delete:
                      onDelete();
                  }
                },
                icon: Icon(Icons.more_vert, size: 18, color: cs.onSurfaceVariant),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _AnnouncementMenuAction.viewReaders,
                    child: Row(children: [
                      Icon(Icons.people_outline, size: 20, color: cs.onSurface),
                      const SizedBox(width: 12),
                      Text(l10n.viewReaders),
                    ]),
                  ),
                  PopupMenuItem(
                    value: _AnnouncementMenuAction.delete,
                    child: Row(children: [
                      Icon(Icons.delete_outline, size: 20, color: cs.error),
                      const SizedBox(width: 12),
                      Text(l10n.deleteAnnouncementTooltip,
                          style: TextStyle(color: cs.error)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
