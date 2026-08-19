import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../../models/announcement.dart';
import '../../models/paginated.dart';
import '../../models/parent.dart';
import '../../services/api_client.dart';
import '../../services/parent_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/meta_badge.dart';
import '../../widgets/pagination_bar.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  int _page = 1;
  int? _selectedStudentId;
  List<ParentStudentListItem>? _students;
  bool _loadingStudents = false;
  late Future<Paginated<Announcement>> _future;

  @override
  void initState() {
    super.initState();
    _future = ParentService.listAnnouncements(page: _page);
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    if (_loadingStudents) return;
    _loadingStudents = true;
    try {
      final students = await ParentService.listStudents();
      if (mounted) setState(() => _students = students);
    } catch (_) {
      // Filter dropdown is optional; a failure here is non-fatal.
    } finally {
      _loadingStudents = false;
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _future = ParentService.listAnnouncements(page: _page, studentId: _selectedStudentId);
    });
    await _future;
  }

  void _goToPage(int page) {
    setState(() {
      _page = page;
      _future = ParentService.listAnnouncements(page: _page, studentId: _selectedStudentId);
    });
  }

  void _onStudentChanged(int? studentId) {
    setState(() {
      _selectedStudentId = studentId;
      _page = 1;
      _future = ParentService.listAnnouncements(page: _page, studentId: _selectedStudentId);
    });
  }

  void _showFullTextDialog(String text) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final dl10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SingleChildScrollView(
            child: Text(
              text,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final showFilter = _students != null && _students!.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.parent),
      ),
      drawer: AppDrawer(
        onProfileTap: () => Navigator.of(context).pushNamed('/parent/profile'),
        actions: [
          DrawerAction(
            icon: Icons.qr_code,
            label: l10n.addStudentCode,
            onTap: () async {
              await Navigator.of(context).pushNamed('/parent/add-student-code');
              _refresh();
              _loadStudents();
            },
          ),
          DrawerAction(
            icon: Icons.people_outline,
            label: l10n.myStudents,
            onTap: () => Navigator.of(context).pushNamed('/parent/students'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: const ContentShapesPainter())),
          RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            if (showFilter) ...[
              Container(
                color: cs.surface,
                padding: AppInsets.filterBar(context),
                child: DropdownButtonFormField<int?>(
                  initialValue: _selectedStudentId,
                  decoration: InputDecoration(
                    labelText: l10n.student,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.allStudents)),
                    for (final s in _students!)
                      DropdownMenuItem(
                        value: s.id,
                        child: Text('${s.name} ${s.surname}'),
                      ),
                  ],
                  onChanged: _onStudentChanged,
                ),
              ),
              Divider(height: 1, color: cs.outlineVariant),
            ],
            Expanded(
              child: FutureBuilder<Paginated<Announcement>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ListView(children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(snapshot.error is ApiException
                            ? (snapshot.error as ApiException).message
                            : snapshot.error.toString()),
                      ),
                    ]);
                  }
                  final result = snapshot.data!;
                  final announcements = result.items;
                  if (announcements.isEmpty) {
                    return ListView(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
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
                    ]);
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: AppInsets.page(context),
                          itemCount: announcements.length,
                          itemBuilder: (context, index) {
                            final a = announcements[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ParentAnnouncementCard(
                                announcement: a,
                                onTap: () => _showFullTextDialog(a.text),
                              ),
                            );
                          },
                        ),
                      ),
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
      ),
        ],
      ),
    );
  }
}

class _ParentAnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onTap;

  const _ParentAnnouncementCard({required this.announcement, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                              if (announcement.studentName != null &&
                                  announcement.studentName!.isNotEmpty)
                                MetaBadge.student(announcement.studentName!),
                              if (announcement.teacherName != null &&
                                  announcement.teacherName!.isNotEmpty)
                                MetaBadge.teacher(announcement.teacherName!),
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
            ],
          ),
        ),
      ),
    );
  }
}
